#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

fail() {
    printf '[GRAYHAIRED-FIXED-BOUNDARY] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-FIXED-BOUNDARY] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"

grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || \
    fail "adaptive icon-strip marker not found; refusing to patch unknown layout"

grep -Fq 'this._eventBox.set_size_request(liveIconStripWidth, -1);' "$GRID" || \
    fail "adaptive EventBox width request not found; refusing to patch unknown layout"

if grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID"; then
    pass "fixed two-column boundary is already installed"
    exit 0
fi

backup="$GRID.pre-fixed-two-column-boundary"
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

anchor = "        this._liveLayout.pack_start(this._eventBox, false, false, 0);\n"
replacement = """        // GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY
        // set_size_request() is only a minimum in GTK3. DING's Gtk.Fixed can
        // request more width when an icon is dragged farther right, which
        // temporarily steals pixels from WebKit. Keep the original EventBox
        // and DING input/focus behavior unchanged, but place it inside a
        // non-scrolling viewport whose preferred content width is clamped to
        // exactly the adaptive two-column width.
        this._liveIconBoundary = new Gtk.ScrolledWindow({
            hscrollbar_policy: Gtk.PolicyType.NEVER,
            vscrollbar_policy: Gtk.PolicyType.NEVER,
            shadow_type: Gtk.ShadowType.NONE,
            can_focus: false,
        });
        this._liveIconBoundary.set_min_content_width(liveIconStripWidth);
        this._liveIconBoundary.set_max_content_width(liveIconStripWidth);
        this._liveIconBoundary.set_propagate_natural_width(false);
        this._liveIconBoundary.set_size_request(liveIconStripWidth, -1);

        this._liveIconViewport = new Gtk.Viewport({
            can_focus: false,
        });
        this._liveIconViewport.add(this._eventBox);
        this._liveIconBoundary.add(this._liveIconViewport);

        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);
"""

if anchor not in text:
    raise SystemExit("expected EventBox packing anchor not found; refusing to patch")

text = text.replace(anchor, replacement, 1)
path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "fixed-boundary marker missing after patch"
grep -Fq 'set_max_content_width(liveIconStripWidth)' "$GRID" || \
    fail "maximum content-width clamp missing after patch"
grep -Fq 'pack_start(this._liveIconBoundary, false, false, 0)' "$GRID" || \
    fail "fixed boundary is not packed into live layout"

pass "fixed adaptive two-column boundary experiment installed"
printf '[GRAYHAIRED-FIXED-BOUNDARY] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child to activate the experiment"
