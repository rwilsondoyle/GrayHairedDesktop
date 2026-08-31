#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
HELPER_UUID="grayhaired-overflow-control@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-vertical-scroll-stage14"

fail() {
    printf '[GRAYHAIRED-SCROLL14] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SCROLL14] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "known-good fixed two-column boundary marker missing"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "known-good Stage 11 marker missing"

# Stage 14 intentionally starts only from the recovered known-good layout.
for bad in \
    GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10 \
    GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12 \
    GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E; do
    if grep -Fq "$bad" "$GRID"; then
        fail "failed experimental marker is still installed: $bad"
    fi
done

if grep -Fq 'GRAYHAIRED-VERTICAL-SCROLL-STAGE14' "$GRID"; then
    pass "Stage 14 minimal vertical scrolling is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

anchor = """        // GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY
        // set_size_request() is only a minimum in GTK3. DING's Gtk.Fixed can
"""
replacement = """        // GRAYHAIRED-VERTICAL-SCROLL-STAGE14
        // Minimal scrolling experiment: keep the proven Stage 11 width,
        // DING geometry, margins, columns, WebKit allocation, and manager
        // reflow untouched. Only allow the existing left-pane ScrolledWindow
        // to expose vertical overflow when DING content extends below the
        // visible desktop area.
        // GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY
        // set_size_request() is only a minimum in GTK3. DING's Gtk.Fixed can
"""
if anchor not in text:
    raise SystemExit('fixed-boundary marker anchor not found')
text = text.replace(anchor, replacement, 1)

old = '            vscrollbar_policy: Gtk.PolicyType.NEVER,\n'
new = '            vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,\n'
count = text.count(old)
if count < 1:
    raise SystemExit('known-good vertical scrollbar policy not found')
text = text.replace(old, new, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-VERTICAL-SCROLL-STAGE14' "$GRID" || \
    fail "Stage 14 marker missing after patch"
grep -Fq 'vscrollbar_policy: Gtk.PolicyType.AUTOMATIC' "$GRID" || \
    fail "automatic vertical scrollbar policy missing"

# Retire the disliked Stage 13F helper. This does not touch the main live
# desktop and avoids an orange Shell-chrome button appearing over applications.
gnome-extensions disable "$HELPER_UUID" >/dev/null 2>&1 || true
rm -rf "$HOME/.local/share/gnome-shell/extensions/$HELPER_UUID"

pass "Stage 14 minimal vertical scrolling experiment installed"
printf '[GRAYHAIRED-SCROLL14] INFO: %s\n' \
    "Stage 13F helper has been disabled/removed; no More button or drawer trigger is used."
printf '[GRAYHAIRED-SCROLL14] INFO: %s\n' \
    "Reload only the GrayHaired child, then test Tiny, Small, Standard, and Large."
printf '[GRAYHAIRED-SCROLL14] INFO: %s\n' \
    "Move the pointer over the left icon pane and try the mouse wheel/touchpad when icons extend below the screen."
