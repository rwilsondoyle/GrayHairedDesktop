"""Tests for explicit tooltip resolution."""

import os

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtWidgets import QApplication, QMenu, QToolButton

from grayhaired_desktop.ui.tooltips import (
    ExplicitToolTipFilter,
    MenuHelpBubble,
    MenuHelpController,
)


def test_menu_help_tracks_hovered_action_and_clears() -> None:
    """Menu help follows action changes and clears without using QToolTip."""

    app = QApplication.instance() or QApplication([])
    menu = QMenu("View")
    bubble = MenuHelpBubble(menu)
    controller = MenuHelpController(menu, bubble)
    home = menu.addAction("Home")
    home.setToolTip("Return to your saved Desktop Website")
    reload_action = menu.addAction("Reload")
    reload_action.setToolTip("Refresh the current Desktop Website")

    controller.select_action(home)
    assert controller.pending_text == "Return to your saved Desktop Website"

    controller.select_action(reload_action)
    assert controller.pending_text == "Refresh the current Desktop Website"

    controller.clear()
    assert controller.pending_text == ""
    assert bubble.isHidden()
    app.processEvents()


def test_widget_tooltip_resolves_open_controls_metadata() -> None:
    """The gear's explicit filter reads its retained Open controls tooltip."""

    app = QApplication.instance() or QApplication([])
    gear = QToolButton()
    gear.setToolTip("Open controls")

    assert ExplicitToolTipFilter.tooltip_at(gear, gear.rect().center()) == (
        "Open controls"
    )
    app.processEvents()
