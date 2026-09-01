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

        # Replace the decorative preview box with a real GTK Button. A real
        # button participates in GTK keyboard focus automatically and handles
        # mouse clicks, Enter, and Space consistently.
        old_preview = self.preview
        parent = old_preview.get_parent()
        previous = old_preview.get_prev_sibling()

        old_preview.remove(self.preview_text)
        parent.remove(old_preview)

        self.preview = base.Gtk.Button()
        self.preview.set_size_request(-1, 86)
        self.preview.add_css_class("grayhaired-preview")
        self.preview.set_valign(base.Gtk.Align.FILL)
        self.preview.set_hexpand(True)
        self.preview.set_focusable(True)
        self.preview.set_tooltip_text(
            "Click this preview, or focus it and press Enter or Space, to choose a color."
        )
        self.preview.set_child(self.preview_text)
        self.preview.connect("clicked", self._preview_clicked)

        parent.insert_child_after(self.preview, previous)

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
