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
    home: QAction
    reload: QAction
    preferences: QAction
    about: QAction


def create_actions(
    parent: QObject,
    *,
    close: Callable[[], object],
    load_home: Callable[[], object],
    reload_page: Callable[[], object],
    show_preferences: Callable[[], object],
    show_about: Callable[[], object],
) -> ApplicationActions:
    """Create the main-window actions and connect their callbacks."""

    exit_action = QAction("Exit", parent)
    exit_action.setStatusTip("Close GrayHaired Desktop")
    exit_action.triggered.connect(close)

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
        home=home_action,
        reload=reload_action,
        preferences=preferences_action,
        about=about_action,
    )
