#!/usr/bin/env python3
"""Friendly GTK 4 settings window for GrayHaired Live Desktop background mode."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

try:
    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    from gi.repository import Gdk, Gtk
except (ImportError, ValueError) as exc:
    raise SystemExit(
        "GTK 4 Python bindings are required for the Live Desktop Background settings window."
    ) from exc

CONFIG_FILE = Path.home() / ".config" / "grayhaired-live-desktop" / "background.json"
REPO_DIR = Path.home() / "GrayHairedDesktop"
SETTER = REPO_DIR / "scripts" / "set-live-desktop-background.sh"
RELOADER = REPO_DIR / "scripts" / "reload-grayhaired.sh"
HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")

# Keep the quick-pick list deliberately short. Most users who want something
# beyond these basics can use Custom Color and the full GTK color chooser.
PRESETS = (
    ("Gray", "#808080", None),
    ("White", "#FFFFFF", None),
    ("Green", "#2E7D32", None),
    ("Red", "#C62828", None),
    ("Blue", "#3155A6", None),
    ("Custom Color…", None, None),
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


def rgba_from_hex(color: str) -> Gdk.RGBA:
    rgba = Gdk.RGBA()
    rgba.parse(color)
    return rgba


def hex_from_rgba(rgba: Gdk.RGBA) -> str:
    red = round(max(0.0, min(1.0, rgba.red)) * 255)
    green = round(max(0.0, min(1.0, rgba.green)) * 255)
    blue = round(max(0.0, min(1.0, rgba.blue)) * 255)
    return f"#{red:02X}{green:02X}{blue:02X}"


class BackgroundSettingsWindow(Gtk.ApplicationWindow):
    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="My Desktop Background")
        self.set_default_size(540, 560)
        self.set_resizable(False)
        self._syncing_color_controls = False

        mode, color = load_config()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        outer.set_margin_top(18)
        outer.set_margin_bottom(18)
        outer.set_margin_start(18)
        outer.set_margin_end(18)
        self.set_child(outer)

        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Desktop Background</span>")
        title.set_xalign(0)
        outer.append(title)

        help_text = Gtk.Label(
            label=(
                "Automatic Blend matches the website. Manual Background uses the color "
                "you choose for the desktop-icon area and the GNOME backing color."
            )
        )
        help_text.set_wrap(True)
        help_text.set_xalign(0)
        outer.append(help_text)

        self.automatic = Gtk.CheckButton(label="Automatic Blend (recommended)")
        self.manual = Gtk.CheckButton(label="Manual Background")
        self.manual.set_group(self.automatic)
        self.automatic.set_active(mode == "automatic")
        self.manual.set_active(mode == "manual")
        outer.append(self.automatic)
        outer.append(self.manual)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.append(Gtk.Label(label="Color choice:"))
        self.preset = Gtk.ComboBoxText()
        self.preset.set_hexpand(True)
        for label, _hex_color, _setter in PRESETS:
            self.preset.append_text(label)
        row.append(self.preset)
        outer.append(row)

        custom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        custom_row.append(Gtk.Label(label="Custom color:"))
        self.custom = Gtk.Entry()
        self.custom.set_hexpand(True)
        self.custom.set_text(color)
        self.custom.set_placeholder_text("Example: #41464C")
        self.custom.set_max_length(7)
        custom_row.append(self.custom)

        self.color_picker = Gtk.ColorButton()
        self.color_picker.set_rgba(rgba_from_hex(color))
        self.color_picker.set_tooltip_text(
            "Open the color picker and choose virtually any screen color."
        )
        custom_row.append(self.color_picker)
        outer.append(custom_row)

        picker_help = Gtk.Label(
            label=(
                "Choose Custom Color to type a hex code or click the color square "
                "to choose your own color."
            )
        )
        picker_help.set_wrap(True)
        picker_help.set_xalign(0)
        outer.append(picker_help)

        preview_label = Gtk.Label(label="Preview:")
        preview_label.set_xalign(0)
        outer.append(preview_label)

        self.preview = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.preview.set_size_request(-1, 86)
        self.preview.add_css_class("grayhaired-preview")
        self.preview.set_valign(Gtk.Align.FILL)
        self.preview_text = Gtk.Label()
        self.preview_text.set_hexpand(True)
        self.preview_text.set_vexpand(True)
        self.preview_text.set_halign(Gtk.Align.FILL)
        self.preview_text.set_valign(Gtk.Align.CENTER)
        self.preview_text.set_justify(Gtk.Justification.CENTER)
        self.preview_text.add_css_class("grayhaired-preview-text")
        self.preview.append(self.preview_text)
        outer.append(self.preview)

        self.status = Gtk.Label()
        self.status.set_xalign(0)
        self.status.set_wrap(True)
        outer.append(self.status)

        self.apply_button = Gtk.Button(label="Apply Now")
        self.apply_button.set_size_request(-1, 42)
        outer.append(self.apply_button)

        close_button = Gtk.Button(label="Close")
        close_button.connect("clicked", lambda *_: self.close())
        outer.append(close_button)

        self._preview_provider = Gtk.CssProvider()
        display = Gdk.Display.get_default()
        if display is not None:
            Gtk.StyleContext.add_provider_for_display(
                display,
                self._preview_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
            )

        self.automatic.connect("toggled", self._update_controls)
        self.manual.connect("toggled", self._update_controls)
        self.preset.connect("changed", self._preset_changed)
        self.custom.connect("changed", self._custom_changed)
        self.color_picker.connect("color-set", self._color_picker_changed)
        self.apply_button.connect("clicked", self._apply)

        self._select_initial_preset(color)
        self._update_controls()

    def _select_initial_preset(self, color: str) -> None:
        for index, (_label, hex_color, _setter) in enumerate(PRESETS):
            if hex_color and hex_color.upper() == color.upper():
                self.preset.set_active(index)
                return
        self.preset.set_active(len(PRESETS) - 1)

    def _set_color_controls(self, color: str) -> None:
        self._syncing_color_controls = True
        try:
            self.custom.set_text(color)
            self.color_picker.set_rgba(rgba_from_hex(color))
        finally:
            self._syncing_color_controls = False
        self._update_preview()

    def _preset_changed(self, *_args) -> None:
        index = self.preset.get_active()
        if 0 <= index < len(PRESETS):
            _label, hex_color, _setter = PRESETS[index]
            if hex_color:
                self._set_color_controls(hex_color)
        self._update_controls()

    def _custom_changed(self, *_args) -> None:
        if self._syncing_color_controls:
            return
        color = self._current_color()
        if color is not None:
            self._syncing_color_controls = True
            try:
                self.color_picker.set_rgba(rgba_from_hex(color))
            finally:
                self._syncing_color_controls = False
        self._update_preview()

    def _color_picker_changed(self, *_args) -> None:
        if self._syncing_color_controls:
            return
        color = hex_from_rgba(self.color_picker.get_rgba())
        self._syncing_color_controls = True
        try:
            self.custom.set_text(color)
        finally:
            self._syncing_color_controls = False
        self._update_preview()

    def _update_controls(self, *_args) -> None:
        manual = self.manual.get_active()
        self.preset.set_sensitive(manual)
        custom_selected = self.preset.get_active() == len(PRESETS) - 1
        self.custom.set_sensitive(manual and custom_selected)
        self.color_picker.set_sensitive(manual and custom_selected)
        self.apply_button.set_label(
            "Apply Background" if manual else "Apply Automatic Blend"
        )
        self._update_preview()

    def _current_color(self) -> str | None:
        value = self.custom.get_text().strip().upper()
        return value if HEX_RE.fullmatch(value) else None

    def _set_preview_css(self, background: str, foreground: str, border: str) -> None:
        css = (
            ".grayhaired-preview {"
            f"background-color: {background};"
            f"border: 2px solid {border};"
            "border-radius: 8px;"
            "}"
            ".grayhaired-preview-text {"
            f"color: {foreground};"
            "font-weight: bold;"
            "font-size: 16px;"
            "}"
        )
        self._preview_provider.load_from_data(css.encode("utf-8"))

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

        rgba = rgba_from_hex(color)
        lightness = max(rgba.red, rgba.green, rgba.blue) + min(
            rgba.red, rgba.green, rgba.blue
        )
        foreground = "#FFFFFF" if lightness < 1.15 else "#111111"
        self.preview_text.set_text(color)
        self._set_preview_css(color, foreground, "#777777")

    def _show_error(self, text: str) -> None:
        self.status.set_markup(f"<span foreground='#C01C28'><b>{text}</b></span>")

    def _apply(self, *_args) -> None:
        if not SETTER.is_file() or not RELOADER.is_file():
            self._show_error("The GrayHairedDesktop helper scripts could not be found.")
            return

        if self.automatic.get_active():
            value = "automatic"
        else:
            color = self._current_color()
            if color is None:
                self._show_error("Enter a six-digit hex color such as #41464C.")
                return
            index = self.preset.get_active()
            if not (0 <= index < len(PRESETS)):
                self._show_error("Choose a background color first.")
                return
            _label, preset_hex, setter_value = PRESETS[index]
            value = setter_value if preset_hex and color == preset_hex.upper() else color

        self.apply_button.set_sensitive(False)
        self.status.set_text("Applying background…")

        try:
            subprocess.run(["bash", str(SETTER), value], check=True)
            subprocess.run(["bash", str(RELOADER)], check=True)
        except subprocess.CalledProcessError as exc:
            self._show_error(f"Background change failed (exit code {exc.returncode}).")
        else:
            label = "Automatic Blend" if value == "automatic" else "Manual Background"
            self.status.set_text(f"Applied: {label}")
        finally:
            self.apply_button.set_sensitive(True)


class BackgroundSettingsApp(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="tech.grayhaired.LiveDesktopBackgroundSettings")

    def do_activate(self) -> None:
        window = self.props.active_window
        if window is None:
            window = BackgroundSettingsWindow(self)
        window.present()


def main() -> int:
    app = BackgroundSettingsApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
