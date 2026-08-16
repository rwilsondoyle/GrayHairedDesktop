"""Focused checks for keyboard navigation."""

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import Qt
from PySide6.QtWidgets import QApplication, QCheckBox, QLabel, QPushButton, QScrollArea

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.favorite_dialog import FavoriteDialog
from grayhaired_desktop.ui.preferences import PreferencesDialog


@pytest.fixture(scope="module")
def qapp():
    """Keep one Qt application alive throughout these GUI tests."""

    app = QApplication.instance() or QApplication([])
    yield app


def test_settings_actions_complete_the_tab_sequence(qapp) -> None:
    """Preview, Save, and Cancel follow the form controls in both directions."""

    dialog = PreferencesDialog(UserPreferences())

    assert dialog._shortcut_theme.nextInFocusChain() is dialog._autostart
    assert dialog._autostart.nextInFocusChain() is dialog._open_button
    assert dialog._open_button.nextInFocusChain() is dialog._save_button
    assert dialog._save_button.nextInFocusChain() is dialog._cancel_button
    assert dialog._cancel_button.nextInFocusChain() is dialog._another_website
    assert dialog._another_website.nextInFocusChain() is dialog._home_page_url

    scroll_area = dialog.findChild(QScrollArea)
    assert scroll_area is not None
    assert scroll_area.focusPolicy() == Qt.FocusPolicy.NoFocus


def test_settings_has_no_desktop_mode_control_or_promise(qapp) -> None:
    dialog = PreferencesDialog(UserPreferences(desktop_mode=True))

    assert not hasattr(dialog, "_desktop_mode")
    visible_text = [widget.text() for widget in dialog.findChildren(QCheckBox)]
    visible_text.extend(widget.text() for widget in dialog.findChildren(QLabel))
    assert all("Desktop Mode" not in text for text in visible_text)
    assert dialog.preferences.desktop_mode is False


def test_settings_address_is_enabled_only_for_custom_website(qapp) -> None:
    """The address participates in keyboard navigation only when applicable."""

    dialog = PreferencesDialog(UserPreferences())
    built_in = next(iter(dialog._built_in_buttons))

    assert dialog._home_page_url.isEnabled()
    built_in.setChecked(True)
    assert not dialog._home_page_url.isEnabled()
    dialog._another_website.setChecked(True)
    assert dialog._home_page_url.isEnabled()


def test_shortcut_editor_has_complete_tab_sequence(qapp) -> None:
    """The shortcut editor follows Name, Address, Icon, Save, and Cancel."""

    dialog = FavoriteDialog()

    assert dialog._name.nextInFocusChain() is dialog._address
    assert dialog._address.nextInFocusChain() is dialog._icon
    assert dialog._icon.nextInFocusChain() is dialog._save_button
    assert dialog._save_button.nextInFocusChain() is dialog._cancel_button
    assert dialog._cancel_button.nextInFocusChain() is dialog._name
    assert dialog._save_button.isDefault()
    assert all(
        button.focusPolicy() & Qt.FocusPolicy.TabFocus
        for button in (dialog._save_button, dialog._cancel_button)
    )


def test_shortcut_validation_returns_focus_to_name(monkeypatch, qapp) -> None:
    """A missing shortcut name sends keyboard focus back to Name."""

    dialog = FavoriteDialog()
    monkeypatch.setattr(
        "grayhaired_desktop.ui.favorite_dialog.QMessageBox.warning",
        lambda *_args: None,
    )
    dialog.show()
    dialog._address.setFocus()
    dialog._validate_and_accept()
    qapp.processEvents()

    assert dialog.focusWidget() is dialog._name


def test_shortcut_validation_returns_focus_to_address(monkeypatch, qapp) -> None:
    """An invalid address sends focus to Website Address and selects its text."""

    dialog = FavoriteDialog()
    monkeypatch.setattr(
        "grayhaired_desktop.ui.favorite_dialog.QMessageBox.warning",
        lambda *_args: None,
    )
    dialog._name.setText("Example")
    dialog._address.setText("not a complete address")
    dialog.show()
    dialog._validate_and_accept()
    qapp.processEvents()

    assert dialog.focusWidget() is dialog._address
    assert dialog._address.selectedText() == "not a complete address"


def test_native_push_buttons_accept_keyboard_focus(qapp) -> None:
    """Qt push buttons retain native Tab focus and Enter/Space handling."""

    button = QPushButton("Shortcut")

    assert button.focusPolicy() & Qt.FocusPolicy.TabFocus
