"""Tests for the main-window action configuration."""

import pytest

pytest.importorskip("PySide6.QtGui", exc_type=ImportError)
from PySide6.QtCore import QObject

from grayhaired_desktop.ui.actions import (
    create_actions,
    register_window_navigation_actions,
)


def test_home_and_reload_action_configuration() -> None:
    """Home and Reload expose their intended shortcuts and help text."""

    def callback() -> None:
        pass

    actions = create_actions(
        QObject(),
        close=callback,
        load_home=callback,
        reload_page=callback,
        show_preferences=callback,
        show_about=callback,
        open_log_folder=callback,
    )

    assert actions.home.shortcut().toString() == "Alt+H"
    assert actions.home.toolTip() == "Return to your saved Desktop Website"
    assert actions.reload.shortcut().toString() == "Ctrl+R"
    assert actions.reload.toolTip() == "Refresh the current Desktop Website"


def test_key_actions_expose_plain_english_help() -> None:
    """Key menu and toolbar actions provide concise descriptive metadata."""

    def callback() -> None:
        pass

    actions = create_actions(
        QObject(),
        close=callback,
        load_home=callback,
        reload_page=callback,
        show_preferences=callback,
        show_about=callback,
        open_log_folder=callback,
    )

    assert actions.home.whatsThis() == "Return to your saved Desktop Website"
    assert actions.reload.whatsThis() == "Refresh the current Desktop Website"
    assert actions.desktop_website.text() == "Desktop Website..."
    assert actions.desktop_website.whatsThis() == (
        "Choose the Desktop Website and shortcut appearance"
    )
    assert actions.about.whatsThis() == "View information about GrayHaired Desktop"
    assert actions.exit.whatsThis() == "Close GrayHaired Desktop"


def test_desktop_website_action_uses_settings_callback() -> None:
    """The Settings menu item opens the existing Settings workflow."""

    settings_requests = []

    def callback() -> None:
        pass

    actions = create_actions(
        QObject(),
        close=callback,
        load_home=callback,
        reload_page=callback,
        show_preferences=lambda: settings_requests.append("requested"),
        show_about=callback,
        open_log_folder=callback,
    )

    actions.desktop_website.trigger()

    assert settings_requests == ["requested"]


def test_navigation_shortcuts_are_registered_with_window() -> None:
    """Home and Reload remain active when the menu bar is hidden."""

    registered_actions = []

    class ActionHost:
        def addAction(self, action) -> None:  # noqa: ANN001, N802
            registered_actions.append(action)

    def callback() -> None:
        pass

    actions = create_actions(
        QObject(),
        close=callback,
        load_home=callback,
        reload_page=callback,
        show_preferences=callback,
        show_about=callback,
        open_log_folder=callback,
    )

    register_window_navigation_actions(ActionHost(), actions)

    assert registered_actions == [actions.home, actions.reload]
    assert registered_actions[0].shortcut().toString() == "Alt+H"
    assert registered_actions[1].shortcut().toString() == "Ctrl+R"
