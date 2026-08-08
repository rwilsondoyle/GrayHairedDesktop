"""Focused checks for system text, contrast, and compact layout compatibility."""

from pathlib import Path

import pytest

pytest.importorskip("PySide6.QtWidgets", exc_type=ImportError)
from PySide6.QtCore import QSettings
from PySide6.QtWidgets import QApplication, QLabel, QPushButton

from grayhaired_desktop.settings import UserPreferences
from grayhaired_desktop.ui.favorites import FavoritesWidget
from grayhaired_desktop.ui.preferences import PreferencesDialog
from grayhaired_desktop.ui.tooltips import HelpBubble


def test_shortcut_themes_inherit_the_application_font() -> None:
    """Shortcut themes must not block operating-system font scaling."""

    for style in (
        FavoritesWidget._SYSTEM_STYLE,
        FavoritesWidget._LIGHT_STYLE,
        FavoritesWidget._DARK_STYLE,
    ):
        assert "font-size" not in style


def test_match_computer_uses_native_button_painting() -> None:
    """The system theme must not replace Qt's native border with partial QSS."""

    assert FavoritesWidget._SYSTEM_STYLE == ""


def test_settings_section_titles_inherit_system_font(qt_app) -> None:
    """Section titles add emphasis without replacing the system-selected size."""

    dialog = PreferencesDialog(UserPreferences())
    titles = {
        label.text(): label for label in dialog.findChildren(QLabel)
    }

    for text in ("Desktop Website", "Shortcut Appearance"):
        title = titles[text]
        assert title.font().bold()
        assert title.font().pointSizeF() == dialog.font().pointSizeF()
        assert title.font().pixelSize() == dialog.font().pixelSize()

    dialog.deleteLater()
    qt_app.processEvents()


def test_help_bubble_uses_application_menu_font(qt_app) -> None:
    """Help text follows the shared, system-scaled menu font."""

    from PySide6.QtWidgets import QWidget

    parent = QWidget()
    bubble = HelpBubble(parent)
    menu_font = QApplication.font("QMenuBar")

    assert bubble.font().family() == menu_font.family()
    assert bubble.font().pointSizeF() == menu_font.pointSizeF()
    assert bubble.font().pixelSize() == menu_font.pixelSize()

    parent.deleteLater()
    qt_app.processEvents()


def test_compact_shortcut_geometry_contract_is_unchanged(tmp_path, qt_app) -> None:
    """Font compatibility must not consume more Desktop Website space."""

    settings = QSettings(str(tmp_path / "settings.ini"), QSettings.Format.IniFormat)
    widget = FavoritesWidget(settings, lambda _url: None)

    assert widget._BUTTON_MINIMUM_HEIGHT == 42
    assert widget._layout.count() <= 2

    application_button_font = QApplication.font("QPushButton")
    assert widget.font().family() == application_button_font.family()
    assert widget.font().pointSizeF() == application_button_font.pointSizeF()
    assert widget.font().pixelSize() == application_button_font.pixelSize()
    assert not widget.font().underline()
    assert all(
        not button.font().underline()
        for button in widget.findChildren(QPushButton)
    )

    widget.deleteLater()
    qt_app.processEvents()


def test_explicit_themes_keep_normal_and_focus_borders() -> None:
    """Light and Dark retain their intended borders and focus indication."""

    assert "border: 1px solid #a5abb2" in FavoritesWidget._LIGHT_STYLE
    assert "QPushButton:focus { border: 2px solid #155ea8; }" in (
        FavoritesWidget._LIGHT_STYLE
    )
    assert "border: 1px solid #666c73" in FavoritesWidget._DARK_STYLE
    assert "outline: none" in FavoritesWidget._DARK_STYLE
    assert "QPushButton:focus { border: 2px solid #8ab4f8; }" in (
        FavoritesWidget._DARK_STYLE
    )


def test_real_shortcut_keeps_dark_style_across_theme_changes(
    tmp_path, qt_app
) -> None:
    """Dark styling reaches actual buttons and survives a native-theme round trip."""

    settings = QSettings(str(tmp_path / "dark.ini"), QSettings.Format.IniFormat)
    widget = FavoritesWidget(settings, lambda _url: None)

    for theme in ("dark", "system", "dark"):
        widget.set_theme(theme)
        qt_app.processEvents()
        assert widget._shortcut_theme == theme
        assert widget.styleSheet() == (
            FavoritesWidget._DARK_STYLE if theme == "dark" else ""
        )

    button = widget.findChildren(QPushButton)[0]
    assert button.palette().button().color().name() == "#2d3034"
    assert button.palette().buttonText().color().name() == "#f1f3f4"
    assert not button.font().underline()
    assert button.style().metaObject().className() == "QStyleSheetStyle"

    widget.deleteLater()
    qt_app.processEvents()


def test_native_ui_sources_do_not_set_fixed_font_pixel_sizes() -> None:
    """Native controls should inherit fonts rather than override pixel sizes."""

    ui_dir = Path(__file__).parents[1] / "src" / "grayhaired_desktop" / "ui"
    audited_sources = (
        "favorites.py",
        "preferences.py",
        "favorite_dialog.py",
        "tooltips.py",
        "menus.py",
    )

    for source_name in audited_sources:
        source = (ui_dir / source_name).read_text(encoding="utf-8")
        assert "font-size:" not in source
        assert ".setPixelSize(" not in source
