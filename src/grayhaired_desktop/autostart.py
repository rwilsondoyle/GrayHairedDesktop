"""User-level XDG autostart support."""

from __future__ import annotations

import os
import shlex
from pathlib import Path

AUTOSTART_FILENAME = "grayhaired-desktop.desktop"


def autostart_path(environment: dict[str, str] | None = None) -> Path:
    """Return the standard per-user autostart entry location."""

    env = os.environ if environment is None else environment
    config_home = env.get("XDG_CONFIG_HOME")
    base = Path(config_home).expanduser() if config_home else Path.home() / ".config"
    return base / "autostart" / AUTOSTART_FILENAME


def autostart_entry(executable: Path) -> str:
    """Build an XDG entry for an installed, absolute console-script path."""

    if not executable.is_absolute():
        raise ValueError("Autostart executable must be an absolute path")
    return (
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=My Desktop\n"
        f"Exec={shlex.quote(str(executable))}\n"
        "Terminal=false\n"
        "X-GNOME-Autostart-enabled=true\n"
    )


def installed_launch_executable(
    argument_zero: str, environment: dict[str, str] | None = None
) -> Path | None:
    """Return the stable public launcher, rejecting checkout virtualenvs."""

    env = os.environ if environment is None else environment
    public_launcher = env.get("GRAYHAIRED_DESKTOP_LAUNCHER", argument_zero)
    candidate = Path(public_launcher).expanduser().resolve()
    if candidate.name != "grayhaired-desktop" or ".venv" in candidate.parts:
        return None
    return candidate


def set_autostart(enabled: bool, executable: Path, path: Path | None = None) -> bool:
    """Idempotently update the user entry and report whether it changed."""

    target = path or autostart_path()
    if not enabled:
        existed = target.exists()
        target.unlink(missing_ok=True)
        return existed
    target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    contents = autostart_entry(executable)
    try:
        existing_contents = (
            target.read_text(encoding="utf-8") if target.exists() else None
        )
    except UnicodeError:
        existing_contents = None
    if existing_contents == contents:
        return False
    temporary = target.with_suffix(".desktop.tmp")
    temporary.write_text(contents, encoding="utf-8")
    temporary.replace(target)
    return True


def reconcile_autostart(
    enabled: bool, executable: Path | None, path: Path | None = None
) -> bool:
    """Repair an enabled entry when a stable launcher is currently available."""

    if not enabled or executable is None:
        return False
    return set_autostart(True, executable, path)
