"""Tests for the main-window action configuration."""

import pytest

pytest.importorskip("PySide6.QtGui", exc_type=ImportError)
from PySide6.QtCore import QObject

from grayhaired_desktop.ui.actions import create_actions


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
