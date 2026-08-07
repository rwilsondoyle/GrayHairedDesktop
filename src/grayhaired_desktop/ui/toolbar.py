"""Main-toolbar construction for the application window."""

from __future__ import annotations

from PySide6.QtWidgets import QMainWindow, QToolBar

from grayhaired_desktop.ui.actions import ApplicationActions


def create_toolbar(parent: QMainWindow, actions: ApplicationActions) -> QToolBar:
    """Create, attach, and return the application's non-movable toolbar."""

    toolbar = QToolBar("Main Toolbar", parent)
    toolbar.setMovable(False)
    toolbar.addAction(actions.reload)
    toolbar.addAction(actions.preferences)
    parent.addToolBar(toolbar)
    return toolbar
