#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
MANAGER="$EXT/app/desktopManager.js"

fail() {
    printf '[GRAYHAIRED-MANAGER-REFLOW] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-MANAGER-REFLOW] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$MANAGER" ]] || fail "installed desktopManager.js not found: $MANAGER"

grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || \
    fail "adaptive icon-strip marker not found"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "fixed two-column boundary marker not found"
grep -Fq 'GRAYHAIRED-LIVE-ICON-SIZE-TRACKING' "$GRID" || \
    fail "live icon-size tracking marker not found"
grep -Fq "if (key == 'icon-size')" "$MANAGER" || \
    fail "DING icon-size manager branch not found"

if grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" && \
   grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$MANAGER"; then
    pass "manager-synchronized live-size reflow is already installed"
    exit 0
fi

for file in "$GRID" "$MANAGER"; do
    backup="$file.pre-manager-synced-live-size"
    if [[ ! -e "$backup" ]]; then
        cp -a "$file" "$backup"
        pass "saved rollback copy: $backup"
    else
        pass "rollback copy already exists: $backup"
    fi
done

python3 - "$GRID" "$MANAGER" <<'PY'
from pathlib import Path
import sys

grid_path = Path(sys.argv[1])
manager_path = Path(sys.argv[2])
grid = grid_path.read_text(encoding="utf-8")
manager = manager_path.read_text(encoding="utf-8")

# Preserve Zorin's original right margin before GrayHaired converts it into the
# split-surface reservation. We need the original value for every later live
# recalculation rather than compounding the already-expanded marginRight.
base_anchor = """        desktopDescription = Object.assign({}, desktopDescription);\n        // GRAYHAIRED-ADAPTIVE-ICON-STRIP\n"""
base_replacement = """        desktopDescription = Object.assign({}, desktopDescription);\n        // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n        // Preserve the real Zorin margin so live width changes can rebuild the\n        // DING usable rectangle from the monitor geometry instead of from the\n        // previously expanded GrayHaired marginRight.\n        this._liveBaseMarginRight = desktopDescription.marginRight;\n        // GRAYHAIRED-ADAPTIVE-ICON-STRIP\n"""
if 'this._liveBaseMarginRight = desktopDescription.marginRight;' not in grid:
    if base_anchor not in grid:
        raise SystemExit("desktopDescription clone anchor not found")
    grid = grid.replace(base_anchor, base_replacement, 1)

# Add a DesktopGrid method that updates both halves of the contract:
# 1) GTK's fixed boundary width; and
# 2) DING's own desktopDescription.marginRight / usable grid width.
method_anchor = """    resizeGrid() {\n        this.updateUnscaledHeightWidthMargins();\n        this.createGrids();\n        this.updateGridRectangle();\n        this.sizeEventBox();\n        this.setGridStatus();\n    }\n\n"""
method_replacement = """    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n    updateLiveIconBoundaryWidth() {\n        const liveIconColumns = 2;\n        const liveIconStripPadding = 8;\n        const liveIconStripMin = 160;\n        const liveIconStripMax = 320;\n        const liveIconStripFallback = 220;\n        const desiredCellWidth = Prefs.get_desired_width() + 4 * elementSpacing;\n\n        let nextWidth = liveIconStripFallback;\n        if (Number.isFinite(desiredCellWidth) && desiredCellWidth > 0) {\n            nextWidth = Math.max(\n                liveIconStripMin,\n                Math.min(\n                    liveIconStripMax,\n                    liveIconColumns * desiredCellWidth + liveIconStripPadding\n                )\n            );\n        }\n\n        // Keep the full monitor-sized top-level window, but make DING's own\n        // usable rectangle exactly match the proven two-column GTK boundary.\n        this._desktopDescription.marginRight = Math.max(\n            this._liveBaseMarginRight,\n            this._desktopDescription.width -\n                this._desktopDescription.marginLeft - nextWidth\n        );\n\n        if (this._eventBox)\n            this._eventBox.set_size_request(nextWidth, -1);\n        if (this._liveIconBoundary) {\n            this._liveIconBoundary.set_min_content_width(nextWidth);\n            this._liveIconBoundary.set_max_content_width(nextWidth);\n            this._liveIconBoundary.set_size_request(nextWidth, -1);\n            this._liveIconBoundary.queue_resize();\n        }\n        if (this._liveLayout)\n            this._liveLayout.queue_resize();\n\n        print(\n            `[GRAYHAIRED-MANAGER-REFLOW] icon cell=${desiredCellWidth}px ` +\n            `columns=${liveIconColumns} strip=${nextWidth}px ` +\n            `marginRight=${this._desktopDescription.marginRight}px`\n        );\n    }\n\n    resizeGrid() {\n        this.updateUnscaledHeightWidthMargins();\n        this.createGrids();\n        this.updateGridRectangle();\n        this.sizeEventBox();\n        this.setGridStatus();\n    }\n\n"""
if 'updateLiveIconBoundaryWidth() {' not in grid:
    if method_anchor not in grid:
        raise SystemExit("resizeGrid method anchor not found")
    grid = grid.replace(method_anchor, method_replacement, 1)

# Insert the GrayHaired boundary/desktop-description update into DING's native
# icon-size handling *before* it clears and rebuilds the grid. Everything after
# this point remains DING's stock safe reflow sequence.
manager_anchor = """            if (key == 'icon-size') {\n                this._fileList.forEach(x => x.removeFromGrid(false));\n                for (let desktop of this._desktops) {\n                    desktop.resizeGrid();\n                }\n                this._fileList.forEach(x => x.updateIcon());\n                this._placeAllFilesOnGrids(true);\n                return;\n            }\n"""
manager_replacement = """            if (key == 'icon-size') {\n                // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n                // Synchronize GTK's fixed boundary and DING's own usable\n                // desktop rectangle before DING performs its normal reflow.\n                for (let desktop of this._desktops) {\n                    if (desktop.updateLiveIconBoundaryWidth)\n                        desktop.updateLiveIconBoundaryWidth();\n                }\n                this._fileList.forEach(x => x.removeFromGrid(false));\n                for (let desktop of this._desktops) {\n                    desktop.resizeGrid();\n                }\n                this._fileList.forEach(x => x.updateIcon());\n                this._placeAllFilesOnGrids(true);\n                return;\n            }\n"""
if 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' not in manager:
    if manager_anchor not in manager:
        raise SystemExit("stock DING icon-size manager branch not found")
    manager = manager.replace(manager_anchor, manager_replacement, 1)

grid_path.write_text(grid, encoding="utf-8")
manager_path.write_text(manager, encoding="utf-8")
PY

grep -Fq 'updateLiveIconBoundaryWidth()' "$GRID" || \
    fail "DesktopGrid live boundary method missing after patch"
grep -Fq 'this._liveBaseMarginRight = desktopDescription.marginRight;' "$GRID" || \
    fail "base Zorin right margin preservation missing after patch"
grep -Fq 'desktop.updateLiveIconBoundaryWidth()' "$MANAGER" || \
    fail "desktopManager live boundary hook missing after patch"
grep -Fq 'this._placeAllFilesOnGrids(true);' "$MANAGER" || \
    fail "DING file re-placement step missing after patch"

pass "manager-synchronized live-size reflow experiment installed"
printf '[GRAYHAIRED-MANAGER-REFLOW] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child once, then change icon sizes without further reloads"
