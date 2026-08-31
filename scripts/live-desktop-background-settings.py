#!/usr/bin/env python3
"""Friendly GTK settings window for GrayHaired Live Desktop background mode."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import gi
    gi.require_version("Gtk", "3.0")
    from gi.repository import Gdk, Gtk
except (ImportError, ValueError) as exc:
    raise SystemExit(
        "GTK 3 Python bindings are required for the Live Desktop Background settings window."
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


class BackgroundSettingsWindow(Gtk.Window):
    def __init__(self) -> None:
        super().__init__(title="My Desktop Background")
        self.set_default_size(520, 460)
        self.set_border_width(18)
        self.connect("destroy", Gtk.main_quit)

        mode, color = load_config()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        self.add(outer)

        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Desktop Background</span>")
        title.set_xalign(0)
        outer.pack_start(title, False, False, 0)

        help_text = Gtk.Label(
            label=(
                "Automatic Blend matches the website. Manual Background uses the color "
                "you choose for the desktop-icon area and the GNOME backing color."
            )
        )
        help_text.set_line_wrap(True)
        help_text.set_xalign(0)
        outer.pack_start(help_text, False, False, 0)

        self.automatic = Gtk.RadioButton.new_with_label_from_widget(
            None, "Automatic Blend (recommended)"
        )
        self.manual = Gtk.RadioButton.new_with_label_from_widget(
            self.automatic, "Manual Background"
        )
        self.automatic.set_active(mode == "automatic")
        self.manual.set_active(mode == "manual")
        outer.pack_start(self.automatic, False, False, 0)
        outer.pack_start(self.manual, False, False, 0)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.pack_start(Gtk.Label(label="Color choice:"), False, False, 0)
        self.preset = Gtk.ComboBoxText()
        for label, _hex_color, _setter in PRESETS:
            self.preset.append_text(label)
        row.pack_start(self.preset, True, True, 0)
        outer.pack_start(row, False, False, 0)

        custom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        custom_row.pack_start(Gtk.Label(label="Custom hex color:"), False, False, 0)
        self.custom = Gtk.Entry()
        self.custom.set_text(color)
        self.custom.set_placeholder_text("Example: #41464C")
        self.custom.set_max_length(7)
        custom_row.pack_start(self.custom, True, True, 0)
        outer.pack_start(custom_row, False, False, 0)

        preview_label = Gtk.Label(label="Preview:")
        preview_label.set_xalign(0)
        outer.pack_start(preview_label, False, False, 0)

        self.preview = Gtk.EventBox()
        self.preview.set_size_request(-1, 86)
        self.preview_text = Gtk.Label()
        self.preview.add(self.preview_text)
        outer.pack_start(self.preview, False, False, 0)

        self.status = Gtk.Label()
        self.status.set_xalign(0)
        outer.pack_start(self.status, False, False, 0)

        self.apply_button = Gtk.Button(label="Apply Now")
        self.apply_button.set_size_request(-1, 42)
        outer.pack_start(self.apply_button, False, False, 0)

        close_button = Gtk.Button(label="Close")
        close_button.connect("clicked", lambda *_: self.destroy())
        outer.pack_start(close_button, False, False, 0)

        self.automatic.connect("toggled", self._update_controls)
        self.manual.connect("toggled", self._update_controls)
        self.preset.connect("changed", self._preset_changed)
        self.custom.connect("changed", self._update_preview)
        self.apply_button.connect("clicked", self._apply)

        self._select_initial_preset(color)
        self._update_controls()
        self.show_all()

    def _select_initial_preset(self, color: str) -> None:
        for index, (_label, hex_color, _setter) in enumerate(PRESETS):
            if hex_color and hex_color.upper() == color.upper():
                self.preset.set_active(index)
                return
        self.preset.set_active(len(PRESETS) - 1)

    def _preset_changed(self, *_args) -> None:
        index = self.preset.get_active()
        if 0 <= index < len(PRESETS):
            _label, hex_color, _setter = PRESETS[index]
            if hex_color:
                self.custom.set_text(hex_color)
        self._update_controls()

    def _update_controls(self, *_args) -> None:
        manual = self.manual.get_active()
        self.preset.set_sensitive(manual)
        custom_selected = self.preset.get_active() == len(PRESETS) - 1
        self.custom.set_sensitive(manual and custom_selected)
        self.apply_button.set_label(
            "Apply Background" if manual else "Apply Automatic Blend"
        )
        self._update_preview()

    def _current_color(self) -> str | None:
        value = self.custom.get_text().strip().upper()
        return value if HEX_RE.fullmatch(value) else None

    def _set_preview_css(self, background: str, foreground: str, border: str) -> None:
        provider = Gtk.CssProvider()
        provider.load_from_data(
            (
                "eventbox {"
                f"background-color: {background};"
                f"border: 2px solid {border};"
                "border-radius: 8px;"
                "}"
                f"label {{ color: {foreground}; font-weight: bold; font-size: 16px; }}"
            ).encode("utf-8")
        )
        self.preview.get_style_context().add_provider(
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self.preview_text.get_style_context().add_provider(
            provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self._preview_provider = provider

    def _update_preview(self, *_args) -> None:
        if self.automatic.get_active():
            self.preview_text.set_text("Automatic Blend\nWebsite colors will be used")
            self._set_preview_css("#F2F2F2", "#222222", "#888888")
            return

        color = self._current_color()
        if color is None:
            self.preview_text.set_text("Enter a color like #41464C")
            self._set_preview_css("#F2F2F2", "#222222", "#B00020")
            return

        rgba = Gdk.RGBA()
        rgba.parse(color)
        lightness = max(rgba.red, rgba.green, rgba.blue) + min(
            rgba.red, rgba.green, rgba.blue
        )
        foreground = "#FFFFFF" if lightness < 1.15 else "#111111"
        self.preview_text.set_text(color)
        self._set_preview_css(color, foreground, "#777777")

    def _message(self, message_type, title: str, text: str) -> None:
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=message_type,
            buttons=Gtk.ButtonsType.OK,
            text=title,
        )
        dialog.format_secondary_text(text)
        dialog.run()
        dialog.destroy()

    def _apply(self, *_args) -> None:
        if not SETTER.is_file() or not RELOADER.is_file():
            self._message(
                Gtk.MessageType.ERROR,
                "My Desktop Background",
                "The GrayHairedDesktop helper scripts could not be found.",
            )
            return

        if self.automatic.get_active():
            value = "automatic"
        else:
            color = self._current_color()
            if color is None:
                self._message(
                    Gtk.MessageType.WARNING,
                    "Invalid Color",
                    "Enter a six-digit hex color such as #41464C.",
                )
                return
            index = self.preset.get_active()
            _label, preset_hex, setter_value = PRESETS[index]
            value = setter_value if preset_hex and color == preset_hex.upper() else color

        self.apply_button.set_sensitive(False)
        self.status.set_text("Applying background…")
        while Gtk.events_pending():
            Gtk.main_iteration_do(False)

        try:
            subprocess.run(["bash", str(SETTER), value], check=True)
            subprocess.run(["bash", str(RELOADER)], check=True)
        except subprocess.CalledProcessError as exc:
            self.status.set_text("The background could not be applied.")
            self._message(
                Gtk.MessageType.ERROR,
                "My Desktop Background",
                f"The background change failed (exit code {exc.returncode}).",
            )
        else:
            label = "Automatic Blend" if value == "automatic" else "Manual Background"
            self.status.set_text(f"Applied: {label}")
        finally:
            self.apply_button.set_sensitive(True)


def main() -> int:
    BackgroundSettingsWindow()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
