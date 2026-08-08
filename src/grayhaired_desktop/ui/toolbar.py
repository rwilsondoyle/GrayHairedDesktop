"""Main-toolbar construction for the application window."""

from __future__ import annotations

from PySide6.QtWidgets import QMainWindow, QToolBar, QToolButton

from grayhaired_desktop.ui.actions import ApplicationActions


def create_toolbar(parent: QMainWindow, actions: ApplicationActions) -> QToolBar:
    """Create, attach, and return the application's non-movable toolbar."""

    toolbar = QToolBar("Main Toolbar", parent)
    toolbar.setMovable(False)
    toolbar.layout().setSpacing(6)

    toolbar.addAction(actions.reload)
    reload_button = toolbar.widgetForAction(actions.reload)
    if isinstance(reload_button, QToolButton):
        reload_button.setAccessibleName("Reload")
        reload_button.setAccessibleDescription(
            "Refresh the current Desktop Website"
        )

    parent.addToolBar(toolbar)
    return toolbar
