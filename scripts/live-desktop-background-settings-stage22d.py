#!/usr/bin/env python3
"""Stage 22D wrapper that preserves non-preset manual background colors."""

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
