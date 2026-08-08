"""Desktop Mode decisions that do not require a display server."""

from grayhaired_desktop.desktop_mode import (
    DesktopModePath,
    detect_session,
    select_desktop_mode,
)


def test_explicit_x11_with_xcb_supports_desktop_mode():
    info = detect_session("xcb", {"XDG_SESSION_TYPE": "x11"})

    assert select_desktop_mode(info, True) is DesktopModePath.X11_DESKTOP


def test_wayland_uses_safe_unsupported_path():
    info = detect_session("wayland", {"XDG_SESSION_TYPE": "wayland"})

    assert select_desktop_mode(info, True) is DesktopModePath.UNSUPPORTED


def test_mismatched_session_and_qt_platform_is_not_claimed_as_x11():
    info = detect_session("wayland", {"XDG_SESSION_TYPE": "x11"})

    assert select_desktop_mode(info, True) is DesktopModePath.UNSUPPORTED


def test_qt_platform_supplies_session_when_environment_is_silent():
    assert detect_session("xcb", {}).session_type == "x11"


def test_disabled_mode_always_remains_windowed():
    info = detect_session("xcb", {"XDG_SESSION_TYPE": "x11"})

    assert select_desktop_mode(info, False) is DesktopModePath.WINDOWED
