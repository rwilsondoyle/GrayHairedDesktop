#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
MIN_WIDTH=240

fail() {
    printf '[GRAYHAIRED-PANE11] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PANE11] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || fail "adaptive icon-strip marker missing"
grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" || fail "manager-synchronized live-size marker missing"
grep -Fq 'const liveIconStripMin = 160;' "$GRID" || fail "known-good startup minimum-width marker not found"
grep -Fq 'const liveIconStripMin = 160;' "$GRID" || fail "known-good live reflow minimum-width marker not found"

if grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID"; then
    pass "Stage 11 compressed-width experiment is already installed"
    exit 0
fi

BACKUP="$GRID.pre-compressed-width-stage11"
if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" "$MIN_WIDTH" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
minimum = int(sys.argv[2])
text = path.read_text(encoding='utf-8')

needle = '        const liveIconStripMin = 160;\n'
count = text.count(needle)
if count < 2:
    raise SystemExit(f'expected at least two adaptive minimum-width assignments, found {count}')

# Mark the startup adaptive geometry block and raise only its minimum width.
startup_marker = '        // GRAYHAIRED-ADAPTIVE-ICON-STRIP\n'
if startup_marker not in text:
    raise SystemExit('adaptive startup marker missing')
text = text.replace(
    startup_marker,
    '        // GRAYHAIRED-COMPRESSED-WIDTH-STAGE11\n'
    '        // Keep the proven adaptive/two-column geometry, but raise the\n'
    '        // minimum pane width so Tiny and Small do not make the WebKit\n'
    '        // surface dramatically wider than Standard/Large.\n'
    + startup_marker,
    1,
)

# Replace the first two known-good minimum assignments: startup calculation and
# manager-synchronized live icon-size reflow. No GTK hierarchy, DING column
# calculation, margins, focus, WebKit, or photo logic is otherwise changed.
text = text.replace(needle, f'        const liveIconStripMin = {minimum};\n', 2)

# Add concise diagnostics to the existing manager log without changing logic.
old_log = '`columns=${liveIconColumns} strip=${nextWidth}px ` +\n'
new_log = '`columns=${liveIconColumns} strip=${nextWidth}px min=240px ` +\n'
if old_log in text:
    text = text.replace(old_log, new_log, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || fail "Stage 11 marker missing"
[[ "$(grep -Fc 'const liveIconStripMin = 240;' "$GRID")" -ge 2 ]] || fail "240px minimum not present in both startup and live-reflow geometry"
grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID" && fail "failed Stage 10 marker is unexpectedly present"

pass "Stage 11 compressed-width experiment installed"
printf '[GRAYHAIRED-PANE11] INFO: %s\n' \
    "expected pane widths are approximately Tiny=240 Small=240 Standard=264 Large=284"
printf '[GRAYHAIRED-PANE11] INFO: %s\n' \
    "reload only the GrayHaired child once; then compare all four icon sizes without further reloads"
