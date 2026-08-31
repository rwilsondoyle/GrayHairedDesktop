#!/usr/bin/env python3
"""Friendly settings window for GrayHaired Live Desktop background mode."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

try:
    from PySide6.QtCore import Qt
    from PySide6.QtGui import QColor
    from PySide6.QtWidgets import (
        QApplication,
        QComboBox,
        QDialog,
        QDialogButtonBox,
        QFrame,
        QHBoxLayout,
        QLabel,
        QLineEdit,
        QMessageBox,
        QPushButton,
        QRadioButton,
        QVBoxLayout,
    )
except ImportError as exc:  # pragma: no cover - user-facing runtime guard
    raise SystemExit(
        "PySide6 is required for the Live Desktop Background settings window."
    ) from exc

CONFIG_FILE = Path.home() / ".config" / "grayhaired-live-desktop" / "background.json"
REPO_DIR = Path.home() / "GrayHairedDesktop"
SETTER = REPO_DIR / "scripts" / "set-live-desktop-background.sh"
RELOADER = REPO_DIR / "scripts" / "reload-grayhaired.sh"
HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")

PRESETS = (
    ("Gunmetal Gray", "#41464C", "gunmetal"),
    ("Charcoal", "#303030", "charcoal"),
    ("Slate Gray", "#4A5568", "slate"),
    ("Dark Blue", "#243447", "navy"),
    ("Black", "#000000", "black"),
    ("Custom Color", None, None),
)


def load_config() -> tuple[str, str]:
    try:
        payload = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError, TypeError):
        return "automatic", "#41464C"

    mode = str(payload.get("mode", "automatic")).lower()
    color = str(payload.get("color", "#41464C")).upper()
    if mode not in {"automatic", "manual"}:
        mode = "automatic"
    if not HEX_RE.fullmatch(color):
        color = "#41464C"
    return mode, color


class BackgroundSettingsDialog(QDialog):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("My Desktop Background")
        self.setMinimumWidth(500)

        mode, color = load_config()
        self._saved_mode = mode
        self._saved_color = color

        title = QLabel("Desktop Background", self)
        font = title.font()
        font.setPointSize(font.pointSize() + 3)
        font.setBold(True)
        title.setFont(font)

        help_text = QLabel(
            "Automatic Blend matches the website. Manual Background uses the color "
            "you choose for the real desktop-icon area and the GNOME backing color.",
            self,
        )
        help_text.setWordWrap(True)

        self.automatic = QRadioButton("Automatic Blend (recommended)", self)
        self.manual = QRadioButton("Manual Background", self)
        self.automatic.setChecked(mode == "automatic")
        self.manual.setChecked(mode == "manual")

        self.preset = QComboBox(self)
        for label, hex_color, setter_value in PRESETS:
            self.preset.addItem(label, (hex_color, setter_value))

        self.custom = QLineEdit(color, self)
        self.custom.setPlaceholderText("Example: #41464C")
        self.custom.setMaxLength(7)

        self.preview = QFrame(self)
        self.preview.setFixedHeight(86)
        self.preview.setFrameShape(QFrame.Shape.StyledPanel)
        self.preview_label = QLabel(self.preview)
        self.preview_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.preview_label.setStyleSheet("font-weight: 700; font-size: 16px;")

        self.status = QLabel("", self)
        self.status.setWordWrap(True)

        self.apply_button = QPushButton("Apply Now", self)
        self.apply_button.setMinimumHeight(40)
        close_buttons = QDialogButtonBox(QDialogButtonBox.StandardButton.Close, self)
        close_buttons.rejected.connect(self.reject)

        mode_layout = QVBoxLayout()
        mode_layout.addWidget(self.automatic)
        mode_layout.addWidget(self.manual)

        preset_row = QHBoxLayout()
        preset_row.addWidget(QLabel("Color choice:", self))
        preset_row.addWidget(self.preset, 1)

        custom_row = QHBoxLayout()
        custom_row.addWidget(QLabel("Custom hex color:", self))
        custom_row.addWidget(self.custom, 1)

        layout = QVBoxLayout(self)
        layout.setSpacing(12)
        layout.addWidget(title)
        layout.addWidget(help_text)
        layout.addLayout(mode_layout)
        layout.addLayout(preset_row)
        layout.addLayout(custom_row)
        layout.addWidget(QLabel("Preview:", self))
        layout.addWidget(self.preview)
        layout.addWidget(self.status)
        layout.addWidget(self.apply_button)
        layout.addWidget(close_buttons)

        self.automatic.toggled.connect(self._update_controls)
        self.manual.toggled.connect(self._update_controls)
        self.preset.currentIndexChanged.connect(self._preset_changed)
        self.custom.textChanged.connect(self._update_preview)
        self.apply_button.clicked.connect(self._apply)

        self._select_initial_preset(color)
        self._update_controls()
        self._update_preview()

    def _select_initial_preset(self, color: str) -> None:
        for index, (_label, hex_color, _setter) in enumerate(PRESETS):
            if hex_color and hex_color.upper() == color.upper():
                self.preset.setCurrentIndex(index)
                return
        self.preset.setCurrentIndex(len(PRESETS) - 1)

    def _preset_changed(self) -> None:
        data = self.preset.currentData()
        hex_color = data[0] if data else None
        if hex_color:
            self.custom.setText(hex_color)
        self._update_controls()
        self._update_preview()

    def _update_controls(self) -> None:
        manual = self.manual.isChecked()
        self.preset.setEnabled(manual)
        custom_selected = self.preset.currentIndex() == len(PRESETS) - 1
        self.custom.setEnabled(manual and custom_selected)
        self.preview.setEnabled(manual)
        self.apply_button.setText(
            "Apply Automatic Blend" if self.automatic.isChecked() else "Apply Background"
        )

    def _current_color(self) -> str | None:
        text = self.custom.text().strip().upper()
        if HEX_RE.fullmatch(text):
            return text
        return None

    def _update_preview(self) -> None:
        if self.automatic.isChecked():
            self.preview.setStyleSheet(
                "QFrame { background: palette(window); border: 2px dashed palette(mid); "
                "border-radius: 8px; }"
            )
            self.preview_label.setText("Automatic Blend")
            self.preview_label.setStyleSheet("font-weight: 700; font-size: 16px;")
            return

        color = self._current_color()
        if color is None:
            self.preview.setStyleSheet(
                "QFrame { background: palette(window); border: 2px solid #b00020; "
                "border-radius: 8px; }"
            )
            self.preview_label.setText("Enter a color like #41464C")
            return

        qcolor = QColor(color)
        text_color = "#FFFFFF" if qcolor.lightness() < 145 else "#111111"
        self.preview.setStyleSheet(
            f"QFrame {{ background-color: {color}; border: 2px solid palette(mid); "
            "border-radius: 8px; }"
        )
        self.preview_label.setText(color)
        self.preview_label.setStyleSheet(
            f"font-weight: 700; font-size: 16px; color: {text_color};"
        )

    def _apply(self) -> None:
        if not SETTER.is_file() or not RELOADER.is_file():
            QMessageBox.critical(
                self,
                "My Desktop Background",
                "The GrayHairedDesktop helper scripts could not be found.",
            )
            return

        if self.automatic.isChecked():
            value = "automatic"
        else:
            color = self._current_color()
            if color is None:
                QMessageBox.warning(
                    self,
                    "Invalid Color",
                    "Enter a six-digit hex color such as #41464C.",
                )
                return
            data = self.preset.currentData()
            preset_hex, setter_value = data if data else (None, None)
            value = setter_value if preset_hex and color == preset_hex.upper() else color

        self.apply_button.setEnabled(False)
        self.status.setText("Applying background…")
        QApplication.processEvents()

        try:
            subprocess.run(["bash", str(SETTER), value], check=True)
            subprocess.run(["bash", str(RELOADER)], check=True)
        except subprocess.CalledProcessError as exc:
            self.status.setText("The background could not be applied.")
            QMessageBox.critical(
                self,
                "My Desktop Background",
                f"The background change failed (exit code {exc.returncode}).",
            )
        else:
            mode = "Automatic Blend" if value == "automatic" else "Manual Background"
            self.status.setText(f"Applied: {mode}")
            self._saved_mode, self._saved_color = load_config()
        finally:
            self.apply_button.setEnabled(True)


def main() -> int:
    app = QApplication(sys.argv)
    dialog = BackgroundSettingsDialog()
    dialog.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
