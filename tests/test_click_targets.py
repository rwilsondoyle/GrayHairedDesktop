"""Focused checks for click-target sizing."""

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import QSettings
from PySide6.QtWidgets import QApplication, QPushButton

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.favorite_dialog import FavoriteDialog
from grayhaired_desktop.ui.favorites import FavoritesWidget
from grayhaired_desktop.ui.preferences import PreferencesDialog


@pytest.fixture(scope="module")
def qapp():
    """Keep the single Qt application alive for this module's GUI tests."""

    app = QApplication.instance() or QApplication([])
    yield app


def test_all_visible_shortcut_buttons_have_42_pixel_minimum(tmp_path, qapp) -> None:
    """Normal, Add Shortcut, and any More button share the larger target."""

    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)
    widget = FavoritesWidget(settings, lambda _url: None)

    buttons = widget.findChildren(QPushButton)
    assert buttons
    assert all(button.minimumHeight() >= 42 for button in buttons)
    assert widget._ROW_SPACING == 8


def test_settings_interactive_controls_have_comfortable_minimums(qapp) -> None:
    """Settings fields, choices, and actions expose non-fragile minimum sizes."""

    dialog = PreferencesDialog(UserPreferences())

    assert dialog._home_page_url.minimumHeight() >= 40
    assert dialog._shortcut_theme.minimumHeight() >= 40
    assert dialog._open_button.minimumHeight() >= 40
    assert all(button.minimumHeight() >= 38 for button in dialog._website_buttons.buttons())


def test_shortcut_editor_controls_have_40_pixel_minimums(qapp) -> None:
    """The shortcut editor fields and dialog actions use comfortable targets."""

    dialog = FavoriteDialog()

    assert dialog._name.minimumHeight() >= 40
    assert dialog._address.minimumHeight() >= 40
    assert dialog._icon.minimumHeight() >= 40
    assert all(button.minimumHeight() >= 40 for button in dialog.findChildren(QPushButton))
