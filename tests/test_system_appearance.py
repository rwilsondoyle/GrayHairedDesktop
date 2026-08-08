"""Focused checks for Zorin system appearance compatibility."""

from subprocess import CompletedProcess, TimeoutExpired

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtGui import QColor, QPalette
from PySide6.QtWidgets import QLineEdit, QPushButton

from grayhaired_desktop.appearance import (
    SystemAppearance,
    apply_system_appearance,
    detect_system_appearance,
    palette_appearance,
)
from grayhaired_desktop.ui.favorites import FavoritesWidget


@pytest.mark.parametrize(
    ("setting", "expected"),
    [
        ("'default'\n", SystemAppearance.LIGHT),
        ("'prefer-light'\n", SystemAppearance.LIGHT),
        ("'prefer-dark'\n", SystemAppearance.DARK),
        ("'something-new'\n", SystemAppearance.UNKNOWN),
    ],
)
def test_detect_system_appearance(monkeypatch, setting, expected) -> None:
    """GNOME color-scheme values map to stable internal values."""

    monkeypatch.setattr(
        "grayhaired_desktop.appearance.subprocess.run",
        lambda *args, **kwargs: CompletedProcess(args[0], 0, setting, ""),
    )

    assert detect_system_appearance() is expected


def test_unavailable_system_setting_keeps_qt_native_palette(monkeypatch, qt_app) -> None:
    """A missing GNOME setting safely leaves Qt's palette untouched."""

    monkeypatch.setattr(
        "grayhaired_desktop.appearance.subprocess.run",
        lambda *args, **kwargs: (_ for _ in ()).throw(TimeoutExpired("gsettings", 2)),
    )
    before = QPalette(qt_app.palette())

    detected = detect_system_appearance()
    changed = apply_system_appearance(qt_app, detected)

    assert detected is SystemAppearance.UNKNOWN
    assert not changed
    assert qt_app.palette() == before


def test_detected_dark_corrects_a_light_qt_palette(qt_app) -> None:
    """Zorin dark gets a readable application-wide palette when Qt misses it."""

    light = QPalette()
    light.setColor(QPalette.ColorRole.Window, QColor("white"))
    light.setColor(QPalette.ColorRole.WindowText, QColor("black"))
    qt_app.setPalette(light)

    assert apply_system_appearance(qt_app, SystemAppearance.DARK)
    assert palette_appearance(qt_app.palette()) is SystemAppearance.DARK
    for role in (
        QPalette.ColorRole.Window,
        QPalette.ColorRole.WindowText,
        QPalette.ColorRole.Base,
        QPalette.ColorRole.AlternateBase,
        QPalette.ColorRole.ToolTipBase,
        QPalette.ColorRole.ToolTipText,
        QPalette.ColorRole.Text,
        QPalette.ColorRole.Button,
        QPalette.ColorRole.ButtonText,
        QPalette.ColorRole.BrightText,
        QPalette.ColorRole.Highlight,
        QPalette.ColorRole.HighlightedText,
        QPalette.ColorRole.PlaceholderText,
    ):
        assert qt_app.palette().color(role).isValid()


def test_dark_fallback_has_readable_distinct_disabled_colors(qt_app) -> None:
    """Disabled controls remain muted but legible under the dark fallback."""

    original_palette = QPalette(qt_app.palette())
    light = QPalette()
    light.setColor(QPalette.ColorRole.Window, QColor("white"))
    light.setColor(QPalette.ColorRole.WindowText, QColor("black"))
    qt_app.setPalette(light)
    assert apply_system_appearance(qt_app, SystemAppearance.DARK)
    palette = qt_app.palette()
    disabled = QPalette.ColorGroup.Disabled
    active = QPalette.ColorGroup.Active

    expected = {
        QPalette.ColorRole.WindowText: "#a8a8a8",
        QPalette.ColorRole.Text: "#a8a8a8",
        QPalette.ColorRole.ButtonText: "#a8a8a8",
        QPalette.ColorRole.PlaceholderText: "#858585",
        QPalette.ColorRole.Base: "#2b2b2b",
        QPalette.ColorRole.Button: "#454545",
    }
    for role, color_name in expected.items():
        disabled_color = palette.color(disabled, role)
        assert disabled_color.isValid()
        assert disabled_color.name() == color_name
        assert disabled_color != palette.color(active, role)

    line_edit = QLineEdit()
    line_edit.setEnabled(False)
    assert line_edit.palette().currentColorGroup() == disabled
    assert line_edit.palette().color(disabled, QPalette.ColorRole.Text).name() == (
        "#a8a8a8"
    )
    assert palette_appearance(palette) is SystemAppearance.DARK

    line_edit.deleteLater()
    qt_app.setPalette(original_palette)
    qt_app.processEvents()


def test_detected_light_corrects_a_dark_qt_palette(qt_app) -> None:
    """Zorin light restores Qt's native Fusion light palette when needed."""

    dark = QPalette()
    dark.setColor(QPalette.ColorRole.Window, QColor("black"))
    dark.setColor(QPalette.ColorRole.WindowText, QColor("white"))
    qt_app.setPalette(dark)

    assert apply_system_appearance(qt_app, SystemAppearance.LIGHT)
    assert palette_appearance(qt_app.palette()) is SystemAppearance.LIGHT


def test_shortcut_choices_remain_independent_of_application_palette(
    tmp_path, qt_app
) -> None:
    """Explicit shortcut themes stay explicit and Match Computer stays native."""

    from PySide6.QtCore import QSettings

    apply_system_appearance(qt_app, SystemAppearance.DARK)
    widget = FavoritesWidget(
        QSettings(str(tmp_path / "appearance.ini"), QSettings.Format.IniFormat),
        lambda _url: None,
    )

    widget.set_theme("light")
    assert widget.styleSheet() == FavoritesWidget._LIGHT_STYLE
    widget.set_theme("dark")
    assert widget.styleSheet() == FavoritesWidget._DARK_STYLE
    widget.set_theme("system")
    assert widget.styleSheet() == ""
    button = widget.findChildren(QPushButton)[0]
    assert palette_appearance(button.palette()) is SystemAppearance.DARK

    widget.deleteLater()
    qt_app.processEvents()
