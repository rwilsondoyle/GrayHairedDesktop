#!/usr/bin/env python3
"""Stage 22D wrapper that preserves custom colors and adds preview interaction."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

BASE_SCRIPT = Path(__file__).with_name("live-desktop-background-settings.py")

spec = importlib.util.spec_from_file_location("grayhaired_background_base", BASE_SCRIPT)
if spec is None or spec.loader is None:
    raise SystemExit("Could not load the My Desktop Background settings module.")

base = importlib.util.module_from_spec(spec)
spec.loader.exec_module(base)


class BackgroundSettingsWindow(base.BackgroundSettingsWindow):
    def __init__(self, app: base.Gtk.Application) -> None:
        super().__init__(app)

        # The large preview naturally looks interactive, so let it open the
        # same full color chooser as the Choose Color button. Keep it in the
        # keyboard focus chain as well so mouse and keyboard users get the
        # same behavior.
        self.preview.set_focusable(True)
        self.preview.set_tooltip_text(
            "Click this preview, or focus it and press Enter or Space, to choose a color."
        )

        click = base.Gtk.GestureClick()
        click.connect("released", self._preview_clicked)
        self.preview.add_controller(click)
        self._preview_click_controller = click

        keys = base.Gtk.EventControllerKey()
        keys.connect("key-pressed", self._preview_key_pressed)
        self.preview.add_controller(keys)
        self._preview_key_controller = keys

    def _select_initial_preset(self, color: str) -> None:
        """Select only an exact preset match; otherwise preserve the saved color."""
        for index, (_label, hex_color) in enumerate(base.PRESETS):
            if hex_color.upper() == color.upper():
                self.preset.set_active(index)
                return

        # No quick preset matches the saved custom color. Leaving the combo box
        # unselected prevents its "changed" handler from replacing the real
        # saved color with Gray (#808080) when the window first opens.
        self.preset.set_active(-1)

    def _preview_clicked(self, *_args) -> None:
        self._open_color_chooser()

    def _preview_key_pressed(self, _controller, keyval, _keycode, _state) -> bool:
        if keyval in {
            base.Gdk.KEY_Return,
            base.Gdk.KEY_KP_Enter,
            base.Gdk.KEY_space,
        }:
            self._open_color_chooser()
            return True
        return False


class BackgroundSettingsApp(base.Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="tech.grayhaired.LiveDesktopBackgroundSettings")

    def do_activate(self) -> None:
        window = self.props.active_window
        if window is None:
            window = BackgroundSettingsWindow(self)
        window.present()


def main() -> int:
    return BackgroundSettingsApp().run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
