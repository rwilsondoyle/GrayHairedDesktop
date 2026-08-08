"""Main-toolbar construction for the application window."""

from __future__ import annotations

from PySide6.QtWidgets import QMainWindow, QToolBar, QToolButton

from grayhaired_desktop.ui.actions import ApplicationActions


def create_toolbar(parent: QMainWindow, actions: ApplicationActions) -> QToolBar:
    """Create, attach, and return the application's non-movable toolbar."""

    toolbar = QToolBar("Main Toolbar", parent)
    toolbar.setMovable(False)
    toolbar.setContentsMargins(4, 2, 4, 2)
    toolbar.layout().setSpacing(6)

    toolbar.addAction(actions.reload)
    toolbar.addAction(actions.preferences)
    reload_button = toolbar.widgetForAction(actions.reload)
    settings_button = toolbar.widgetForAction(actions.preferences)

    for button, name, description in (
        (
            reload_button,
            "Reload",
            "Refresh the current Desktop Website",
        ),
        (
            settings_button,
            "Settings",
            "Choose the Desktop Website and shortcut appearance",
        ),
    ):
        if isinstance(button, QToolButton):
            button.setMinimumHeight(40)
            button.setAccessibleName(name)
            button.setAccessibleDescription(description)

    parent.addToolBar(toolbar)
    return toolbar
