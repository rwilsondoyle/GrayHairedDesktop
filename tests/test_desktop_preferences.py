"""Persistence checks for new opt-in desktop preferences."""

from PySide6.QtCore import QSettings

from grayhaired_desktop.settings import UserPreferences, load_preferences, save_preferences


def test_desktop_options_default_off(tmp_path):
    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)

    preferences = load_preferences(settings)

    assert preferences.desktop_mode is False
    assert preferences.autostart is False


def test_desktop_options_round_trip_without_changing_other_preferences(tmp_path):
    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)
    expected = UserPreferences(
        home_page_url="https://example.com",
        shortcut_theme="dark",
        desktop_mode=True,
        autostart=True,
    )

    save_preferences(settings, expected)

    assert load_preferences(settings) == expected
