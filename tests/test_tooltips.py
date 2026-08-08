"""Tests for explicit tooltip resolution."""

import os

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QMenu, QToolButton

from grayhaired_desktop.ui.tooltips import (
    ExplicitToolTipFilter,
    HelpBubble,
    MenuHelpBubble,
    MenuHelpController,
)


def test_menu_help_tracks_hovered_action_and_clears(qt_app) -> None:
    """Menu help follows action changes and clears without using QToolTip."""

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
    qt_app.processEvents()


def test_widget_tooltip_uses_shared_bubble_for_open_controls(qt_app) -> None:
    """The gear's explicit filter uses the shared non-focusable help bubble."""

    gear = QToolButton()
    gear.setToolTip("Open controls")
    bubble = HelpBubble(gear)
    tooltip_filter = ExplicitToolTipFilter(gear, bubble)

    assert tooltip_filter.tooltip_at(gear, gear.rect().center()) == "Open controls"
    assert bubble.testAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)
    assert bubble.windowFlags() & Qt.WindowType.WindowDoesNotAcceptFocus
    assert bubble.focusPolicy() == Qt.FocusPolicy.NoFocus
    assert bubble.margin() == 6
    qt_app.processEvents()
