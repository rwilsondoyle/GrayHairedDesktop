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
        "Name=GrayHaired Desktop\n"
        f"Exec={shlex.quote(str(executable))}\n"
        "Terminal=false\n"
        "X-GNOME-Autostart-enabled=true\n"
    )


def installed_launch_executable(argument_zero: str) -> Path | None:
    """Return a stable installed launcher, rejecting source-checkout virtualenvs."""

    candidate = Path(argument_zero).expanduser().resolve()
    if candidate.name != "grayhaired-desktop" or ".venv" in candidate.parts:
        return None
    return candidate


def set_autostart(enabled: bool, executable: Path, path: Path | None = None) -> None:
    """Idempotently create or remove the one user-level autostart entry."""

    target = path or autostart_path()
    if not enabled:
        target.unlink(missing_ok=True)
        return
    target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    contents = autostart_entry(executable)
    if target.exists() and target.read_text(encoding="utf-8") == contents:
        return
    temporary = target.with_suffix(".desktop.tmp")
    temporary.write_text(contents, encoding="utf-8")
    temporary.replace(target)
