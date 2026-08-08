"""Tests for explicit tooltip resolution."""

import os

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtWidgets import QApplication, QMenu, QToolButton

from grayhaired_desktop.ui.tooltips import ExplicitToolTipFilter


def test_menu_tooltip_resolves_action_under_position() -> None:
    """Menu tooltip lookup uses the action underneath the help event position."""

    app = QApplication.instance() or QApplication([])
    menu = QMenu()
    action = menu.addAction("Exit")
    action.setToolTip("Close GrayHaired Desktop")
    menu.ensurePolished()

    tooltip = ExplicitToolTipFilter.tooltip_at(
        menu, menu.actionGeometry(action).center()
    )

    assert tooltip == "Close GrayHaired Desktop"
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
