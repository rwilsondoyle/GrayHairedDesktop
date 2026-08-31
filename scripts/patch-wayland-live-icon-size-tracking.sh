#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

fail() {
    printf '[GRAYHAIRED-LIVE-SIZE] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LIVE-SIZE] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"

grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || \
    fail "adaptive icon-strip marker not found; refusing to patch unknown layout"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "fixed two-column boundary marker not found; refusing to patch unknown layout"
grep -Fq 'this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);' "$GRID" || \
    fail "known-good fixed-boundary packing anchor not found"

if grep -Fq 'GRAYHAIRED-LIVE-ICON-SIZE-TRACKING' "$GRID"; then
    pass "live icon-size tracking is already installed"
    exit 0
fi

backup="$GRID.pre-live-icon-size-tracking"
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

anchor = "        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);\n"
replacement = """        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);\n\n        // GRAYHAIRED-LIVE-ICON-SIZE-TRACKING\n        // Follow Zorin/DING's existing icon-size setting live. DING remains\n        // responsible for changing the icon/grid size; GrayHaired only\n        // recalculates its already-proven fixed two-column boundary afterward.\n        const LiveGio = imports.gi.Gio;\n        const LiveGLib = imports.gi.GLib;\n        this._liveIconSizeSettings = new LiveGio.Settings({\n            schema_id: 'org.gnome.shell.extensions.zorin-desktop-icons',\n        });\n        this._liveIconResizeSource = 0;\n\n        const applyLiveIconBoundaryWidth = () => {\n            const desiredCellWidth = Prefs.get_desired_width() + 4 * elementSpacing;\n            let nextWidth = liveIconStripFallback;\n            if (Number.isFinite(desiredCellWidth) && desiredCellWidth > 0) {\n                nextWidth = Math.max(\n                    liveIconStripMin,\n                    Math.min(\n                        liveIconStripMax,\n                        liveIconColumns * desiredCellWidth + liveIconStripPadding\n                    )\n                );\n            }\n\n            liveIconStripWidth = nextWidth;\n            this._eventBox.set_size_request(liveIconStripWidth, -1);\n            this._liveIconBoundary.set_min_content_width(liveIconStripWidth);\n            this._liveIconBoundary.set_max_content_width(liveIconStripWidth);\n            this._liveIconBoundary.set_size_request(liveIconStripWidth, -1);\n            this._liveIconBoundary.queue_resize();\n            this._liveLayout.queue_resize();\n\n            print(\n                `[GRAYHAIRED-LIVE-SIZE] icon cell=${desiredCellWidth}px ` +\n                `columns=${liveIconColumns} strip=${liveIconStripWidth}px`\n            );\n        };\n\n        this._liveIconSizeSettings.connect('changed::icon-size', () => {\n            // Defer one main-loop turn so DING's own preferences callback can\n            // update Prefs.get_desired_width() before we read the new geometry.\n            if (this._liveIconResizeSource !== 0)\n                return;\n\n            this._liveIconResizeSource = LiveGLib.idle_add(\n                LiveGLib.PRIORITY_DEFAULT_IDLE,\n                () => {\n                    this._liveIconResizeSource = 0;\n                    applyLiveIconBoundaryWidth();\n                    return LiveGLib.SOURCE_REMOVE;\n                }\n            );\n        });\n"""

if anchor not in text:
    raise SystemExit("expected fixed-boundary packing anchor not found; refusing to patch")

text = text.replace(anchor, replacement, 1)
path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-LIVE-ICON-SIZE-TRACKING' "$GRID" || \
    fail "live-size tracking marker missing after patch"
grep -Fq "changed::icon-size" "$GRID" || \
    fail "icon-size GSettings signal hook missing after patch"
grep -Fq '[GRAYHAIRED-LIVE-SIZE] icon cell=' "$GRID" || \
    fail "live-size diagnostic logging missing after patch"

pass "live icon-size tracking patch installed"
printf '[GRAYHAIRED-LIVE-SIZE] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child once to activate live tracking"
