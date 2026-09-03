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

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' "$GRID" || \
    fail "Stage 23A v10 must be installed before applying the one-second timing update"

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

old = "GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {"
new = "GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, () => {"

if old not in text:
    raise SystemExit('Stage 23A v10 1200ms retry delay not found; no changes made')

text = text.replace(old, new, 1)
text = text.replace(
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10',
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V11',
    1,
)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V11' "$GRID" || fail "v11 marker missing"
grep -Fq 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000' "$GRID" || fail "one-second retry delay missing"

pass "Stage 23A retry status now remains visible for exactly one second before retrying"
printf '[GRAYHAIRED-SITE23A] INFO: reload the GrayHaired child process to use the new timing.\n'
