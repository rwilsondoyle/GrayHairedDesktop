#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-tight-width-stage18"

fail() {
    printf '[GRAYHAIRED-PANE18-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PANE18-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$BACKUP" ]] || fail "Stage 18 rollback copy is missing: $BACKUP"
cp -a "$BACKUP" "$GRID"

grep -Fq 'GRAYHAIRED-TIGHT-WIDTH-STAGE18' "$GRID" && fail "Stage 18 marker still present after rollback"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || fail "Stage 11 marker missing after rollback"
grep -Fq 'const liveIconStripMin = 240;' "$GRID" || fail "Stage 11 240px minimum not restored"
grep -Fq 'GRAYHAIRED-MANUAL-BACKGROUND-STAGE17' "$GRID" || fail "Stage 17 background controls were not preserved"

pass "restored the pre-Stage18 working desktopGrid.js"
printf '[GRAYHAIRED-PANE18-ROLLBACK] INFO: reload only the GrayHaired child to return to the 240px Stage 11 minimum.\n'
