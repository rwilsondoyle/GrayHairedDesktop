#!/usr/bin/env python3
"""Friendly GTK 4 website selector for GrayHaired Live Desktop."""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

try:
    import gi
    gi.require_version("Gtk", "4.0")
    from gi.repository import Gtk
except (ImportError, ValueError) as exc:
    raise SystemExit("GTK 4 Python bindings are required for My Desktop Website.") from exc

CONFIG_FILE = Path.home() / ".config" / "grayhaired-live-desktop" / "site.json"
REPO_DIR = Path.home() / "GrayHairedDesktop"
SETTER = REPO_DIR / "scripts" / "set-live-desktop-website.sh"
RELOADER = REPO_DIR / "scripts" / "reload-grayhaired.sh"

PRESETS = (
    ("GrayHaired Desktop D", "desktop-d", "https://grayhaired.tech/desktop-d"),
    ("GrayHaired Desktop C", "desktop-c", "https://grayhaired.tech/desktop-c"),
    ("MSN", "msn", "https://www.msn.com/"),
    ("DuckDuckGo", "duckduckgo", "https://duckduckgo.com/"),
    ("Custom Website", "custom", ""),
)


def load_current_url() -> str:
    try:
        payload = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        url = str(payload.get("url", "")).strip()
        if url.startswith(("http://", "https://")):
            return url
    except (OSError, ValueError, TypeError):
        pass
    return "https://grayhaired.tech/desktop-d"


class WebsiteSettingsWindow(Gtk.ApplicationWindow):
    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="My Desktop Website")
        self.set_default_size(560, 330)
        self.set_resizable(False)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        outer.set_margin_top(18)
        outer.set_margin_bottom(18)
        outer.set_margin_start(18)
        outer.set_margin_end(18)
        self.set_child(outer)

        title = Gtk.Label()
        title.set_markup("<span size='x-large' weight='bold'>Desktop Website</span>")
        title.set_xalign(0)
        outer.append(title)

        help_text = Gtk.Label(
            label=(
                "Choose what appears on the live desktop. The choice is saved and "
                "will be used the next time My Desktop starts."
            )
        )
        help_text.set_wrap(True)
        help_text.set_xalign(0)
        outer.append(help_text)

        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.append(Gtk.Label(label="Website:"))
        self.preset = Gtk.ComboBoxText()
        self.preset.set_hexpand(True)
        for label, _key, _url in PRESETS:
            self.preset.append_text(label)
        row.append(self.preset)
        outer.append(row)

        custom_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        custom_row.append(Gtk.Label(label="Address:"))
        self.custom = Gtk.Entry()
        self.custom.set_hexpand(True)
        self.custom.set_placeholder_text("https://example.com/")
        custom_row.append(self.custom)
        outer.append(custom_row)

        note = Gtk.Label(
            label="Custom addresses must begin with http:// or https://."
        )
        note.set_xalign(0)
        outer.append(note)

        self.status = Gtk.Label()
        self.status.set_xalign(0)
        self.status.set_wrap(True)
        outer.append(self.status)

        self.apply_button = Gtk.Button(label="Apply Website")
        self.apply_button.set_size_request(-1, 42)
        outer.append(self.apply_button)

        close_button = Gtk.Button(label="Close")
        close_button.connect("clicked", lambda *_: self.close())
        outer.append(close_button)

        self.preset.connect("changed", self._preset_changed)
        self.apply_button.connect("clicked", self._apply)

        self._select_initial(load_current_url())

    def _select_initial(self, url: str) -> None:
        for index, (_label, _key, preset_url) in enumerate(PRESETS[:-1]):
            if preset_url.rstrip("/") == url.rstrip("/"):
                self.preset.set_active(index)
                self.custom.set_text(preset_url)
                return
        self.preset.set_active(len(PRESETS) - 1)
        self.custom.set_text(url)

    def _preset_changed(self, *_args) -> None:
        index = self.preset.get_active()
        if not (0 <= index < len(PRESETS)):
            return
        _label, key, url = PRESETS[index]
        is_custom = key == "custom"
        self.custom.set_sensitive(is_custom)
        if not is_custom:
            self.custom.set_text(url)

    def _show_error(self, text: str) -> None:
        self.status.set_markup(f"<span foreground='#C01C28'><b>{text}</b></span>")

    def _apply(self, *_args) -> None:
        if not SETTER.is_file() or not RELOADER.is_file():
            self._show_error("The GrayHairedDesktop helper scripts could not be found.")
            return

        index = self.preset.get_active()
        if not (0 <= index < len(PRESETS)):
            self._show_error("Choose a website first.")
            return

        label, key, _url = PRESETS[index]
        value = self.custom.get_text().strip() if key == "custom" else key
        if key == "custom" and not value.startswith(("http://", "https://")):
            self._show_error("Enter a complete address beginning with http:// or https://.")
            return

        self.apply_button.set_sensitive(False)
        self.status.set_text("Changing desktop website…")
        try:
            subprocess.run(["bash", str(SETTER), value], check=True)
            subprocess.run(["bash", str(RELOADER)], check=True)
        except subprocess.CalledProcessError as exc:
            self._show_error(f"Website change failed (exit code {exc.returncode}).")
        else:
            self.status.set_text(f"Applied: {label}")
        finally:
            self.apply_button.set_sensitive(True)


class WebsiteSettingsApp(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="tech.grayhaired.LiveDesktopWebsiteSettings")

    def do_activate(self) -> None:
        window = self.props.active_window
        if window is None:
            window = WebsiteSettingsWindow(self)
        window.present()


def main() -> int:
    return WebsiteSettingsApp().run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
