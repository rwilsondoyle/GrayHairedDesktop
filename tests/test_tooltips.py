"""Tests for explicit tooltip resolution."""

import os

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import Qt
from PySide6.QtTest import QTest
from PySide6.QtWidgets import QMenu, QMenuBar, QToolButton

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


def test_widget_activation_hides_help_without_consuming_click(qt_app) -> None:
    """Pressing the gear hides its help and still activates the button."""

    gear = QToolButton()
    bubble = HelpBubble(gear)
    tooltip_filter = ExplicitToolTipFilter(gear, bubble)
    gear.installEventFilter(tooltip_filter)
    activations = []
    gear.clicked.connect(lambda: activations.append(True))
    gear.show()
    bubble.setText("Open controls")
    bubble.show()
    qt_app.processEvents()
    assert bubble.isVisible()

    QTest.mouseClick(gear, Qt.MouseButton.LeftButton)
    qt_app.processEvents()

    assert bubble.isHidden()
    assert activations == [True]


def test_help_bubble_presentation_does_not_depend_on_parent(qt_app) -> None:
    """Menu-bar and control bubbles use one centrally defined presentation."""

    menu_bubble = HelpBubble(QMenuBar())
    gear_bubble = HelpBubble(QToolButton())

    assert menu_bubble.font().family() == gear_bubble.font().family()
    assert menu_bubble.font().pointSizeF() == gear_bubble.font().pointSizeF()
    assert menu_bubble.font().weight() == gear_bubble.font().weight()
    assert menu_bubble.styleSheet() == gear_bubble.styleSheet()
    assert "background-color: #202020" in menu_bubble.styleSheet()
    assert "color: #f5f5f5" in menu_bubble.styleSheet()
    assert "border: 1px solid #505050" in menu_bubble.styleSheet()
    assert menu_bubble.margin() == gear_bubble.margin() == 6
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
