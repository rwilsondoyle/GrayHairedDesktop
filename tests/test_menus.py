"""Tests for the top-level application menu configuration."""

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import QObject
from PySide6.QtWidgets import QApplication, QMenuBar

from grayhaired_desktop.ui.actions import create_actions
from grayhaired_desktop.ui.menus import create_menus


def test_done_is_final_top_level_action_and_hides_controls() -> None:
    """Done follows Help, exposes help text, and invokes the hide callback."""

    app = QApplication.instance() or QApplication([])
    parent = QObject()
    hide_requests = []
    callback = lambda: None
    actions = create_actions(
        parent,
        close=callback,
        load_home=callback,
        reload_page=callback,
        show_preferences=callback,
        show_about=callback,
        open_log_folder=callback,
    )
    menu_bar = QMenuBar()

    done = create_menus(menu_bar, actions, lambda: hide_requests.append(True))

    assert [action.text() for action in menu_bar.actions()] == [
        "File",
        "View",
        "Settings",
        "Help",
        "Done",
    ]
    assert done.menu() is None
    assert done.toolTip() == "Return to Desktop Website"
    assert done.statusTip() == "Return to Desktop Website"
    assert done.whatsThis() == "Return to Desktop Website"
    assert done.property("accessibleName") == "Done"
    assert done.property("accessibleDescription") == "Return to Desktop Website"

    done.trigger()

    assert hide_requests == [True]
    app.processEvents()
