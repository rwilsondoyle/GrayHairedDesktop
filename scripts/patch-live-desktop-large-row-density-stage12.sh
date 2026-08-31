#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
LARGE_EFFECTIVE_HEIGHT=120

fail() {
    printf '[GRAYHAIRED-ROWS12] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-ROWS12] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || fail "Stage 11 compressed-width marker missing"
if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    fail "failed Stage 10 marker is present; refusing to patch"
fi

if grep -Fq 'GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12' "$GRID"; then
    pass "Stage 12 Large-icon row-density experiment is already installed"
    exit 0
fi

needle='        this._maxRows =  Math.floor(this._height / (Prefs.get_desired_height() + 4 * elementSpacing));'
grep -Fq "$needle" "$GRID" || fail "known-good DING maxRows calculation not found"

BACKUP="$GRID.pre-large-row-density-stage12"
if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
else
    pass "rollback copy already exists: $BACKUP"
fi

python3 - "$GRID" "$LARGE_EFFECTIVE_HEIGHT" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
large_effective_height = int(sys.argv[2])
text = path.read_text(encoding='utf-8')

old = "        this._maxRows =  Math.floor(this._height / (Prefs.get_desired_height() + 4 * elementSpacing));\n"
if text.count(old) != 1:
    raise SystemExit(f'expected exactly one maxRows calculation, found {text.count(old)}')

new = f"""        // GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12
        // Keep the actual Large icon at its normal 96px size. Only make the
        // Large-mode grid row calculation denser so one additional row can
        // fit on common 768px displays. Tiny/Small/Standard remain untouched.
        const liveDesiredRowHeight = Prefs.get_desired_height();
        const liveEffectiveRowHeight = liveDesiredRowHeight === 138
            ? {large_effective_height}
            : liveDesiredRowHeight;
        this._maxRows = Math.max(1, Math.floor(
            this._height / (liveEffectiveRowHeight + 4 * elementSpacing)
        ));
        if (liveDesiredRowHeight === 138) {{
            print(
                `[GRAYHAIRED-ROWS12] height=${{this._height}}px ` +
                `desired=${{liveDesiredRowHeight}}px effective=${{liveEffectiveRowHeight}}px ` +
                `rows=${{this._maxRows}}`
            );
        }}
"""

text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12' "$GRID" || fail "Stage 12 marker missing after patch"
grep -Fq 'liveDesiredRowHeight === 138' "$GRID" || fail "Large-only guard missing"
grep -Fq 'liveEffectiveRowHeight' "$GRID" || fail "effective row-height calculation missing"
grep -Fq '[GRAYHAIRED-ROWS12]' "$GRID" || fail "Stage 12 diagnostic logging missing"

pass "Stage 12 Large-icon row-density experiment installed"
printf '[GRAYHAIRED-ROWS12] INFO: %s\n' \
    "Large keeps its 96px icon; only its grid row basis changes from 138px to 120px"
printf '[GRAYHAIRED-ROWS12] INFO: %s\n' \
    "reload only the GrayHaired child once, then test Large for overlap/clipping and extra accessible icons"
