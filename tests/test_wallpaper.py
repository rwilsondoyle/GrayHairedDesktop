"""Safe Wallpaper Mode unit and UI tests (never mutate the real desktop)."""

from __future__ import annotations

import logging
import subprocess

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)

from PySide6.QtCore import QSettings

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.preferences import PreferencesDialog
from grayhaired_desktop.wallpaper import (
    BACKGROUND_SCHEMA,
    HAS_PREVIOUS_KEY,
    PREVIOUS_OPTIONS_KEY,
    PREVIOUS_URI_DARK_KEY,
    PREVIOUS_URI_KEY,
    BackgroundSettings,
    WallpaperManager,
    file_uri,
    has_previous_wallpaper,
    read_background_settings,
    restore_background_settings,
    set_background_wallpaper,
    wallpaper_path,
)


class FakeGSettings:
    def __init__(self, values: dict[str, str], fail_set: str | None = None) -> None:
        self.values = values
        self.fail_set = fail_set
        self.calls: list[list[str]] = []

    def __call__(self, arguments, **kwargs):
        arguments = list(arguments)
        self.calls.append(arguments)
        assert arguments[:3] in (
            ["gsettings", "get", BACKGROUND_SCHEMA],
            ["gsettings", "set", BACKGROUND_SCHEMA],
        )
        assert kwargs == {"check": True, "capture_output": True, "text": True}
        operation, key = arguments[1], arguments[3]
        if operation == "get":
            return subprocess.CompletedProcess(arguments, 0, f"'{self.values[key]}'\n", "")
        if key == self.fail_set:
            raise subprocess.CalledProcessError(1, arguments)
        self.values[key] = arguments[4]
        return subprocess.CompletedProcess(arguments, 0, "", "")


@pytest.fixture
def ini_settings(tmp_path):
    return QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)


@pytest.fixture
def background_values():
    return {
        "picture-uri": "file:///light.jpg",
        "picture-uri-dark": "file:///dark.jpg",
        "picture-options": "zoom",
    }


def test_wallpaper_path_is_deterministic_user_data(tmp_path):
    assert wallpaper_path(tmp_path) == (
        tmp_path
        / ".local/share/GrayHairedDesktop/wallpaper/my-desktop-wallpaper.png"
    )


def test_file_uri_encodes_local_path(tmp_path):
    assert file_uri(tmp_path / "My Wallpaper.png").endswith("/My%20Wallpaper.png")


def test_background_settings_are_captured_separately(background_values):
    captured = read_background_settings(FakeGSettings(background_values.copy()))
    assert captured == BackgroundSettings(
        "file:///light.jpg", "file:///dark.jpg", "zoom"
    )


def test_refresh_preserves_original_background(
    ini_settings, background_values, tmp_path
):
    fake = FakeGSettings(background_values.copy())
    manager = WallpaperManager(ini_settings, logging.getLogger(), fake)
    image = tmp_path / "snapshot.png"
    image.write_bytes(b"png")

    assert manager.apply(image)
    fake.values.update(
        {
            "picture-uri": "file:///changed-light.jpg",
            "picture-uri-dark": "file:///changed-dark.jpg",
            "picture-options": "centered",
        }
    )
    assert manager.apply(image)

    assert ini_settings.value(PREVIOUS_URI_KEY) == "file:///light.jpg"
    assert ini_settings.value(PREVIOUS_URI_DARK_KEY) == "file:///dark.jpg"
    assert ini_settings.value(PREVIOUS_OPTIONS_KEY) == "zoom"


def test_restore_uses_original_values_and_clears_marker(
    ini_settings, background_values, tmp_path
):
    fake = FakeGSettings(background_values.copy())
    manager = WallpaperManager(ini_settings, logging.getLogger(), fake)
    image = tmp_path / "snapshot.png"
    image.write_bytes(b"png")
    assert manager.apply(image)

    assert manager.restore()
    assert fake.values == background_values
    assert not has_previous_wallpaper(ini_settings)


def test_helpers_use_argument_lists_without_shell(background_values):
    fake = FakeGSettings(background_values.copy())
    set_background_wallpaper("file:///snapshot.png", fake)
    restore_background_settings(
        BackgroundSettings("file:///a.png", "file:///b.png", "scaled"), fake
    )
    assert all(isinstance(call, list) for call in fake.calls)


def test_failed_mutation_reports_false_and_keeps_restore_state(
    ini_settings, background_values, tmp_path
):
    fake = FakeGSettings(background_values.copy(), fail_set="picture-uri-dark")
    manager = WallpaperManager(ini_settings, logging.getLogger(), fake)

    assert not manager.apply(tmp_path / "snapshot.png")
    assert ini_settings.value(HAS_PREVIOUS_KEY, False, bool)
    assert ini_settings.value(PREVIOUS_URI_KEY) == "file:///light.jpg"


def test_restore_button_tracks_saved_previous_wallpaper(
    qt_app, ini_settings, monkeypatch
):
    monkeypatch.setattr("grayhaired_desktop.ui.preferences.shutil.which", lambda _: "/bin/gsettings")
    dialog = PreferencesDialog(
        UserPreferences(), settings=ini_settings, logger=logging.getLogger()
    )
    assert not dialog._restore_wallpaper_button.isEnabled()
    ini_settings.setValue(HAS_PREVIOUS_KEY, True)
    dialog._set_wallpaper_busy(False)
    assert dialog._restore_wallpaper_button.isEnabled()


def test_settings_ui_uses_static_wallpaper_wording(qt_app, ini_settings):
    dialog = PreferencesDialog(UserPreferences(), settings=ini_settings)
    labels = " ".join(label.text() for label in dialog.findChildren(type(dialog._wallpaper_status)))
    buttons = " ".join(button.text() for button in dialog.findChildren(type(dialog._set_wallpaper_button)))
    assert "Desktop Wallpaper" in labels
    assert "normal desktop icons stay in place" in labels
    assert "Desktop Mode" not in labels + buttons


def test_failed_render_does_not_mutate_wallpaper(qt_app, ini_settings):
    class Manager:
        apply_calls = 0

        def apply(self, _path):
            self.apply_calls += 1
            return True

    dialog = PreferencesDialog(UserPreferences(), settings=ini_settings)
    manager = Manager()
    dialog._wallpaper_manager = manager

    dialog._wallpaper_rendered(False, "load failed")

    assert manager.apply_calls == 0
    assert "not changed" in dialog._wallpaper_status.text()
