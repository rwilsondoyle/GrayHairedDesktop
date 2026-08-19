#!/usr/bin/env bash
set -euo pipefail

UUID="zorin-desktop-icons@zorinos.com"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$UUID"
USER_ROOT="$HOME/.local/share/gnome-shell/extensions"
USER_EXT="$USER_ROOT/$UUID"
BACKUP_EXT="$USER_ROOT/${UUID}.grayhaired-backup"
GRID="$USER_EXT/app/desktopGrid.js"

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

mkdir -p "$USER_ROOT"

if [[ -e "$BACKUP_EXT" ]]; then
    echo "A previous prototype backup already exists:"
    echo "  $BACKUP_EXT"
    echo "Remove or restore that backup before installing again."
    exit 2
fi

if [[ -e "$USER_EXT" ]]; then
    mv "$USER_EXT" "$BACKUP_EXT"
    echo "Backed up existing user-local extension override to:"
    echo "  $BACKUP_EXT"
fi

cp -a "$SYSTEM_EXT" "$USER_EXT"

echo "Created user-local Zorin extension copy:"
echo "  $USER_EXT"

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
"""
new_description = """        // GrayHairedDesktop Wayland research prototype:
        // reserve a real DING icon strip on the left and leave the rest of
        // the desktop to an embedded WebKit view. Work on a shallow copy so
        // the geometry object supplied by the extension is not mutated.
        desktopDescription = Object.assign({}, desktopDescription);
        const liveIconStripWidth = 220;
        desktopDescription.marginRight = Math.max(
            desktopDescription.marginRight,
            desktopDescription.width - liveIconStripWidth
        );
        this._desktopDescription = desktopDescription;
        this.updateWindowGeometry();
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
        this.sizeEventBox();

        // Keep DING's original widget hierarchy intact inside a dedicated
        // left-side strip. This preserves its clicks, context menus and DnD.
        this._eventBox.set_size_request(220, this._windowHeight);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);

        // Put WebKit beside DING rather than underneath it. The two systems
        // therefore do not compete for the same pointer events on Wayland.
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
print("Patched user-local desktopGrid.js for the Wayland split-surface prototype.")
PY

cat <<EOF

=== WAYLAND DING LIVE PROTOTYPE INSTALLED ===

System extension was NOT modified:
  $SYSTEM_EXT

User-local prototype:
  $USER_EXT

Next step: log out of Zorin and log back into Wayland.
A reboot is NOT required.

After login, verify with:
  echo "Session: \$XDG_SESSION_TYPE"
  gnome-extensions info $UUID | head -20

To remove the prototype later, run:
  bash ~/GrayHairedDesktop/scripts/remove-wayland-ding-live-prototype.sh
EOF
