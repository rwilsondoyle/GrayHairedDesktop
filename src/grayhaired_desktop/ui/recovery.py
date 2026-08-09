"""Application-local keyboard recovery for Desktop Mode."""

from __future__ import annotations

from collections.abc import Callable

from PySide6.QtCore import QEvent, QObject, Qt


class DesktopModeRecoveryFilter(QObject):
    """Catch Ctrl+Shift+D before a focused child such as QtWebEngine consumes it."""

    def __init__(
        self,
        is_active: Callable[[], bool],
        recover: Callable[[], None],
        parent: QObject | None = None,
    ) -> None:
        super().__init__(parent)
        self._is_active = is_active
        self._recover = recover

    def eventFilter(self, watched, event) -> bool:  # noqa: N802 - Qt override name
        """Recover only for key events delivered to this application."""

        if event.type() != QEvent.Type.KeyPress or not self._is_active():
            return False
        relevant_modifiers = (
            Qt.KeyboardModifier.ControlModifier
            | Qt.KeyboardModifier.ShiftModifier
            | Qt.KeyboardModifier.AltModifier
            | Qt.KeyboardModifier.MetaModifier
        )
        expected_modifiers = (
            Qt.KeyboardModifier.ControlModifier
            | Qt.KeyboardModifier.ShiftModifier
        )
        if (
            event.key() == Qt.Key.Key_D
            and event.modifiers() & relevant_modifiers == expected_modifiers
        ):
            self._recover()
            event.accept()
            return True
        return False
