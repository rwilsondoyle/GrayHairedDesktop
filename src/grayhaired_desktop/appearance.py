"""Linux system-appearance detection and Qt palette compatibility fallback."""

from __future__ import annotations

import subprocess
from enum import StrEnum

from PySide6.QtGui import QColor, QPalette
from PySide6.QtWidgets import QApplication, QStyleFactory


class SystemAppearance(StrEnum):
    """Appearance values reported by the GNOME desktop setting."""

    LIGHT = "light"
    DARK = "dark"
    UNKNOWN = "unknown"


def detect_system_appearance() -> SystemAppearance:
    """Read GNOME/Zorin's color-scheme preference once at application startup."""

    try:
        result = subprocess.run(
            [
                "gsettings",
                "get",
                "org.gnome.desktop.interface",
                "color-scheme",
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError):
        return SystemAppearance.UNKNOWN

    value = result.stdout.strip().strip("'").casefold()
    if value == "prefer-dark":
        return SystemAppearance.DARK
    if value in {"default", "prefer-light"}:
        return SystemAppearance.LIGHT
    return SystemAppearance.UNKNOWN


def palette_appearance(palette: QPalette) -> SystemAppearance:
    """Classify a Qt palette using its primary window foreground/background."""

    window = palette.color(QPalette.ColorRole.Window)
    text = palette.color(QPalette.ColorRole.WindowText)
    return (
        SystemAppearance.DARK
        if window.lightness() < text.lightness()
        else SystemAppearance.LIGHT
    )


def _fusion_dark_palette() -> QPalette:
    """Return the conventional neutral Fusion dark palette."""

    palette = QPalette()
    window = QColor(53, 53, 53)
    text = QColor(240, 240, 240)
    base = QColor(35, 35, 35)
    highlight = QColor(42, 130, 218)

    palette.setColor(QPalette.ColorRole.Window, window)
    palette.setColor(QPalette.ColorRole.WindowText, text)
    palette.setColor(QPalette.ColorRole.Base, base)
    palette.setColor(QPalette.ColorRole.AlternateBase, window)
    palette.setColor(QPalette.ColorRole.ToolTipBase, base)
    palette.setColor(QPalette.ColorRole.ToolTipText, text)
    palette.setColor(QPalette.ColorRole.Text, text)
    palette.setColor(QPalette.ColorRole.Button, window)
    palette.setColor(QPalette.ColorRole.ButtonText, text)
    palette.setColor(QPalette.ColorRole.BrightText, QColor(255, 255, 255))
    palette.setColor(QPalette.ColorRole.Highlight, highlight)
    palette.setColor(QPalette.ColorRole.HighlightedText, QColor(255, 255, 255))
    palette.setColor(QPalette.ColorRole.PlaceholderText, QColor(170, 170, 170))

    disabled_text = QColor(168, 168, 168)
    disabled_base = QColor(43, 43, 43)
    disabled_button = QColor(69, 69, 69)
    disabled_placeholder = QColor(133, 133, 133)
    disabled = QPalette.ColorGroup.Disabled
    palette.setColor(disabled, QPalette.ColorRole.WindowText, disabled_text)
    palette.setColor(disabled, QPalette.ColorRole.Text, disabled_text)
    palette.setColor(disabled, QPalette.ColorRole.ButtonText, disabled_text)
    palette.setColor(disabled, QPalette.ColorRole.PlaceholderText, disabled_placeholder)
    palette.setColor(disabled, QPalette.ColorRole.Base, disabled_base)
    palette.setColor(disabled, QPalette.ColorRole.Button, disabled_button)
    return palette


def apply_system_appearance(
    app: QApplication, appearance: SystemAppearance
) -> bool:
    """Correct a mismatched Qt palette; return whether a fallback was applied."""

    if appearance is SystemAppearance.UNKNOWN:
        return False
    if palette_appearance(app.palette()) is appearance:
        return False

    if appearance is SystemAppearance.DARK:
        app.setPalette(_fusion_dark_palette())
    else:
        fusion = QStyleFactory.create("Fusion")
        if fusion is None:  # pragma: no cover - Fusion ships with supported Qt
            return False
        app.setPalette(fusion.standardPalette())
    return True
