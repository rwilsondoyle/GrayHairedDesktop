"""Application-local Desktop Mode recovery tests."""

import pytest

qt_core = pytest.importorskip("PySide6.QtCore", exc_type=ImportError)
QEvent = qt_core.QEvent
Qt = qt_core.Qt
recovery = pytest.importorskip(
    "grayhaired_desktop.ui.recovery", exc_type=ImportError
)


class KeyEvent:
    def __init__(self, key, modifiers):
        self._key = key
        self._modifiers = modifiers
        self.accepted = False

    def type(self):
        return QEvent.Type.KeyPress

    def key(self):
        return self._key

    def modifiers(self):
        return self._modifiers

    def accept(self):
        self.accepted = True


def test_recovery_catches_shortcut_before_focused_child():
    recovered = []
    event_filter = recovery.DesktopModeRecoveryFilter(
        lambda: True, lambda: recovered.append(True)
    )
    event = KeyEvent(
        Qt.Key.Key_D,
        Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier,
    )

    assert event_filter.eventFilter(None, event)
    assert event.accepted
    assert recovered == [True]


def test_recovery_does_not_consume_shortcut_in_windowed_mode():
    recovered = []
    event_filter = recovery.DesktopModeRecoveryFilter(
        lambda: False, lambda: recovered.append(True)
    )
    event = KeyEvent(
        Qt.Key.Key_D,
        Qt.KeyboardModifier.ControlModifier | Qt.KeyboardModifier.ShiftModifier,
    )

    assert not event_filter.eventFilter(None, event)
    assert not event.accepted
    assert recovered == []
