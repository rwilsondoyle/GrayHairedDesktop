"""Explicit tooltip handling for Linux desktop environments."""

from __future__ import annotations

from PySide6.QtCore import QEvent, QObject, QPoint
from PySide6.QtGui import QHelpEvent
from PySide6.QtWidgets import QMenu, QToolTip, QWidget


class ExplicitToolTipFilter(QObject):
    """Display widget and menu-action tooltips from ``QEvent.ToolTip`` events."""

    @staticmethod
    def tooltip_at(widget: QWidget, position: QPoint) -> str:
        """Return the tooltip for the widget or menu action at ``position``."""

        if isinstance(widget, QMenu):
            action = widget.actionAt(position)
            return action.toolTip() if action is not None else ""
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
