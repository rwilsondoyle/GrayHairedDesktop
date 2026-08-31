#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-block-local-file-drop-stage19"

fail() {
    printf '[GRAYHAIRED-DROP19] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-DROP19] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq "Opening in default browser" "$GRID" || fail "WebKit navigation policy handler is not installed"

if grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID"; then
    pass "Stage 19 local-file navigation guard is already installed"
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

anchor = """                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
"""
replacement = """                // GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19
                // A desktop-style surface should never navigate away from its
                // configured website just because a local file was accidentally
                // dropped over WebKit. Reject file:// requests regardless of
                // gesture/new-window state. Desktop icon drag/rearrange remains
                // entirely on the DING side and is unaffected.
                if (uri && uri.startsWith('file://')) {
                    print(`[GRAYHAIRED-DROP19] blocked local file navigation: ${uri}`);
                    decision.ignore();
                    return true;
                }

                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
"""

if anchor not in text:
    raise SystemExit('WebKit navigation-policy anchor not found')

path.write_text(text.replace(anchor, replacement, 1), encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID" || fail "Stage 19 marker missing after patch"
grep -Fq '[GRAYHAIRED-DROP19] blocked local file navigation:' "$GRID" || fail "Stage 19 diagnostic log missing"

pass "Stage 19 local-file navigation guard installed"
printf '[GRAYHAIRED-DROP19] INFO: reload only the GrayHaired child, then drag a harmless local text file onto the WebKit/page side.\n'
printf '[GRAYHAIRED-DROP19] INFO: the desktop website should remain visible and the file should not open there.\n'
