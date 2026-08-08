"""Explicit tooltip handling for Linux desktop environments."""

from __future__ import annotations

from PySide6.QtCore import QEvent, QObject, QPoint, Qt, QTimer
from PySide6.QtGui import QAction, QHelpEvent
from PySide6.QtWidgets import QApplication, QLabel, QMenu, QToolTip, QWidget


class MenuHelpBubble(QLabel):
    """Small non-focusable help window for popup-menu commands."""

    def __init__(self, parent: QWidget) -> None:
        super().__init__(parent, Qt.WindowType.ToolTip)
        self.setMargin(6)
        self.setTextFormat(Qt.TextFormat.PlainText)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)
        self.setWindowFlag(Qt.WindowType.WindowDoesNotAcceptFocus)

    def show_message(self, text: str, position: QPoint) -> None:
        """Show plain help text near a menu command without taking focus."""

        self.setText(text)
        self.adjustSize()
        screen = QApplication.screenAt(position)
        if screen is not None:
            available = screen.availableGeometry()
            position.setX(min(position.x(), available.right() - self.width()))
            position.setY(min(position.y(), available.bottom() - self.height()))
        self.move(position)
        self.show()


class MenuHelpController(QObject):
    """Drive one shared help bubble from a popup menu's hovered actions."""

    _SHOW_DELAY_MS = 350

    def __init__(self, menu: QMenu, bubble: MenuHelpBubble) -> None:
        super().__init__(menu)
        self._menu = menu
        self._bubble = bubble
        self._pending_action: QAction | None = None
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(self._SHOW_DELAY_MS)
        self._timer.timeout.connect(self._show_pending_help)
        menu.hovered.connect(self.select_action)
        menu.triggered.connect(lambda action: self.clear())
        menu.aboutToShow.connect(self.clear)
        menu.aboutToHide.connect(self.clear)
        menu.installEventFilter(self)

    @property
    def pending_text(self) -> str:
        """Return the selected help text, primarily for focused tests."""

        if self._pending_action is None:
            return ""
        return self._pending_action.toolTip()

    def select_action(self, action: QAction) -> None:
        """Select a hovered action and restart its short display delay."""

        self._timer.stop()
        self._bubble.hide()
        self._pending_action = action if action.toolTip() else None
        if self._pending_action is not None:
            self._timer.start()

    def clear(self) -> None:
        """Cancel pending help and hide any visible bubble."""

        self._timer.stop()
        self._pending_action = None
        self._bubble.hide()

    def eventFilter(self, watched: QObject, event: QEvent) -> bool:  # noqa: N802
        """Clear help when the cursor leaves or the popup closes."""

        if watched is self._menu and event.type() in {
            QEvent.Type.Leave,
            QEvent.Type.Hide,
        }:
            self.clear()
        return super().eventFilter(watched, event)

    def _show_pending_help(self) -> None:
        action = self._pending_action
        if action is None or not self._menu.isVisible():
            return
        action_geometry = self._menu.actionGeometry(action)
        position = self._menu.mapToGlobal(action_geometry.topRight() + QPoint(8, 0))
        self._bubble.show_message(action.toolTip(), position)


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
