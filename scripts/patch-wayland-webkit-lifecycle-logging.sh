#!/usr/bin/env bash
set -euo pipefail

TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.before-webkit-lifecycle-logging"

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
marker = "[GRAYHAIRED-WEBKIT] Live WebView created"

if marker in text:
    print("WebKit lifecycle logging is already present.")
    raise SystemExit(0)

old_create = """        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);
"""
new_create = """        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);
        print(`[GRAYHAIRED-WEBKIT] Live WebView created for ${this._desktopName}`);
"""
if old_create not in text:
    raise SystemExit("Expected WebKit creation block not found; no changes made.")
text = text.replace(old_create, new_create, 1)

old_destroy = """    destroy() {
        this._destroying = true;
        this.disconnectAllSignals();
        this._window.destroy();
    }
"""
new_destroy = """    destroy() {
        this._destroying = true;
        if (this._liveWebView) {
            print(`[GRAYHAIRED-WEBKIT] Destroying live WebView for ${this._desktopName}`);
        }
        this.disconnectAllSignals();
        this._window.destroy();
        this._liveWebView = null;
        this._liveLayout = null;
    }
"""
if old_destroy not in text:
    raise SystemExit("Expected DesktopGrid.destroy() block not found; no changes made.")
text = text.replace(old_destroy, new_destroy, 1)

if not backup.exists():
    shutil.copy2(path, backup)

path.write_text(text, encoding="utf-8")
print("Added concise WebKit create/destroy lifecycle logging.")
PY

cat <<EOF

=== WEBKIT LIFECYCLE LOGGING READY ===

Patched only the GrayHaired child-side desktopGrid.js:
  $GRID

Reload child code without toggling GNOME extensions:
  bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
EOF
