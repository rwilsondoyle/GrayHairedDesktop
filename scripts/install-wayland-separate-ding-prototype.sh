#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$SYSTEM_UUID"
USER_ROOT="$HOME/.local/share/gnome-shell/extensions"
TEST_EXT="$USER_ROOT/$TEST_UUID"
GRID="$TEST_EXT/app/desktopGrid.js"
META="$TEST_EXT/metadata.json"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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

if pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' >/dev/null 2>&1; then
    echo "The GrayHaired Wayland prototype DING process is still running."
    echo "This installer replaces the user-local extension tree, so use it only for installation/reinstallation."
    echo "For normal development reloads use:"
    echo "  bash $SCRIPT_DIR/reload-grayhaired.sh"
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

old_description = """        this._desktopDescription = desktopDescription;
        this.updateWindowGeometry();
        this.updateUnscaledHeightWidthMargins();
"""
new_description = """        // GrayHairedDesktop Wayland research prototype:
        // keep the top-level desktop window at the monitor's full size, but
        // constrain DING's usable icon grid to a 220-pixel strip on the left.
        // updateWindowGeometry() uses desktopDescription.width, while the grid
        // calculations below subtract marginRight, so these can be controlled
        // independently.
        desktopDescription = Object.assign({}, desktopDescription);
        const liveIconStripWidth = 220;
        desktopDescription.marginRight = Math.max(
            desktopDescription.marginRight,
            desktopDescription.width - desktopDescription.marginLeft - liveIconStripWidth
        );
        this._desktopDescription = desktopDescription;
        this.updateWindowGeometry();
        this.updateUnscaledHeightWidthMargins();
"""
if old_description not in text:
    raise SystemExit("Expected desktop description block not found; refusing to patch")
text = text.replace(old_description, new_description, 1)

old_widgets = """        this._eventBox = new Gtk.EventBox({visible: true});
        this.sizeEventBox();
        this._window.add(this._eventBox);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);
        this.gridGlobalRectangle = new Gdk.Rectangle();
        this.setDropDestination(this._eventBox);
"""
new_widgets = """        this._eventBox = new Gtk.EventBox({visible: true});

        // Tell sizeEventBox() that the large right margin is grid geometry
        // only. If GTK also applies that margin to this widget inside the
        // horizontal split, it consumes the space intended for WebKit.
        this._liveSplitSurface = true;
        this.sizeEventBox();

        // Keep DING's original EventBox -> Gtk.Fixed hierarchy intact in the
        // left-side strip. WebKit lives beside it, so the two input systems do
        // not overlap.
        this._eventBox.set_size_request(220, -1);
        this._eventBox.set_vexpand(true);
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

old_size_event_box = """    sizeEventBox() {
        this._eventBox.margin_top = this._marginTop;
        this._eventBox.margin_bottom = this._marginBottom;
        const leftToRight =
            this._eventBox.get_direction() === Gtk.TextDirection.LTR;
        if (leftToRight) {
            this._eventBox.margin_start = this._marginLeft;
            this._eventBox.margin_end = this._marginRight;
        } else {
            this._eventBox.margin_start = this._marginRight;
            this._eventBox.margin_end = this._marginLeft;
        }
    }
"""
new_size_event_box = """    sizeEventBox() {
        this._eventBox.margin_top = this._marginTop;
        this._eventBox.margin_bottom = this._marginBottom;

        // GrayHairedDesktop split-surface prototype: marginRight is still used
        // by DING's grid calculations, but must not become a GTK widget margin
        // or it will consume WebKit's horizontal allocation.
        if (this._liveSplitSurface) {
            this._eventBox.margin_start = 0;
            this._eventBox.margin_end = 0;
            return;
        }

        const leftToRight =
            this._eventBox.get_direction() === Gtk.TextDirection.LTR;
        if (leftToRight) {
            this._eventBox.margin_start = this._marginLeft;
            this._eventBox.margin_end = this._marginRight;
        } else {
            this._eventBox.margin_start = this._marginRight;
            this._eventBox.margin_end = this._marginLeft;
        }
    }
"""
if old_size_event_box not in text:
    raise SystemExit("Expected sizeEventBox() method not found; refusing to patch")
text = text.replace(old_size_event_box, new_size_event_box, 1)

path.write_text(text, encoding="utf-8")
print("Patched separate-UUID desktopGrid.js for split allocation without GTK margin starvation.")
PY

# Build the complete known-good child-process code during installation. These
# patchers are also useful independently during development, but they no longer
# require a whole GNOME extension disable/enable cycle.
bash "$SCRIPT_DIR/patch-wayland-webkit-links.sh"
bash "$SCRIPT_DIR/patch-wayland-webkit-keyboard-focus.sh"
bash "$SCRIPT_DIR/patch-wayland-webkit-lifecycle-logging.sh"

# Reproducibility gate: verify the generated user-local tree before declaring
# installation complete. This is read-only and does not start/stop anything.
bash "$SCRIPT_DIR/verify-wayland-known-good.sh" --files-only

cat <<EOF

=== SEPARATE WAYLAND DING PROTOTYPE INSTALLED ===

System extension remains untouched:
  $SYSTEM_EXT

Separate user extension:
  $TEST_EXT

UUID:
  $TEST_UUID

The normal Zorin desktop-icons extension must remain disabled while testing.

If this UUID has already been discovered by GNOME Shell, enable it with:
  gnome-extensions enable $TEST_UUID

For a first-time installation, log out and back into Wayland before enabling it.
A reboot is NOT required.

IMPORTANT DEVELOPMENT WORKFLOW:
  Do not repeatedly disable/enable the GNOME extension to reload app code.
  For desktopGrid.js, desktopManager.js, ding.js, WebKit, or other app/ code changes use:
    bash $SCRIPT_DIR/reload-grayhaired.sh

For changes to extension.js itself, prefer a normal logout/login so GNOME Shell
loads a fresh extension module without churning unrelated Zorin extensions.

Read-only verification of an active installation:
  bash $SCRIPT_DIR/verify-wayland-known-good.sh

Recovery/removal:
  bash $SCRIPT_DIR/remove-wayland-separate-ding-prototype.sh
EOF
