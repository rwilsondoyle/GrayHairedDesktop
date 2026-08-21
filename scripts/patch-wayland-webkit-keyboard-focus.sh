#!/usr/bin/env bash
set -euo pipefail

TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.before-webkit-keyboard-focus"

if [[ ! -f "$GRID" ]]; then
    echo "GrayHaired Wayland prototype desktopGrid.js not found:"
    echo "  $GRID"
    exit 2
fi

python3 - "$GRID" "$BACKUP" <<'PY'
from pathlib import Path
import shutil
import sys

path = Path(sys.argv[1])
backup = Path(sys.argv[2])
text = path.read_text(encoding="utf-8")
changed = False

if not backup.exists():
    shutil.copy2(path, backup)

keyboard_marker = "The WebKit live-desktop surface and DING icon strip share this"
if keyboard_marker not in text:
    old = """        this.connectSignal(this._window, 'key-press-event', (actor, event) => {
            this._desktopManager.onKeyPress(event, this);
        });
        // key-release-event must be used for the arrow keys to avoid conflicts
        // with assistive technologies.
        this.connectSignal(this._window, 'key-release-event', (actor, event) => {
            this._desktopManager.onKeyRelease(event, this);
        });"""

    new = """        // GrayHairedDesktop:
        // The WebKit live-desktop surface and DING icon strip share this
        // top-level window. Keyboard events from WebKit can therefore bubble
        // up to the window. Do not let DING process those keys while WebKit
        // owns the keyboard focus.
        this.connectSignal(this._window, 'key-press-event', (actor, event) => {
            if (this._liveWebView && this._liveWebView.has_focus) {
                return false;
            }

            this._desktopManager.onKeyPress(event, this);
            return false;
        });

        // key-release-event must be used for the arrow keys to avoid conflicts
        // with assistive technologies.
        this.connectSignal(this._window, 'key-release-event', (actor, event) => {
            if (this._liveWebView && this._liveWebView.has_focus) {
                return false;
            }

            this._desktopManager.onKeyRelease(event, this);
            return false;
        });"""

    if old not in text:
        raise SystemExit("Expected DING keyboard-event block not found; no changes made.")

    text = text.replace(old, new, 1)
    changed = True

focus_marker = "Reclaim keyboard focus for DING when the icon strip is clicked"
if focus_marker not in text:
    old_press = """        this.connectSignal(this._eventBox, 'button-press-event', (actor, event) => {
            let [a, x, y] = event.get_coords();
            [x, y] = this.coordinatesLocalToGlobal(x, y);
            this._desktopManager.onPressButton(x, y, event, this);
            return false;
        });"""

    new_press = """        this.connectSignal(this._eventBox, 'button-press-event', (actor, event) => {
            // GrayHairedDesktop: Reclaim keyboard focus for DING when the icon
            // strip is clicked. WebKit legitimately owns focus while typing in
            // the live page, but clicking back on the real desktop must restore
            // DING keyboard navigation (Escape, arrows, type-to-search, etc.).
            this._eventBox.set_can_focus(true);
            this._eventBox.grab_focus();

            let [a, x, y] = event.get_coords();
            [x, y] = this.coordinatesLocalToGlobal(x, y);
            this._desktopManager.onPressButton(x, y, event, this);
            return false;
        });"""

    if old_press not in text:
        raise SystemExit("Expected DING button-press block not found; no changes made.")

    text = text.replace(old_press, new_press, 1)
    changed = True

if changed:
    path.write_text(text, encoding="utf-8")
    print("Applied WebKit/DING keyboard focus handoff to GrayHaired desktopGrid.js.")
else:
    print("WebKit/DING keyboard focus handoff is already present.")
PY

cat <<EOF

=== WEBKIT / DING KEYBOARD FOCUS PATCH READY ===

Patched only the GrayHaired user-local DING/WebKit child code:
  $GRID

Do NOT disable/re-enable the GNOME extension for this app-code change.
Reload only the child process with:
  bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
EOF
