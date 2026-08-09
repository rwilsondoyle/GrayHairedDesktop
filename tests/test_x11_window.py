"""X11 window configuration tests that require no display server."""

import pytest

qt_core = pytest.importorskip("PySide6.QtCore", exc_type=ImportError)
Qt = qt_core.Qt
x11_window = pytest.importorskip("grayhaired_desktop.x11_window", exc_type=ImportError)
X11_DESKTOP_ATTRIBUTE = x11_window.X11_DESKTOP_ATTRIBUTE
X11_DESKTOP_FLAGS = x11_window.X11_DESKTOP_FLAGS
apply_x11_desktop_window = x11_window.apply_x11_desktop_window
restore_windowed_window = x11_window.restore_windowed_window


class FakeWindow:
    def __init__(self):
        self.calls = []

    def setAttribute(self, attribute, on=True):  # noqa: N802 - Qt-compatible API
        self.calls.append(("attribute", attribute, on))

    def setWindowFlags(self, flags):  # noqa: N802 - Qt-compatible API
        self.calls.append(("flags", flags))


def test_x11_desktop_attribute_is_applied_before_native_window_recreation():
    window = FakeWindow()

    apply_x11_desktop_window(window)

    assert window.calls == [
        ("attribute", X11_DESKTOP_ATTRIBUTE, True),
        ("flags", X11_DESKTOP_FLAGS),
    ]
    window_type = X11_DESKTOP_FLAGS & Qt.WindowType.WindowType_Mask
    assert window_type == Qt.WindowType.Window


def test_windowed_mode_clears_attribute_before_restoring_flags():
    window = FakeWindow()
    normal_flags = Qt.WindowType.Window | Qt.WindowType.WindowTitleHint

    restore_windowed_window(window, normal_flags)

    assert window.calls == [
        ("attribute", X11_DESKTOP_ATTRIBUTE, False),
        ("flags", normal_flags),
    ]
