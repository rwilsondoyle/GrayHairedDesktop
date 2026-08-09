"""X11 window configuration tests that require no display server."""

import pytest

qt_core = pytest.importorskip("PySide6.QtCore", exc_type=ImportError)
Qt = qt_core.Qt
x11_window = pytest.importorskip("grayhaired_desktop.x11_window", exc_type=ImportError)
X11_DESKTOP_ATTRIBUTE = x11_window.X11_DESKTOP_ATTRIBUTE
X11_BELOW_WINDOW_FLAGS = x11_window.X11_BELOW_WINDOW_FLAGS
apply_x11_below_window = x11_window.apply_x11_below_window
restore_windowed_window = x11_window.restore_windowed_window


class FakeWindow:
    def __init__(self):
        self.calls = []

    def setAttribute(self, attribute, on=True):  # noqa: N802 - Qt-compatible API
        self.calls.append(("attribute", attribute, on))

    def setWindowFlags(self, flags):  # noqa: N802 - Qt-compatible API
        self.calls.append(("flags", flags))


def test_x11_strategy_clears_desktop_type_before_creating_below_normal_window():
    window = FakeWindow()

    apply_x11_below_window(window)

    assert window.calls == [
        ("attribute", X11_DESKTOP_ATTRIBUTE, False),
        ("flags", X11_BELOW_WINDOW_FLAGS),
    ]
    window_type = X11_BELOW_WINDOW_FLAGS & Qt.WindowType.WindowType_Mask
    assert window_type == Qt.WindowType.Window
    assert X11_BELOW_WINDOW_FLAGS & Qt.WindowType.WindowStaysOnBottomHint
    assert X11_BELOW_WINDOW_FLAGS & Qt.WindowType.FramelessWindowHint


def test_windowed_mode_clears_attribute_before_restoring_flags():
    window = FakeWindow()
    normal_flags = Qt.WindowType.Window | Qt.WindowType.WindowTitleHint

    restore_windowed_window(window, normal_flags)

    assert window.calls == [
        ("attribute", X11_DESKTOP_ATTRIBUTE, False),
        ("flags", normal_flags),
    ]
