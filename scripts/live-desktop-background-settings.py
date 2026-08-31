#!/usr/bin/env python3
"""Friendly GTK 4 settings window for GrayHaired Live Desktop background mode."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

try:
    import gi

    gi.require_version("Gtk", "4.0")
    gi.require_version("Gdk", "4.0")
    from gi.repository import Gdk, Gio, GLib, Gtk
except (ImportError, ValueError) as exc:
    raise SystemExit(
        "GTK 4 Python bindings are required for the Live Desktop Background settings window."
    ) from exc

CONFIG_FILE = Path.home() / ".config" / "grayhaired-live-desktop" / "background.json"
REPO_DIR = Path.home() / "GrayHairedDesktop"
SETTER = REPO_DIR / "scripts" / "set-live-desktop-background.sh"
RELOADER = REPO_DIR / "scripts" / "reload-grayhaired.sh"
HEX_RE = re.compile(r"^#[0-9A-Fa-f]{6}$")

PRESETS = (
    ("Gray", "#808080"),
    ("White", "#FFFFFF"),
    ("Green", "#2E7D32"),
    ("Red", "#C62828"),
    ("Blue", "#3155A6"),
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


def hex_from_rgb_floats(red: float, green: float, blue: float) -> str:
    return (
        f"#{round(max(0.0, min(1.0, red)) * 255):02X}"
        f"{round(max(0.0, min(1.0, green)) * 255):02X}"
        f"{round(max(0.0, min(1.0, blue)) * 255):02X}"
    )


class BackgroundSettingsWindow(Gtk.ApplicationWindow):
    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="My Desktop Background")
        self.set_default_size(560, 585)
        self.set_resizable(False)
        self._syncing_color_controls = False
        self._chooser_dialog = None
        self._portal_bus = None
        self._portal_signal_id = None

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
        row.append(Gtk.Label(label="Quick color:"))
        self.preset = Gtk.ComboBoxText()
        self.preset.set_hexpand(True)
        for label, _hex_color in PRESETS:
            self.preset.append_text(label)
        row.append(self.preset)
        outer.append(row)

        custom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        custom_row.append(Gtk.Label(label="Chosen color:"))
        self.custom = Gtk.Entry()
        self.custom.set_hexpand(True)
        self.custom.set_text(color)
        self.custom.set_placeholder_text("Example: #41464C")
        self.custom.set_max_length(7)
        custom_row.append(self.custom)

        self.choose_color_button = Gtk.Button(label="Choose Color…")
        self.choose_color_button.set_tooltip_text(
            "Open the full color chooser and select a color manually."
        )
        custom_row.append(self.choose_color_button)
        outer.append(custom_row)

        self.pick_screen_button = Gtk.Button(label="Pick Color From Screen…")
        self.pick_screen_button.set_size_request(-1, 40)
        self.pick_screen_button.set_tooltip_text(
            "Hide this window, then click a color anywhere on the desktop or website."
        )
        outer.append(self.pick_screen_button)

        picker_help = Gtk.Label(
            label=(
                "To match your website, click Pick Color From Screen…, then click the exact "
                "color you want on the live desktop. The sampled color will appear below."
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
        self.choose_color_button.connect("clicked", self._open_color_chooser)
        self.pick_screen_button.connect("clicked", self._pick_color_from_screen)
        self.apply_button.connect("clicked", self._apply)

        self._select_initial_preset(color)
        self._update_controls()

    def _select_initial_preset(self, color: str) -> None:
        for index, (_label, hex_color) in enumerate(PRESETS):
            if hex_color.upper() == color.upper():
                self.preset.set_active(index)
                return
        self.preset.set_active(0)

    def _set_color(self, color: str) -> None:
        self._syncing_color_controls = True
        try:
            self.custom.set_text(color.upper())
        finally:
            self._syncing_color_controls = False
        self._update_preview()

    def _preset_changed(self, *_args) -> None:
        index = self.preset.get_active()
        if 0 <= index < len(PRESETS):
            _label, hex_color = PRESETS[index]
            self._set_color(hex_color)
        self._update_preview()

    def _custom_changed(self, *_args) -> None:
        if self._syncing_color_controls:
            return
        self._update_preview()

    def _open_color_chooser(self, *_args) -> None:
        if not self.manual.get_active():
            self.manual.set_active(True)

        current = self._current_color() or "#41464C"

        if hasattr(Gtk, "ColorChooserDialog"):
            dialog = Gtk.ColorChooserDialog(title="Choose Color", transient_for=self)
            dialog.set_modal(True)
            dialog.set_rgba(rgba_from_hex(current))
            dialog.connect("response", self._color_chooser_response)
            self._chooser_dialog = dialog
            dialog.present()
            return

        hidden_picker = Gtk.ColorButton()
        hidden_picker.set_rgba(rgba_from_hex(current))
        hidden_picker.connect("color-set", self._fallback_picker_changed)
        self._fallback_picker = hidden_picker
        hidden_picker.activate()

    def _color_chooser_response(self, dialog, response_id) -> None:
        try:
            if response_id in {Gtk.ResponseType.OK, Gtk.ResponseType.ACCEPT}:
                self._set_color(hex_from_rgba(dialog.get_rgba()))
        finally:
            dialog.close()
            if self._chooser_dialog is dialog:
                self._chooser_dialog = None

    def _fallback_picker_changed(self, picker) -> None:
        self._set_color(hex_from_rgba(picker.get_rgba()))
        self._fallback_picker = None

    def _pick_color_from_screen(self, *_args) -> None:
        if not self.manual.get_active():
            self.manual.set_active(True)

        self.pick_screen_button.set_sensitive(False)
        self.status.set_text("Click the color you want anywhere on the desktop or website…")

        # Hide the settings window so it cannot cover the color the user wants.
        self.set_visible(False)
        GLib.timeout_add(150, self._start_portal_color_pick)

    def _start_portal_color_pick(self) -> bool:
        try:
            bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
            token = f"grayhaired_{os.getpid()}_{int(time.time() * 1000)}"
            options = {"handle_token": GLib.Variant("s", token)}
            result = bus.call_sync(
                "org.freedesktop.portal.Desktop",
                "/org/freedesktop/portal/desktop",
                "org.freedesktop.portal.Screenshot",
                "PickColor",
                GLib.Variant("(sa{sv})", ("", options)),
                GLib.VariantType.new("(o)"),
                Gio.DBusCallFlags.NONE,
                -1,
                None,
            )
            request_path = result.unpack()[0]
            self._portal_bus = bus
            self._portal_signal_id = bus.signal_subscribe(
                "org.freedesktop.portal.Desktop",
                "org.freedesktop.portal.Request",
                "Response",
                request_path,
                None,
                Gio.DBusSignalFlags.NONE,
                self._portal_color_response,
            )
        except Exception as exc:  # D-Bus/portal availability varies by desktop.
            self.present()
            self.pick_screen_button.set_sensitive(True)
            self._show_error(f"Screen color picker could not start: {exc}")
        return GLib.SOURCE_REMOVE

    def _portal_color_response(
        self,
        _connection,
        _sender_name,
        _object_path,
        _interface_name,
        _signal_name,
        parameters,
    ) -> None:
        try:
            response, results = parameters.unpack()
            if response != 0:
                self.status.set_text("Color picking was canceled.")
                return

            color_value = results.get("color")
            if hasattr(color_value, "unpack"):
                color_value = color_value.unpack()
            if not color_value or len(color_value) != 3:
                raise ValueError("portal returned no color value")

            red, green, blue = (float(component) for component in color_value)
            picked = hex_from_rgb_floats(red, green, blue)
            self._set_color(picked)
            self.status.set_text(f"Picked from screen: {picked}")
        except Exception as exc:
            self._show_error(f"Could not read the picked color: {exc}")
        finally:
            if self._portal_bus is not None and self._portal_signal_id is not None:
                self._portal_bus.signal_unsubscribe(self._portal_signal_id)
            self._portal_signal_id = None
            self._portal_bus = None
            self.pick_screen_button.set_sensitive(True)
            self.present()

    def _update_controls(self, *_args) -> None:
        manual = self.manual.get_active()
        self.preset.set_sensitive(manual)
        self.custom.set_sensitive(manual)
        self.choose_color_button.set_sensitive(manual)
        self.pick_screen_button.set_sensitive(manual and self._portal_signal_id is None)
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
            value = color

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
