"""Session detection and conservative Desktop Mode selection."""

from __future__ import annotations

import os
from dataclasses import dataclass
from enum import Enum
from typing import Mapping


class DesktopModePath(Enum):
    """Supported window paths, kept independent of a running Qt session."""

    WINDOWED = "windowed"
    X11_DESKTOP = "x11-desktop"
    UNSUPPORTED = "unsupported"


@dataclass(frozen=True, slots=True)
class SessionInfo:
    """Non-sensitive graphical-session facts used to select a window path."""

    session_type: str
    qt_platform: str
    desktop_environment: str


def detect_session(
    qt_platform: str, environment: Mapping[str, str] | None = None
) -> SessionInfo:
    """Detect the graphical session without assuming X11 or Wayland."""

    env = os.environ if environment is None else environment
    session_type = env.get("XDG_SESSION_TYPE", "").strip().lower()
    platform = qt_platform.strip().lower()
    if not session_type:
        if platform == "xcb":
            session_type = "x11"
        elif "wayland" in platform:
            session_type = "wayland"
        else:
            session_type = "unknown"
    desktop = env.get("XDG_CURRENT_DESKTOP", "unknown").strip() or "unknown"
    return SessionInfo(session_type, platform or "unknown", desktop)


def select_desktop_mode(info: SessionInfo, requested: bool) -> DesktopModePath:
    """Choose true desktop-window support only for Qt's native X11 backend."""

    if not requested:
        return DesktopModePath.WINDOWED
    if info.session_type in {"x11", "xorg"} and info.qt_platform == "xcb":
        return DesktopModePath.X11_DESKTOP
    return DesktopModePath.UNSUPPORTED
