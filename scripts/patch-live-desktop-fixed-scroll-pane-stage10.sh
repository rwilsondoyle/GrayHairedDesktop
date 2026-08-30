#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
MANAGER="$EXT/app/desktopManager.js"
FIXED_WIDTH=264

fail() {
    printf '[GRAYHAIRED-PANE10] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PANE10] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$MANAGER" ]] || fail "installed desktopManager.js not found: $MANAGER"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || fail "fixed boundary marker missing"
grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" || fail "manager-synced live-size marker missing"
grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$MANAGER" || fail "manager live-size hook missing"

if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    pass "Stage 10 fixed scroll pane is already installed"
    exit 0
fi

for file in "$GRID" "$MANAGER"; do
    backup="$file.pre-fixed-scroll-pane-stage10"
    if [[ ! -e "$backup" ]]; then
        cp -a "$file" "$backup"
        pass "saved rollback copy: $backup"
    fi
done

python3 - "$GRID" "$MANAGER" "$FIXED_WIDTH" <<'PY'
from pathlib import Path
import re
import sys

grid_path = Path(sys.argv[1])
manager_path = Path(sys.argv[2])
fixed_width = int(sys.argv[3])
grid = grid_path.read_text(encoding='utf-8')
manager = manager_path.read_text(encoding='utf-8')

# Mark the experiment and make the existing ScrolledWindow vertically scrollable.
old_boundary = """        // GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY
        // set_size_request() is only a minimum in GTK3. DING's Gtk.Fixed can
"""
new_boundary = """        // GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10
        // Experimental consistent-width desktop icon pane. The horizontal
        // boundary stays fixed while GTK may expose a vertical scrollbar if
        // DING's content becomes taller than the visible monitor area.
        // GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY
        // set_size_request() is only a minimum in GTK3. DING's Gtk.Fixed can
"""
if old_boundary not in grid:
    raise SystemExit('fixed boundary anchor not found')
grid = grid.replace(old_boundary, new_boundary, 1)

grid = grid.replace(
    '            vscrollbar_policy: Gtk.PolicyType.NEVER,',
    '            vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,',
    1,
)

# Startup boundary: replace the computed adaptive width at the final width-use
# point with the fixed experimental width. Retain the adaptive calculation for
# diagnostics and easy rollback.
startup_anchor = """        this._liveIconBoundary.set_min_content_width(liveIconStripWidth);
        this._liveIconBoundary.set_max_content_width(liveIconStripWidth);
        this._liveIconBoundary.set_propagate_natural_width(false);
        this._liveIconBoundary.set_size_request(liveIconStripWidth, -1);
"""
startup_replacement = f"""        const liveFixedPaneWidth = {fixed_width};
        this._liveIconBoundary.set_min_content_width(liveFixedPaneWidth);
        this._liveIconBoundary.set_max_content_width(liveFixedPaneWidth);
        this._liveIconBoundary.set_propagate_natural_width(false);
        this._liveIconBoundary.set_size_request(liveFixedPaneWidth, -1);
        this._eventBox.set_size_request(liveFixedPaneWidth, -1);
"""
if startup_anchor not in grid:
    raise SystemExit('startup fixed-boundary width block not found')
grid = grid.replace(startup_anchor, startup_replacement, 1)

# Ensure DING's startup usable rectangle also matches the fixed width. The
# adaptive installer has already computed marginRight from liveIconStripWidth.
# Rebuild it once after the fixed pane width exists.
pack_anchor = """        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);
"""
pack_replacement = f"""        this._desktopDescription.marginRight = Math.max(
            this._liveBaseMarginRight,
            this._desktopDescription.width -
                this._desktopDescription.marginLeft - liveFixedPaneWidth
        );
        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);
        print(`[GRAYHAIRED-PANE10] startup fixed=${{liveFixedPaneWidth}}px`);
"""
if pack_anchor not in grid:
    raise SystemExit('live boundary packing anchor not found')
grid = grid.replace(pack_anchor, pack_replacement, 1)

# Replace only the body of the existing live-width method so icon-size changes
# still trigger DING's proven remove/resize/update/re-place sequence, but no
# longer change the WebKit/icon-pane split width.
method_pattern = re.compile(
    r"    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n"
    r"    updateLiveIconBoundaryWidth\(\) \{.*?\n    \}\n\n"
    r"    resizeGrid\(\) \{",
    re.S,
)
method_replacement = f"""    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE
    updateLiveIconBoundaryWidth() {{
        // GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10
        // Icon size changes still reflow DING, but the desktop/webpage split
        // remains stable at the Standard-size width.
        const nextWidth = {fixed_width};
        const desiredCellWidth = Prefs.get_desired_width() + 4 * elementSpacing;

        this._desktopDescription.marginRight = Math.max(
            this._liveBaseMarginRight,
            this._desktopDescription.width -
                this._desktopDescription.marginLeft - nextWidth
        );

        if (this._eventBox)
            this._eventBox.set_size_request(nextWidth, -1);
        if (this._liveIconBoundary) {{
            this._liveIconBoundary.set_min_content_width(nextWidth);
            this._liveIconBoundary.set_max_content_width(nextWidth);
            this._liveIconBoundary.set_size_request(nextWidth, -1);
            this._liveIconBoundary.queue_resize();
        }}
        if (this._liveLayout)
            this._liveLayout.queue_resize();

        print(
            `[GRAYHAIRED-PANE10] icon cell=${{desiredCellWidth}}px ` +
            `fixed=${{nextWidth}}px marginRight=${{this._desktopDescription.marginRight}}px`
        );
    }}

    resizeGrid() {{"""
new_grid, count = method_pattern.subn(method_replacement, grid, count=1)
if count != 1:
    raise SystemExit(f'live boundary method replacement count={count}, expected 1')
grid = new_grid

grid_path.write_text(grid, encoding='utf-8')
manager_path.write_text(manager, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID" || fail "Stage 10 marker missing"
grep -Fq 'vscrollbar_policy: Gtk.PolicyType.AUTOMATIC' "$GRID" || fail "vertical automatic scrollbar policy missing"
grep -Fq 'const nextWidth = 264;' "$GRID" || fail "fixed live width missing"
grep -Fq '[GRAYHAIRED-PANE10] icon cell=' "$GRID" || fail "Stage 10 reflow logging missing"

pass "Stage 10 fixed-width scroll-pane experiment installed at ${FIXED_WIDTH}px"
printf '[GRAYHAIRED-PANE10] INFO: %s\n' \
    "reload only the GrayHaired child; then compare Tiny/Small/Standard/Large without further reloads"
printf '[GRAYHAIRED-PANE10] INFO: %s\n' \
    "Large may use fewer columns at this width; vertical scrolling is enabled at the GTK boundary but DING overflow behavior is still experimental"
