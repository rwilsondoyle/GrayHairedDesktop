#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-navigation-diagnostics-stage20b"

fail() {
    printf '[GRAYHAIRED-LINK20B] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LINK20B] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-CREATE-HANDOFF-STAGE20' "$GRID" || fail "Stage 20 create handoff must be installed first"
grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID" || fail "Stage 19 local-file guard is missing"

if grep -Fq 'GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B' "$GRID"; then
    pass "Stage 20B navigation diagnostics are already installed"
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

anchor = """                // GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19
"""
insert = """                // GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B
                // Diagnostic only: log every inspected navigation action before
                // any existing Stage 19/local-file or browser-handoff decision.
                // This lets us identify same-window authentication flows without
                // changing their behavior yet.
                print(
                    `[GRAYHAIRED-LINK20B] nav uri=${uri || '<empty>'} ` +
                    `gesture=${isUserGesture} newWindow=${isNewWindow} ` +
                    `decisionType=${decisionType}`
                );

"""

if anchor not in text:
    raise SystemExit('Stage 19 navigation-policy anchor not found')

text = text.replace(anchor, insert + anchor, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B' "$GRID" || fail "Stage 20B marker missing after patch"
grep -Fq '[GRAYHAIRED-LINK20B] nav uri=' "$GRID" || fail "Stage 20B navigation diagnostic log missing"

pass "Stage 20B WebKit navigation diagnostics installed"
printf '[GRAYHAIRED-LINK20B] INFO: reload only the GrayHaired child, click MSN Sign in once, then inspect LINK20B logs.\n'
