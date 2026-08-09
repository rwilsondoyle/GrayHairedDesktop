"""Desktop Mode decisions that do not require a display server."""

from grayhaired_desktop.desktop_mode import (
    DesktopModePath,
    detect_session,
    select_desktop_mode,
    should_notify_unsupported_mode,
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


def test_newly_enabled_unsupported_mode_notifies_user():
    assert should_notify_unsupported_mode(
        DesktopModePath.UNSUPPORTED, newly_enabled=True
    )


def test_saved_unsupported_mode_does_not_notify_again_at_startup():
    info = detect_session("wayland", {"XDG_SESSION_TYPE": "wayland"})
    path = select_desktop_mode(info, requested=True)

    assert path is DesktopModePath.UNSUPPORTED
    assert not should_notify_unsupported_mode(path, newly_enabled=False)


def test_supported_or_windowed_paths_do_not_show_unavailable_message():
    assert not should_notify_unsupported_mode(
        DesktopModePath.X11_DESKTOP, newly_enabled=True
    )
    assert not should_notify_unsupported_mode(
        DesktopModePath.WINDOWED, newly_enabled=True
    )
