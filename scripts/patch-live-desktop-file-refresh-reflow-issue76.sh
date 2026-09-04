#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
MANAGER="$EXT/app/desktopManager.js"
BACKUP="$MANAGER.pre-issue76-file-refresh-reflow"

fail() {
    printf '[GRAYHAIRED-ISSUE76] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-ISSUE76] PASS: %s\n' "$*"
}

[[ -f "$MANAGER" ]] || fail "installed desktopManager.js not found: $MANAGER"

if grep -Fq 'GRAYHAIRED-DESKTOP-FILE-REFLOW-ISSUE76' "$MANAGER"; then
    pass "desktop-file refresh reflow fix is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$MANAGER" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$MANAGER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

# Preserve the exact physically tested live fix if this machine already has
# the temporary Issue #76 marker from hands-on testing.
if 'GRAYHAIRED-ISSUE76-FILE-REFLOW-TEST' in text:
    text = text.replace(
        'GRAYHAIRED-ISSUE76-FILE-REFLOW-TEST',
        'GRAYHAIRED-DESKTOP-FILE-REFLOW-ISSUE76',
        1,
    )
    text = text.replace(
        '// A desktop-file change can alter the number of rows required by the\n'
        '        // GrayHaired scroll canvas. Rebuild grid geometry before placing files.',
        '// Desktop-file changes can alter the rows required by the GrayHaired\n'
        '        // scroll canvas. Rebuild grid geometry before placing files.',
        1,
    )
    path.write_text(text, encoding='utf-8')
    raise SystemExit(0)

old = """        this._removeAllFilesFromGrids();
        this._fileList = fileList;
        // Select the files that were selected before the repaint
"""
new = """        this._removeAllFilesFromGrids();
        this._fileList = fileList;

        // GRAYHAIRED-DESKTOP-FILE-REFLOW-ISSUE76
        // Desktop-file changes can alter the rows required by the GrayHaired
        // scroll canvas. Rebuild grid geometry before placing files.
        for (let desktop of this._desktops) {
            desktop.resizeGrid();
        }

        // Select the files that were selected before the repaint
"""

if old not in text:
    raise SystemExit('expected _drawDesktop file-list block not found')

text = text.replace(old, new, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-DESKTOP-FILE-REFLOW-ISSUE76' "$MANAGER" || \
    fail "Issue #76 marker missing after patch"
grep -Fq 'desktop.resizeGrid();' "$MANAGER" || \
    fail "grid resize call missing after patch"

pass "desktop-file changes now rebuild grid geometry before icon placement"
printf '[GRAYHAIRED-ISSUE76] INFO: new desktop icons should appear automatically at every icon size without toggling size settings.\n'
