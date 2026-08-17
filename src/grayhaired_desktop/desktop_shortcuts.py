"""Safe user-level launchers for the configured My Desktop shortcuts."""

from __future__ import annotations

import logging
import re
import subprocess
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable
from urllib.parse import urlsplit, urlunsplit

from grayhaired_desktop.favorites import Favorite

MANAGED_MARKER = "X-MyDesktop-Managed=true"
FILE_PREFIX = "my-desktop-"


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
    return (slug[:60].rstrip("-") or "shortcut")


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


class DesktopShortcutManager:
    """Synchronize only clearly marked launchers in a supplied Desktop path."""

    def __init__(self, desktop: Path, logger: logging.Logger, command: str = "grayhaired-desktop") -> None:
        self.desktop = desktop
        self.logger = logger
        self.command = command

    def sync(self, favorites: Iterable[Favorite]) -> SyncResult:
        items = list(favorites)
        self.logger.info("Desktop shortcut synchronization requested; configured shortcuts: %d", len(items))
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
                self.logger.warning("Refused desktop shortcut with unsafe target: %s", sanitized_url_for_log(favorite.website_address))

        for path, contents in desired.items():
            if path.is_symlink():
                refused += 1
                self.logger.warning("Refused Desktop shortcut symlink collision: %s", path.name)
                continue
            if path.exists() and not is_managed_launcher(path):
                refused += 1
                self.logger.warning("Refused to overwrite unowned Desktop collision: %s", path.name)
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
            "Desktop shortcut synchronization complete: created=%d updated=%d removed=%d refused=%d invalid=%d",
            created, updated, removed, refused, invalid,
        )
        return result

    def remove_all(self) -> int:
        removed = 0
        for path in self.desktop.glob(f"{FILE_PREFIX}*.desktop"):
            if is_managed_launcher(path):
                path.unlink()
                removed += 1
                self.logger.info("Cleanup removed managed Desktop shortcut: %s", path.name)
        self.logger.info("Desktop shortcut cleanup complete: removed=%d", removed)
        return removed
