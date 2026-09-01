#!/usr/bin/env python3
"""Unified GTK 4 settings hub for GrayHaired Live Desktop."""

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
    raise SystemExit("GTK 4 Python bindings are required for My Desktop Settings.") from exc

REPO_DIR = Path.home() / "GrayHairedDesktop"
WEBSITE_LAUNCHER = REPO_DIR / "scripts" / "open-live-desktop-website-settings.sh"
BACKGROUND_LAUNCHER = REPO_DIR / "scripts" / "open-live-desktop-background-settings.sh"
SITE_CONFIG = Path.home() / ".config" / "grayhaired-live-desktop" / "site.json"
BACKGROUND_CONFIG = Path.home() / ".config" / "grayhaired-live-desktop" / "background.json"


def current_website() -> str:
    try:
        payload = json.loads(SITE_CONFIG.read_text(encoding="utf-8"))
        label = str(payload.get("label", "")).strip()
        url = str(payload.get("url", "")).strip()
        if label and url:
            return f"{label}\n{url}"
        if url:
            return url
    except (OSError, ValueError, TypeError):
        pass
    return "GrayHaired Desktop D\nhttps://grayhaired.tech/desktop-d"


def current_background() -> str:
    try:
        payload = json.loads(BACKGROUND_CONFIG.read_text(encoding="utf-8"))
        mode = str(payload.get("mode", "automatic")).lower()
        color = str(payload.get("color", "")).upper()
        if mode == "manual" and color:
            return f"Manual Background\n{color}"
    except (OSError, ValueError, TypeError):
        pass
    return "Automatic Blend"


class SettingsHubWindow(Gtk.ApplicationWindow):
    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="My Desktop Settings")
        self.set_default_size(620, 440)
        self.set_resizable(False)

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        outer.set_margin_top(20)
        outer.set_margin_bottom(20)
        outer.set_margin_start(20)
        outer.set_margin_end(20)
        self.set_child(outer)

        title = Gtk.Label()
        title.set_markup("<span size='xx-large' weight='bold'>My Desktop Settings</span>")
        title.set_xalign(0)
        outer.append(title)

        intro = Gtk.Label(
            label="Choose what your live desktop displays and how the desktop-icon area looks."
        )
        intro.set_wrap(True)
        intro.set_xalign(0)
        outer.append(intro)

        website_frame = Gtk.Frame(label="Website")
        website_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        website_box.set_margin_top(12)
        website_box.set_margin_bottom(12)
        website_box.set_margin_start(12)
        website_box.set_margin_end(12)
        website_frame.set_child(website_box)

        self.website_status = Gtk.Label(label=current_website())
        self.website_status.set_xalign(0)
        self.website_status.set_wrap(True)
        self.website_status.set_tooltip_text(
            "This is the website currently shown on your live desktop."
        )
        website_box.append(self.website_status)

        website_button = Gtk.Button(label="Change Desktop Website…")
        website_button.set_size_request(-1, 46)
        website_button.set_tooltip_text(
            "Choose a different website to display on your live desktop."
        )
        website_button.connect("clicked", self._open_website)
        website_box.append(website_button)
        outer.append(website_frame)

        background_frame = Gtk.Frame(label="Background")
        background_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=9)
        background_box.set_margin_top(12)
        background_box.set_margin_bottom(12)
        background_box.set_margin_start(12)
        background_box.set_margin_end(12)
        background_frame.set_child(background_box)

        self.background_status = Gtk.Label(label=current_background())
        self.background_status.set_xalign(0)
        self.background_status.set_wrap(True)
        self.background_status.set_tooltip_text(
            "This is the background setting currently used behind your desktop icons."
        )
        background_box.append(self.background_status)

        background_button = Gtk.Button(label="Change Desktop Background…")
        background_button.set_size_request(-1, 46)
        background_button.set_tooltip_text(
            "Choose Automatic Blend or pick a color for the desktop-icon area."
        )
        background_button.connect("clicked", self._open_background)
        background_box.append(background_button)
        outer.append(background_frame)

        refresh_button = Gtk.Button(label="Refresh Current Settings")
        refresh_button.set_tooltip_text(
            "Update this window after changing the website or background."
        )
        refresh_button.connect("clicked", self._refresh)
        outer.append(refresh_button)

        close_button = Gtk.Button(label="Close")
        close_button.set_tooltip_text("Close My Desktop Settings.")
        close_button.connect("clicked", lambda *_: self.close())
        outer.append(close_button)

    def _launch(self, path: Path, friendly_name: str) -> None:
        if not path.is_file():
            dialog = Gtk.MessageDialog(
                transient_for=self,
                modal=True,
                buttons=Gtk.ButtonsType.OK,
                message_type=Gtk.MessageType.ERROR,
                text=f"{friendly_name} could not be found.",
            )
            dialog.connect("response", lambda d, *_: d.close())
            dialog.present()
            return
        subprocess.Popen(["bash", str(path)])

    def _open_website(self, *_args) -> None:
        self._launch(WEBSITE_LAUNCHER, "My Desktop Website")

    def _open_background(self, *_args) -> None:
        self._launch(BACKGROUND_LAUNCHER, "My Desktop Background")

    def _refresh(self, *_args) -> None:
        self.website_status.set_text(current_website())
        self.background_status.set_text(current_background())


class SettingsHubApp(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="tech.grayhaired.LiveDesktopSettings")

    def do_activate(self) -> None:
        window = self.props.active_window
        if window is None:
            window = SettingsHubWindow(self)
        window.present()


def main() -> int:
    return SettingsHubApp().run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
