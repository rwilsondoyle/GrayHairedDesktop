"""Application action creation for the main window."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from PySide6.QtCore import QObject
from PySide6.QtGui import QAction


@dataclass(frozen=True, slots=True)
class ApplicationActions:
    """Actions shared by the application's menus and toolbar."""

    exit: QAction
    back: QAction
    forward: QAction
    home: QAction
    reload: QAction
    preferences: QAction
    about: QAction


def create_actions(
    parent: QObject,
    *,
    close: Callable[[], object],
    go_back: Callable[[], object],
    go_forward: Callable[[], object],
    load_home: Callable[[], object],
    reload_page: Callable[[], object],
    show_preferences: Callable[[], object],
    show_about: Callable[[], object],
) -> ApplicationActions:
    """Create the main-window actions and connect their callbacks."""

    exit_action = QAction("Exit", parent)
    exit_action.setStatusTip("Close GrayHaired Desktop")
    exit_action.triggered.connect(close)

    back_action = QAction("Back", parent)
    back_action.setShortcut("Alt+Left")
    back_action.setToolTip("Go back to the previous page")
    back_action.setStatusTip("Go back to the previous page")
    back_action.setEnabled(False)
    back_action.triggered.connect(go_back)

    forward_action = QAction("Forward", parent)
    forward_action.setShortcut("Alt+Right")
    forward_action.setToolTip("Go forward to the next page")
    forward_action.setStatusTip("Go forward to the next page")
    forward_action.setEnabled(False)
    forward_action.triggered.connect(go_forward)

    home_action = QAction("Home", parent)
    home_action.setShortcut("Alt+Home")
    home_action.setToolTip("Load the configured home page")
    home_action.setStatusTip("Load the configured home page")
    home_action.triggered.connect(load_home)

    reload_action = QAction("Reload", parent)
    reload_action.setShortcut("Ctrl+R")
    reload_action.setToolTip("Reload the current page")
    reload_action.setStatusTip("Reload the current page")
    reload_action.triggered.connect(reload_page)

    preferences_action = QAction("Preferences...", parent)
    preferences_action.setIconText("Preferences")
    preferences_action.setStatusTip("Edit GrayHaired Desktop preferences")
    preferences_action.triggered.connect(show_preferences)

    about_action = QAction("About", parent)
    about_action.setStatusTip("About GrayHaired Desktop")
    about_action.triggered.connect(show_about)

    return ApplicationActions(
        exit=exit_action,
        back=back_action,
        forward=forward_action,
        home=home_action,
        reload=reload_action,
        preferences=preferences_action,
        about=about_action,
    )
