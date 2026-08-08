"""Explicit tooltip handling for Linux desktop environments."""

from __future__ import annotations

from PySide6.QtCore import QEvent, QObject, QPoint
from PySide6.QtGui import QAction, QHelpEvent, QMouseEvent
from PySide6.QtWidgets import QMenu, QToolTip, QWidget


class ToolTipMenu(QMenu):
    """Popup menu that displays action tooltips directly from mouse movement."""

    def __init__(self, title: str, parent: QWidget | None = None) -> None:
        super().__init__(title, parent)
        self.setMouseTracking(True)
        self._tooltip_action: QAction | None = None

    def action_tooltip_at(self, position: QPoint) -> str:
        """Return the tooltip for the action at a menu-local position."""

        action = self.actionAt(position)
        return action.toolTip() if action is not None else ""

    def mouseMoveEvent(self, event: QMouseEvent) -> None:  # noqa: N802
        """Update the tooltip when the pointer moves to a different action."""

        super().mouseMoveEvent(event)
        action = self.actionAt(event.position().toPoint())
        if action is self._tooltip_action:
            return

        QToolTip.hideText()
        self._tooltip_action = action
        if action is not None and (tooltip := action.toolTip()):
            QToolTip.showText(event.globalPosition().toPoint(), tooltip, self)

    def leaveEvent(self, event: QEvent) -> None:  # noqa: N802
        """Hide action help when the pointer leaves the popup menu."""

        self._hide_action_tooltip()
        super().leaveEvent(event)

    def hideEvent(self, event: QEvent) -> None:  # noqa: N802
        """Hide action help when the popup menu closes."""

        self._hide_action_tooltip()
        super().hideEvent(event)

    def _hide_action_tooltip(self) -> None:
        self._tooltip_action = None
        QToolTip.hideText()


class ExplicitToolTipFilter(QObject):
    """Display widget and menu-action tooltips from ``QEvent.ToolTip`` events."""

    @staticmethod
    def tooltip_at(widget: QWidget, position: QPoint) -> str:
        """Return the tooltip for the widget or menu action at ``position``."""

        return widget.toolTip()

    def eventFilter(self, watched: QObject, event: QEvent) -> bool:  # noqa: N802
        """Handle tooltip events explicitly instead of relying on platform behavior."""

        if event.type() != QEvent.Type.ToolTip or not isinstance(event, QHelpEvent):
            return super().eventFilter(watched, event)
        if not isinstance(watched, QWidget):
            return super().eventFilter(watched, event)

        tooltip = self.tooltip_at(watched, event.pos())
        if tooltip:
            QToolTip.showText(event.globalPos(), tooltip, watched)
        else:
            QToolTip.hideText()
        event.accept()
        return True


def install_explicit_tooltips(widget: QWidget) -> ExplicitToolTipFilter:
    """Install and return a widget-owned explicit tooltip event filter."""

    tooltip_filter = ExplicitToolTipFilter(widget)
    widget.installEventFilter(tooltip_filter)
    return tooltip_filter
