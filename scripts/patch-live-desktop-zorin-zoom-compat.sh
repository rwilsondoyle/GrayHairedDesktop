#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-zorin-zoom-compat"

fail() {
    printf '[GRAYHAIRED-ZOOM] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-ZOOM] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"

if grep -Fq 'GRAYHAIRED-ZORIN-ZOOM-COMPAT' "$GRID"; then
    pass "Zorin zoom/scale compatibility is already installed"
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

old = "        this._zoom = this._desktopDescription.scaleFactor;\n"
new = """        // GRAYHAIRED-ZORIN-ZOOM-COMPAT
        // Zorin/DING desktop descriptions have used both scaleFactor and zoom
        // across releases. Prefer scaleFactor when present, otherwise use zoom,
        // and fall back safely to 1 so geometry never becomes NaN.
        const grayhairedScale = Number.isFinite(this._desktopDescription.scaleFactor)
            ? this._desktopDescription.scaleFactor
            : (Number.isFinite(this._desktopDescription.zoom)
                ? this._desktopDescription.zoom
                : 1);
        this._zoom = grayhairedScale > 0 ? grayhairedScale : 1;
"""

if old not in text:
    raise SystemExit('expected updateWindowGeometry scale assignment not found')

text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-ZORIN-ZOOM-COMPAT' "$GRID" || \
    fail "compatibility marker missing after patch"
grep -Fq 'this._desktopDescription.zoom' "$GRID" || \
    fail "zoom fallback missing after patch"
grep -Fq 'grayhairedScale > 0 ? grayhairedScale : 1' "$GRID" || \
    fail "safe geometry fallback missing after patch"

pass "Zorin scaleFactor/zoom compatibility installed"
printf '[GRAYHAIRED-ZOOM] INFO: prevents NaN desktop geometry when current Zorin supplies zoom instead of scaleFactor.\n'
