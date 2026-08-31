#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

fail() {
    printf '[GRAYHAIRED-ALLOC] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-ALLOC] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"

grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || \
    fail "adaptive icon-strip marker not found; refusing to patch unknown layout"

if grep -Fq 'GRAYHAIRED-LAYOUT-ALLOCATION-LOGGER' "$GRID"; then
    pass "allocation logger is already installed"
    exit 0
fi

backup="$GRID.pre-allocation-logger"
if [[ ! -e "$backup" ]]; then
    cp -a "$GRID" "$backup"
    pass "saved one-time rollback copy: $backup"
else
    pass "rollback copy already exists: $backup"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

anchor = """        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n\n        this._window.add(this._liveLayout);\n"""

replacement = """        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n\n        // GRAYHAIRED-LAYOUT-ALLOCATION-LOGGER\n        // Diagnostic only: report actual GTK allocations when they change.\n        // This does not alter size requests, packing, focus, or input handling.\n        this._liveLastIconAllocationWidth = null;\n        this._liveLastWebAllocationWidth = null;\n        this._liveLastLayoutAllocationWidth = null;\n\n        this._eventBox.connect('size-allocate', (_widget, allocation) => {\n            if (allocation.width !== this._liveLastIconAllocationWidth) {\n                this._liveLastIconAllocationWidth = allocation.width;\n                print(`[GRAYHAIRED-ALLOC] icon=${allocation.width}px`);\n            }\n        });\n\n        this._liveWebView.connect('size-allocate', (_widget, allocation) => {\n            if (allocation.width !== this._liveLastWebAllocationWidth) {\n                this._liveLastWebAllocationWidth = allocation.width;\n                print(`[GRAYHAIRED-ALLOC] web=${allocation.width}px`);\n            }\n        });\n\n        this._liveLayout.connect('size-allocate', (_widget, allocation) => {\n            if (allocation.width !== this._liveLastLayoutAllocationWidth) {\n                this._liveLastLayoutAllocationWidth = allocation.width;\n                print(`[GRAYHAIRED-ALLOC] layout=${allocation.width}px`);\n            }\n        });\n\n        this._window.add(this._liveLayout);\n"""

if anchor not in text:
    raise SystemExit("expected live-layout packing anchor not found; refusing to patch")

text = text.replace(anchor, replacement, 1)
path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-LAYOUT-ALLOCATION-LOGGER' "$GRID" || \
    fail "allocation logger marker missing after patch"
grep -Fq '[GRAYHAIRED-ALLOC] icon=' "$GRID" || \
    fail "icon allocation logger missing after patch"
grep -Fq '[GRAYHAIRED-ALLOC] web=' "$GRID" || \
    fail "WebKit allocation logger missing after patch"

pass "split-surface allocation logger installed"
printf '[GRAYHAIRED-ALLOC] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child to activate logging"
