"""Focused checks for Alpha 0.9 user-visible terminology."""

import os

import pytest

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtWidgets import QApplication, QLabel

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.favorite_dialog import (
    FavoriteDialog,
    INVALID_ADDRESS_MESSAGE,
    MISSING_NAME_MESSAGE,
)
from grayhaired_desktop.ui.preferences import (
    INVALID_URL_MESSAGE,
    OPEN_WEBSITE_FAILURE_MESSAGE,
    PREVIEW_DESCRIPTION,
    PreferencesDialog,
)


@pytest.fixture(scope="module")
def qapp():
    """Keep one Qt application alive for the wording checks."""

    app = QApplication.instance() or QApplication([])
    yield app


def test_settings_uses_approved_desktop_website_terms(qapp) -> None:
    """Settings labels and accessibility metadata use the approved terms."""

    dialog = PreferencesDialog(UserPreferences())
    labels = {label.text() for label in dialog.findChildren(QLabel)}

    assert dialog.windowTitle() == "Settings"
    assert "Desktop Website" in labels
    assert "Choose the website to display on your desktop." in labels
    assert "Website Address" in labels
    assert dialog._home_page_url.accessibleName() == "Website Address"
    assert dialog._open_button.text() == "Preview in Browser"
    assert dialog._open_button.toolTip() == PREVIEW_DESCRIPTION
    assert "without saving changes" in PREVIEW_DESCRIPTION
    assert OPEN_WEBSITE_FAILURE_MESSAGE == (
        "The selected website could not be opened in your default browser. Check that "
        "your computer has a working default browser and try again."
    )


def test_shortcut_editor_explains_how_to_fix_missing_details(qapp) -> None:
    """Shortcut fields and validation messages identify the needed input."""

    dialog = FavoriteDialog()

    assert dialog.windowTitle() == "Add Shortcut"
    assert dialog._name.accessibleName() == "Name"
    assert dialog._address.accessibleName() == "Website Address"
    assert MISSING_NAME_MESSAGE == "Please enter a name for this shortcut."
    assert INVALID_ADDRESS_MESSAGE == INVALID_URL_MESSAGE
    assert "http:// or https://" in INVALID_ADDRESS_MESSAGE
