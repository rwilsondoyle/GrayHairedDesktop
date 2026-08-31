#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-tight-width-stage18"
NEW_MIN=204

fail() {
    printf '[GRAYHAIRED-PANE18] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PANE18] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || fail "Stage 11 compressed width is not installed"
grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID" || fail "Stage 15 virtual scrolling is not installed"
grep -Fq 'GRAYHAIRED-MANUAL-BACKGROUND-STAGE17' "$GRID" || fail "Stage 17 background controls are not installed"

if grep -Fq 'GRAYHAIRED-TIGHT-WIDTH-STAGE18' "$GRID"; then
    pass "Stage 18 tighter-width test is already installed"
    exit 0
fi

count="$(grep -Fc 'const liveIconStripMin = 240;' "$GRID" || true)"
[[ "$count" -ge 2 ]] || fail "expected at least two Stage 11 240px minimum assignments, found $count"

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" "$NEW_MIN" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
new_min = int(sys.argv[2])
text = path.read_text(encoding='utf-8')

marker = '        // GRAYHAIRED-COMPRESSED-WIDTH-STAGE11\n'
if marker not in text:
    raise SystemExit('Stage 11 marker missing')
text = text.replace(
    marker,
    '        // GRAYHAIRED-TIGHT-WIDTH-STAGE18\n'
    '        // Reversible physical test: reduce the Stage 11 minimum from 240px\n'
    '        // to 204px. Tiny/Small should remain two columns while reclaiming\n'
    '        // 36px for the WebKit page. No GTK hierarchy or scroll logic changes.\n'
    + marker,
    1,
)

old = '        const liveIconStripMin = 240;\n'
if text.count(old) < 2:
    raise SystemExit('expected two 240px minimum assignments')
text = text.replace(old, f'        const liveIconStripMin = {new_min};\n', 2)
text = text.replace('strip=${nextWidth}px min=240px ', f'strip=${{nextWidth}}px min={new_min}px ', 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-TIGHT-WIDTH-STAGE18' "$GRID" || fail "Stage 18 marker missing after patch"
[[ "$(grep -Fc 'const liveIconStripMin = 204;' "$GRID")" -ge 2 ]] || fail "204px minimum not present in startup and live-reflow geometry"
grep -Fq 'min=204px' "$GRID" || fail "Stage 18 diagnostic minimum was not updated"

pass "Stage 18 tighter icon-pane width installed"
printf '[GRAYHAIRED-PANE18] INFO: expected approximate widths: Tiny=204 Small=204 Standard=264 Large=284.\n'
printf '[GRAYHAIRED-PANE18] INFO: reload only the GrayHaired child, then test Tiny first and compare all four sizes.\n'
