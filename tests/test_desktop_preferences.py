"""Persistence checks for new opt-in desktop preferences."""

from PySide6.QtCore import QSettings

from grayhaired_desktop.settings import UserPreferences, load_preferences, save_preferences


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
    assert loaded.home_page_url == expected.home_page_url
    assert loaded.shortcut_theme == expected.shortcut_theme
    assert loaded.desktop_mode is False
    assert loaded.autostart is True
    assert settings.value("preferences/desktopMode", type=bool) is False


def test_legacy_true_desktop_mode_is_ignored(tmp_path):
    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)
    settings.setValue("preferences/desktopMode", True)

    assert load_preferences(settings).desktop_mode is False
