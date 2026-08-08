"""Application action creation for the main window."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Protocol

from PySide6.QtCore import QObject
from PySide6.QtGui import QAction


@dataclass(frozen=True, slots=True)
class ApplicationActions:
    """Actions shared by the application's menus and toolbar."""

    exit: QAction
    home: QAction
    reload: QAction
    desktop_website: QAction
    about: QAction
    open_log_folder: QAction


class ActionHost(Protocol):
    """Qt widget capable of keeping an action active independently of menus."""

    def addAction(self, action: QAction) -> None:  # noqa: N802 - Qt API name
        """Associate an action with the widget."""


def register_window_navigation_actions(
    host: ActionHost, actions: ApplicationActions
) -> None:
    """Keep navigation shortcuts active when their containing menus are hidden."""

    host.addAction(actions.home)
    host.addAction(actions.reload)


def create_actions(
    parent: QObject,
    *,
    close: Callable[[], object],
    load_home: Callable[[], object],
    reload_page: Callable[[], object],
    show_preferences: Callable[[], object],
    show_about: Callable[[], object],
    open_log_folder: Callable[[], object],
) -> ApplicationActions:
    """Create the main-window actions and connect their callbacks."""

    exit_action = QAction("Exit", parent)
    exit_action.setToolTip("Close GrayHaired Desktop")
    exit_action.setStatusTip("Close GrayHaired Desktop")
    exit_action.setWhatsThis("Close GrayHaired Desktop")
    exit_action.triggered.connect(close)

    home_action = QAction("Home", parent)
    home_action.setShortcut("Alt+H")
    home_action.setToolTip("Return to your saved Desktop Website")
    home_action.setStatusTip("Return to your saved Desktop Website")
    home_action.setWhatsThis("Return to your saved Desktop Website")
    home_action.triggered.connect(load_home)

    reload_action = QAction("Reload", parent)
    reload_action.setShortcut("Ctrl+R")
    reload_action.setToolTip("Refresh the current Desktop Website")
    reload_action.setStatusTip("Refresh the current Desktop Website")
    reload_action.setWhatsThis("Refresh the current Desktop Website")
    reload_action.triggered.connect(reload_page)

    desktop_website_action = QAction("Desktop Website...", parent)
    desktop_website_action.setToolTip(
        "Choose the Desktop Website and shortcut appearance"
    )
    desktop_website_action.setStatusTip(
        "Choose the Desktop Website and shortcut appearance"
    )
    desktop_website_action.setWhatsThis(
        "Choose the Desktop Website and shortcut appearance"
    )
    desktop_website_action.triggered.connect(show_preferences)

    about_action = QAction("About", parent)
    about_action.setToolTip("View information about GrayHaired Desktop")
    about_action.setStatusTip("About GrayHaired Desktop")
    about_action.setWhatsThis("View information about GrayHaired Desktop")
    about_action.triggered.connect(show_about)

    open_log_folder_action = QAction("Open Log Folder", parent)
    open_log_folder_action.setToolTip(
        "Open the folder containing diagnostic logs"
    )
    open_log_folder_action.setStatusTip("Open the folder containing diagnostic logs")
    open_log_folder_action.triggered.connect(open_log_folder)

    return ApplicationActions(
        exit=exit_action,
        home=home_action,
        reload=reload_action,
        desktop_website=desktop_website_action,
        about=about_action,
        open_log_folder=open_log_folder_action,
    )
