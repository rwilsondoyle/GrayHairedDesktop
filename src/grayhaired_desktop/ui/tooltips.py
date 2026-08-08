"""Consistent, non-focusable help bubbles for application controls."""

from __future__ import annotations

from PySide6.QtCore import QEvent, QObject, QPoint, Qt, QTimer
from PySide6.QtGui import QAction, QHelpEvent
from PySide6.QtWidgets import QApplication, QLabel, QMenu, QMenuBar, QWidget


HELP_SHOW_DELAY_MS = 350


class HelpBubble(QLabel):
    """Small non-focusable help window shared by controls and commands."""

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
            position.setX(
                max(
                    available.left(),
                    min(position.x(), available.right() - self.width() + 1),
                )
            )
            position.setY(
                max(
                    available.top(),
                    min(position.y(), available.bottom() - self.height() + 1),
                )
            )
        self.move(position)
        self.show()


# Retain the original public name for callers outside this package.
MenuHelpBubble = HelpBubble


class MenuHelpController(QObject):
    """Drive one shared help bubble from a popup menu's hovered actions."""

    _SHOW_DELAY_MS = HELP_SHOW_DELAY_MS

    def __init__(
        self,
        menu: QMenu | QMenuBar,
        bubble: HelpBubble,
        actions: set[QAction] | None = None,
    ) -> None:
        super().__init__(menu)
        self._menu = menu
        self._bubble = bubble
        self._actions = actions
        self._pending_action: QAction | None = None
        self._timer = QTimer(self)
        self._timer.setSingleShot(True)
        self._timer.setInterval(self._SHOW_DELAY_MS)
        self._timer.timeout.connect(self._show_pending_help)
        menu.hovered.connect(self.select_action)
        menu.triggered.connect(lambda action: self.clear())
        if isinstance(menu, QMenu):
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
        action_is_supported = self._actions is None or action in self._actions
        self._pending_action = (
            action if action_is_supported and action.toolTip() else None
        )
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

        if event.type() in {QEvent.Type.Leave, QEvent.Type.Hide}:
            self._bubble.hide()
        if event.type() != QEvent.Type.ToolTip or not isinstance(event, QHelpEvent):
            return super().eventFilter(watched, event)
        if not isinstance(watched, QWidget):
            return super().eventFilter(watched, event)

        tooltip = self.tooltip_at(watched, event.pos())
        if tooltip:
            self._bubble.show_message(tooltip, self._position(watched))
        else:
            self._bubble.hide()
        event.accept()
        return True
    def __init__(self, widget: QWidget, bubble: HelpBubble) -> None:
        super().__init__(widget)
        self._bubble = bubble

    @staticmethod
    def _position(widget: QWidget) -> QPoint:
        """Place help beside the widget without covering it."""

        return widget.mapToGlobal(QPoint(widget.width() + 8, 0))


def install_explicit_tooltips(
    widget: QWidget, bubble: HelpBubble
) -> ExplicitToolTipFilter:
    """Install custom help-bubble handling for a widget's tooltip events."""

    tooltip_filter = ExplicitToolTipFilter(widget, bubble)
    widget.installEventFilter(tooltip_filter)
    return tooltip_filter
