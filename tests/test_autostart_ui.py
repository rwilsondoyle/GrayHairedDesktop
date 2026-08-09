"""Settings behavior when automatic start is or is not available."""

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.preferences import PreferencesDialog


def test_autostart_control_enabled_with_stable_launcher(qt_app):
    dialog = PreferencesDialog(UserPreferences(), autostart_available=True)

    assert dialog._autostart.isEnabled()
    assert dialog._autostart_help.isHidden()


def test_autostart_control_disabled_without_stable_launcher(qt_app):
    dialog = PreferencesDialog(UserPreferences(), autostart_available=False)

    assert not dialog._autostart.isEnabled()
    assert not dialog._autostart.isChecked()
    assert "installed as a desktop application" in dialog._autostart.toolTip()
    assert not dialog._autostart_help.isHidden()


def test_unavailable_control_preserves_previously_enabled_setting(qt_app):
    dialog = PreferencesDialog(
        UserPreferences(autostart=True), autostart_available=False
    )

    assert not dialog._autostart.isEnabled()
    assert not dialog._autostart.isChecked()
    assert dialog.preferences.autostart is True
