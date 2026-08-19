#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$SYSTEM_UUID"
USER_ROOT="$HOME/.local/share/gnome-shell/extensions"
TEST_EXT="$USER_ROOT/$TEST_UUID"
GRID="$TEST_EXT/app/desktopGrid.js"
META="$TEST_EXT/metadata.json"

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    echo "This prototype installer is intended for a Wayland login."
    echo "Current session: ${XDG_SESSION_TYPE:-unknown}"
    exit 2
fi

if [[ ! -d "$SYSTEM_EXT" ]]; then
    echo "System Zorin desktop-icons extension not found:"
    echo "  $SYSTEM_EXT"
    exit 2
fi

if pgrep -f '/zorin-desktop-icons@zorinos.com/app/ding.js' >/dev/null 2>&1; then
    echo "The normal Zorin DING process is still running."
    echo "Disable it first with:"
    echo "  gnome-extensions disable $SYSTEM_UUID"
    exit 2
fi

mkdir -p "$USER_ROOT"
rm -rf "$TEST_EXT"
cp -a "$SYSTEM_EXT" "$TEST_EXT"

python3 - "$META" "$TEST_UUID" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
uuid = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
data["uuid"] = uuid
data["name"] = "GrayHaired Live Desktop Wayland Prototype"
data["description"] = (
    "Research-only GrayHairedDesktop copy of Zorin Desktop Icons with a "
    "dedicated DING icon strip and live My Desktop WebKit surface."
)
path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
PY

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_imports = """'use strict';
const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
"""
new_imports = """'use strict';
imports.gi.versions.WebKit2 = '4.1';
const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const WebKit2 = imports.gi.WebKit2;
"""
if old_imports not in text:
    raise SystemExit("Expected desktopGrid.js import block not found; refusing to patch")
text = text.replace(old_imports, new_imports, 1)

old_widgets = """        this._eventBox = new Gtk.EventBox({visible: true});
        this.sizeEventBox();
        this._window.add(this._eventBox);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);
        this.gridGlobalRectangle = new Gdk.Rectangle();
        this.setDropDestination(this._eventBox);
"""
new_widgets = """        this._eventBox = new Gtk.EventBox({visible: true});
        this.sizeEventBox();

        // GrayHairedDesktop Wayland research prototype:
        // keep DING's original EventBox -> Gtk.Fixed hierarchy intact, but
        // show it only in a dedicated left-side strip. WebKit lives beside
        // DING rather than above or below it, so pointer events do not cross
        // between two overlapping full-screen widgets.
        this._eventBox.set_size_request(220, this._windowHeight);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);

        this._liveLayout = new Gtk.Box({orientation: Gtk.Orientation.HORIZONTAL});
        this._liveLayout.pack_start(this._eventBox, false, false, 0);

        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);
        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');
        this._liveLayout.pack_start(this._liveWebView, true, true, 0);

        this._window.add(this._liveLayout);
        this.gridGlobalRectangle = new Gdk.Rectangle();
        this.setDropDestination(this._eventBox);
"""
if old_widgets not in text:
    raise SystemExit("Expected DING widget block not found; refusing to patch")
text = text.replace(old_widgets, new_widgets, 1)

path.write_text(text, encoding="utf-8")
print("Patched separate-UUID desktopGrid.js for split-surface Wayland research.")
PY

cat <<EOF

=== SEPARATE WAYLAND DING PROTOTYPE INSTALLED ===

System extension remains untouched:
  $SYSTEM_EXT

Separate user extension:
  $TEST_EXT

UUID:
  $TEST_UUID

The normal Zorin desktop-icons extension must remain disabled while testing.

Next step: LOG OUT and log back into Wayland so GNOME discovers the new UUID.
Do not reboot.

After login run:
  gnome-extensions list | grep -E 'grayhaired-live-desktop|zorin-desktop-icons'

Then enable the prototype with:
  gnome-extensions enable $TEST_UUID

Recovery/removal:
  bash ~/GrayHairedDesktop/scripts/remove-wayland-separate-ding-prototype.sh
EOF
