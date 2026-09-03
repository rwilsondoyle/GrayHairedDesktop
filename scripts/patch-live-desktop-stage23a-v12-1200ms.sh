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

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V12' in text:
    if 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200' not in text:
        raise SystemExit('v12 marker exists but 1200ms retry delay is missing')
    print('[GRAYHAIRED-SITE23A] Stage 23A v12 1200ms timing already installed')
    raise SystemExit(0)

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V11' in text:
    marker = 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V11'
    old_delay = 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {'
elif 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' in text:
    marker = 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10'
    old_delay = 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {'
else:
    raise SystemExit('Stage 23A v10 or v11 must be installed before applying v12')

if old_delay not in text:
    raise SystemExit('Expected retry delay not found; no changes made')

text = text.replace(old_delay, 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {', 1)
text = text.replace(marker, 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V12', 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V12' "$GRID" || fail "v12 marker missing"
grep -Fq 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200' "$GRID" || fail "1.2-second retry delay missing"

pass "Stage 23A retry feedback is standardized at 1.2 seconds"
printf '[GRAYHAIRED-SITE23A] INFO: reload the GrayHaired child process to use the standardized timing.\n'
