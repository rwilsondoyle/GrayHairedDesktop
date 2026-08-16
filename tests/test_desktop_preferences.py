"""Persistence checks for new opt-in desktop preferences."""

from pathlib import Path

from PySide6.QtCore import QSettings

from grayhaired_desktop.settings import (
    UserPreferences,
    load_preferences,
    save_preferences,
    startup_desktop_mode_requested,
)


def test_desktop_options_default_off(tmp_path):
    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)

    preferences = load_preferences(settings)

    assert preferences.desktop_mode is False
    assert preferences.autostart is False


def test_legacy_desktop_mode_is_forced_off_without_changing_other_preferences(tmp_path):
    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)
    expected = UserPreferences(
        home_page_url="https://example.com",
        shortcut_theme="dark",
        desktop_mode=True,
        autostart=True,
    )

    save_preferences(settings, expected)

    loaded = load_preferences(settings)
    assert loaded == UserPreferences(
        home_page_url=expected.home_page_url,
        shortcut_theme=expected.shortcut_theme,
        desktop_mode=False,
        autostart=expected.autostart,
    )
    assert settings.value("preferences/desktopMode", type=bool) is False


def test_startup_ignores_legacy_desktop_mode_request():
    preferences = UserPreferences(desktop_mode=True)

    assert startup_desktop_mode_requested(preferences) is False


def test_normal_settings_source_has_no_desktop_mode_control():
    preferences_source = (
        Path(__file__).parents[1]
        / "src"
        / "grayhaired_desktop"
        / "ui"
        / "preferences.py"
    ).read_text(encoding="utf-8")

    assert "Desktop Mode" not in preferences_source
    assert "_desktop_mode" not in preferences_source
