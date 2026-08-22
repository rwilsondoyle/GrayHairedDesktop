#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$SYSTEM_UUID"
GRID="$SYSTEM_EXT/app/desktopGrid.js"
META="$SYSTEM_EXT/metadata.json"

pass() { printf '[GRAYHAIRED-BASE] PASS: %s\n' "$*"; }
fail() { printf '[GRAYHAIRED-BASE] FAIL: %s\n' "$*" >&2; exit 1; }

[[ -d "$SYSTEM_EXT" ]] || fail "system Zorin Desktop Icons extension not found at $SYSTEM_EXT"
[[ -f "$GRID" ]] || fail "desktopGrid.js not found at $GRID"
[[ -f "$META" ]] || fail "metadata.json not found at $META"
pass "system Zorin Desktop Icons files exist"

python3 - "$META" <<'PY'
import json, sys
from pathlib import Path
p = Path(sys.argv[1])
data = json.loads(p.read_text(encoding='utf-8'))
if data.get('uuid') != 'zorin-desktop-icons@zorinos.com':
    raise SystemExit('metadata UUID is not zorin-desktop-icons@zorinos.com')
print('[GRAYHAIRED-BASE] PASS: metadata UUID matches Zorin Desktop Icons')
print('[GRAYHAIRED-BASE] INFO: name=' + str(data.get('name', 'unknown')))
print('[GRAYHAIRED-BASE] INFO: version=' + str(data.get('version', 'unknown')))
print('[GRAYHAIRED-BASE] INFO: shell-version=' + ','.join(map(str, data.get('shell-version', []))))
PY

require_literal() {
    local text="$1"
    local description="$2"
    grep -Fq -- "$text" "$GRID" || fail "$description is missing; installed Zorin DING base is not compatible with the tested patch structure"
    pass "$description is present"
}

# These are the exact structural anchors used by the known-good installer.
# Checking them before copying anything makes Zorin updates fail closed instead
# of partially constructing an untested GrayHaired extension tree.
require_literal "'use strict';" "desktopGrid strict-mode header"
require_literal "const Gtk = imports.gi.Gtk;" "GTK import anchor"
require_literal "const Gdk = imports.gi.Gdk;" "GDK import anchor"
require_literal "this._desktopDescription = desktopDescription;" "desktop-description anchor"
require_literal "this._eventBox = new Gtk.EventBox({visible: true});" "DING EventBox anchor"
require_literal "this._window.add(this._eventBox);" "original desktop window child anchor"
require_literal "this._container = new Gtk.Fixed();" "DING Gtk.Fixed anchor"
require_literal "sizeEventBox() {" "sizeEventBox method anchor"
require_literal "this._eventBox.margin_end = this._marginRight;" "right-margin allocation anchor"
require_literal "this.connectSignal(this._window, 'key-press-event'" "window key-press anchor"
require_literal "this.connectSignal(this._window, 'key-release-event'" "window key-release anchor"
require_literal "destroy() {" "DesktopGrid destroy anchor"
require_literal "this.disconnectAllSignals();" "signal cleanup anchor"
require_literal "this._window.destroy();" "window destroy anchor"

if grep -Fq '[GRAYHAIRED-' "$GRID"; then
    fail "system Zorin desktopGrid.js unexpectedly contains GrayHaired modifications"
fi
pass "system Zorin desktopGrid.js is untouched by GrayHaired markers"

printf '[GRAYHAIRED-BASE] PASS: installed Zorin DING base is structurally compatible with the known-good Wayland installer\n'
