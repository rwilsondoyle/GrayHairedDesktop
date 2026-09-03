#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

fail() {
    printf '[GRAYHAIRED-SITE23A] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23A] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V6' "$GRID" || \
    fail "Stage 23A v6 must be installed before adding retry feedback"

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

old_button = '<a class="button" href="${safeUri}">Try Again</a>'
new_button = '''<a class="button" id="retryButton" href="${safeUri}"
       onclick="event.preventDefault(); this.textContent='Trying…'; this.setAttribute('aria-disabled','true'); this.style.pointerEvents='none'; const retryUrl=this.href; setTimeout(() => { window.location.href=retryUrl; }, 650);">Try Again</a>'''

if old_button not in text:
    raise SystemExit('Stage 23A v6 Retry link anchor not found; no changes made')

text = text.replace(old_button, new_button, 1)
text = text.replace(
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V6',
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V7',
    1,
)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V7' "$GRID" || fail "Stage 23A v7 marker missing"
grep -Fq "this.textContent='Trying…'" "$GRID" || fail "Trying feedback missing"
grep -Fq 'setTimeout(() => { window.location.href=retryUrl; }, 650);' "$GRID" || fail "delayed retry navigation missing"

pass "Stage 23A retry now shows Trying… before retrying"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
