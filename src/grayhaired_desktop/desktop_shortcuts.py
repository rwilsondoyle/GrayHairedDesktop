"""Safe user-level launchers and placement for My Desktop shortcuts."""

from __future__ import annotations

import logging
import os
import re
import subprocess
import unicodedata
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

from grayhaired_desktop.favorites import Favorite

MANAGED_MARKER = "X-MyDesktop-Managed=true"
FILE_PREFIX = "my-desktop-"
POSITION_ATTRIBUTE = "metadata::nautilus-icon-position"


def safe_web_url(value: str) -> str | None:
    """Return a normalized HTTP(S) URL, or None for an unsafe target."""

    if any(ord(character) < 32 or ord(character) == 127 for character in value):
        return None
    try:
        parts = urlsplit(value.strip())
        if parts.scheme.lower() not in {"http", "https"} or not parts.netloc:
            return None
        return urlunsplit(parts)
    except ValueError:
        return None


def sanitized_url_for_log(value: str) -> str:
    """Describe a URL without logging its path, query, credentials, or fragment."""

    safe = safe_web_url(value)
    if safe is None:
        return "<invalid URL>"
    parts = urlsplit(safe)
    host = parts.hostname or "<unknown host>"
    return f"{parts.scheme}://{host}/"


def resolve_desktop_directory(
    home: Path,
    *,
    runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
    logger: logging.Logger | None = None,
) -> Path:
    """Resolve XDG Desktop, accepting only an absolute path inside *home*."""

    home = home.expanduser().resolve()
    candidate: Path | None = None
    try:
        result = runner(
            ["xdg-user-dir", "DESKTOP"],
            check=True,
            capture_output=True,
            text=True,
            timeout=5,
        )
        output = result.stdout.strip()
        if output:
            proposed = Path(output).expanduser()
            if proposed.is_absolute():
                resolved = proposed.resolve(strict=False)
                if resolved != home and resolved.is_relative_to(home):
                    candidate = resolved
    except (FileNotFoundError, OSError, subprocess.SubprocessError):
        pass
    desktop = candidate or (home / "Desktop")
    desktop.mkdir(mode=0o700, parents=True, exist_ok=True)
    if logger:
        logger.info("Resolved Desktop directory: %s", desktop)
    return desktop


def launcher_slug(title: str) -> str:
    """Create a stable ASCII filename component from a shortcut title."""

    normalized = unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-z0-9]+", "-", normalized.lower()).strip("-")
    return slug[:60].rstrip("-") or "shortcut"


def _desktop_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace("\n", " ").replace("\r", " ")


def _exec_argument(value: str) -> str:
    # Desktop Entry quoting is not shell quoting. Percent is doubled because it
    # introduces field codes in Exec values.
    escaped = value.replace("%", "%%").replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def launcher_contents(favorite: Favorite, command: str = "grayhaired-desktop") -> str:
    """Render one owned Desktop Entry; reject non-web targets."""

    url = safe_web_url(favorite.website_address)
    if url is None:
        raise ValueError("shortcut target must be an HTTP or HTTPS URL")
    name = _desktop_string(favorite.title.strip()) or "Web Shortcut"
    return "\n".join(
        (
            "[Desktop Entry]",
            "Type=Application",
            f"Name={name}",
            f"Exec={_exec_argument(command)} --open-url {_exec_argument(url)}",
            "Icon=web-browser",
            "Terminal=false",
            MANAGED_MARKER,
            "",
        )
    )


def is_managed_launcher(path: Path) -> bool:
    try:
        return MANAGED_MARKER in path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError):
        return False


@dataclass(frozen=True, slots=True)
class SyncResult:
    created: int = 0
    updated: int = 0
    removed: int = 0
    refused: int = 0
    invalid: int = 0


@dataclass(frozen=True, slots=True)
class PlacementResult:
    moved: int = 0
    skipped: int = 0
    failed: int = 0


def parse_icon_position(value: str) -> tuple[int, int] | None:
    """Parse a non-negative ``x,y`` desktop icon position."""

    match = re.fullmatch(r"\s*(\d+)\s*,\s*(\d+)\s*", value)
    if match is None:
        return None
    return int(match.group(1)), int(match.group(2))


def format_icon_position(position: tuple[int, int]) -> str:
    """Serialize a desktop icon position for GIO metadata."""

    x, y = position
    if x < 0 or y < 0:
        raise ValueError("desktop icon coordinates must be non-negative")
    return f"{x},{y}"


def preset_positions(count: int, width: int, height: int) -> list[tuple[int, int]]:
    """Return a conservative two-row layout above the panel/right icon strip."""

    if count <= 0 or width <= 0 or height <= 0:
        return []
    columns = min(4, count)
    rows = (count + columns - 1) // columns
    left = max(24, min(72, width // 20))
    right = max(left, width - max(200, width // 8))
    top = max(40, min(100, height // 10))
    lower = max(top, min(height - 180, int(height * 0.55)))
    xs = (
        [left]
        if columns == 1
        else [
            round(left + index * (right - left) / (columns - 1))
            for index in range(columns)
        ]
    )
    ys = (
        [top]
        if rows == 1
        else [
            round(top + index * (lower - top) / (rows - 1))
            for index in range(rows)
        ]
    )
    return [(xs[index % columns], ys[index // columns]) for index in range(count)]


class DesktopShortcutManager:
    """Synchronize only clearly marked launchers in a supplied Desktop path."""

    def __init__(
        self,
        desktop: Path,
        logger: logging.Logger,
        command: str = "grayhaired-desktop",
    ) -> None:
        self.desktop = desktop
        self.logger = logger
        self.command = command

    def sync(self, favorites: Iterable[Favorite]) -> SyncResult:
        items = list(favorites)
        self.logger.info(
            "Desktop shortcut synchronization requested; configured shortcuts: %d",
            len(items),
        )
        desired: dict[Path, str] = {}
        invalid = refused = created = updated = removed = 0
        used: set[str] = set()
        for favorite in items:
            slug = launcher_slug(favorite.title)
            suffix = 2
            unique = slug
            while unique in used:
                unique = f"{slug}-{suffix}"
                suffix += 1
            used.add(unique)
            path = self.desktop / f"{FILE_PREFIX}{unique}.desktop"
            try:
                desired[path] = launcher_contents(favorite, self.command)
            except ValueError:
                invalid += 1
                self.logger.warning(
                    "Refused desktop shortcut with unsafe target: %s",
                    sanitized_url_for_log(favorite.website_address),
                )

        for path, contents in desired.items():
            if path.is_symlink():
                refused += 1
                self.logger.warning(
                    "Refused Desktop shortcut symlink collision: %s", path.name
                )
                continue
            if path.exists() and not is_managed_launcher(path):
                refused += 1
                self.logger.warning(
                    "Refused to overwrite unowned Desktop collision: %s", path.name
                )
                continue
            old = path.read_text(encoding="utf-8") if path.exists() else None
            if old == contents:
                path.chmod(0o700)
                continue
            path.write_text(contents, encoding="utf-8")
            path.chmod(0o700)
            if old is None:
                created += 1
                self.logger.info("Created managed Desktop shortcut: %s", path.name)
            else:
                updated += 1
                self.logger.info("Updated managed Desktop shortcut: %s", path.name)

        for path in self.desktop.glob(f"{FILE_PREFIX}*.desktop"):
            if path not in desired and is_managed_launcher(path):
                path.unlink()
                removed += 1
                self.logger.info("Removed stale managed Desktop shortcut: %s", path.name)
        result = SyncResult(created, updated, removed, refused, invalid)
        self.logger.info(
            "Desktop shortcut synchronization complete: created=%d updated=%d "
            "removed=%d refused=%d invalid=%d",
            created,
            updated,
            removed,
            refused,
            invalid,
        )
        return result

    def remove_all(self) -> int:
        removed = 0
        for path in self.desktop.glob(f"{FILE_PREFIX}*.desktop"):
            if is_managed_launcher(path):
                path.unlink()
                removed += 1
                self.logger.info(
                    "Cleanup removed managed Desktop shortcut: %s", path.name
                )
        self.logger.info("Desktop shortcut cleanup complete: removed=%d", removed)
        return removed


class DesktopShortcutPlacementManager:
    """Read and update positions for My Desktop-owned launchers only."""

    def __init__(
        self,
        desktop: Path,
        logger: logging.Logger,
        *,
        runner: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
        refresher: Callable[[Path], None] | None = None,
    ) -> None:
        self.desktop = desktop.resolve(strict=False)
        self.logger = logger
        self.runner = runner
        self.refresher = refresher or self._refresh_file

    @staticmethod
    def _refresh_file(path: Path) -> None:
        # Equivalent to the physically verified ``touch`` test without changing
        # launcher contents or trust metadata, and without creating a missing file.
        os.utime(path, None, follow_symlinks=False)

    def _managed_launchers(self) -> list[Path]:
        launchers = []
        for path in sorted(self.desktop.glob(f"{FILE_PREFIX}*.desktop")):
            if path.is_symlink() or not path.is_file() or not is_managed_launcher(path):
                continue
            if path.parent.resolve(strict=False) != self.desktop:
                continue
            launchers.append(path)
        return launchers

    def read_position(self, path: Path) -> tuple[int, int] | None:
        """Read one managed launcher's saved position using GIO."""

        if path not in self._managed_launchers():
            return None
        try:
            result = self.runner(
                ["gio", "info", "-a", POSITION_ATTRIBUTE, str(path)],
                check=True,
                capture_output=True,
                text=True,
                timeout=5,
            )
        except (FileNotFoundError, OSError, subprocess.SubprocessError):
            self.logger.warning(
                "Could not read Desktop shortcut position: %s", path.name
            )
            return None
        prefix = f"{POSITION_ATTRIBUTE}:"
        for line in result.stdout.splitlines():
            stripped = line.strip()
            if not stripped.startswith(prefix):
                continue
            value = stripped[len(prefix) :].strip()
            return parse_icon_position(value)
        return None

    def capture_positions(self) -> dict[str, str]:
        """Capture readable positions for currently managed launchers."""

        captured: dict[str, str] = {}
        for path in self._managed_launchers():
            position = self.read_position(path)
            if position is not None:
                captured[path.name] = format_icon_position(position)
        self.logger.info(
            "Captured previous Desktop shortcut positions: %d", len(captured)
        )
        return captured

    def _write_position(self, path: Path, position: tuple[int, int]) -> bool:
        if path not in self._managed_launchers():
            return False
        value = format_icon_position(position)
        try:
            self.runner(
                ["gio", "set", str(path), POSITION_ATTRIBUTE, value],
                check=True,
                capture_output=True,
                text=True,
                timeout=5,
            )
            self.refresher(path)
        except (FileNotFoundError, OSError, subprocess.SubprocessError):
            self.logger.warning("Could not place Desktop shortcut: %s", path.name)
            return False
        self.logger.info(
            "Placed managed Desktop shortcut %s at %s", path.name, value
        )
        return True

    def arrange(self, width: int, height: int) -> PlacementResult:
        """Arrange managed launchers in a conservative primary-screen layout."""

        launchers = self._managed_launchers()
        positions = preset_positions(len(launchers), width, height)
        moved = failed = 0
        for path, position in zip(launchers, positions, strict=True):
            if self._write_position(path, position):
                moved += 1
            else:
                failed += 1
        result = PlacementResult(moved=moved, failed=failed)
        self.logger.info(
            "Desktop shortcut arrangement complete: moved=%d failed=%d",
            moved,
            failed,
        )
        return result

    def restore(self, positions: Mapping[str, str]) -> PlacementResult:
        """Restore saved coordinates to matching managed launchers only."""

        moved = skipped = failed = 0
        managed = {path.name: path for path in self._managed_launchers()}
        for name, value in positions.items():
            path = managed.get(name)
            position = parse_icon_position(value)
            if path is None or position is None:
                skipped += 1
                continue
            if self._write_position(path, position):
                moved += 1
            else:
                failed += 1
        result = PlacementResult(moved=moved, skipped=skipped, failed=failed)
        self.logger.info(
            "Desktop shortcut restore complete: moved=%d skipped=%d failed=%d",
            moved,
            skipped,
            failed,
        )
        return result
