#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-arbitrary-link-handoff-stage8"

fail() {
    printf '[GRAYHAIRED-LINK8-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LINK8-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$BACKUP" ]] || fail "Stage 8 rollback copy not found: $BACKUP"

cp -a "$BACKUP" "$GRID"

if grep -Fq 'GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8' "$GRID"; then
    fail "Stage 8 marker still present after rollback"
fi

pass "restored the exact pre-Stage-8 WebKit handoff"
printf '[GRAYHAIRED-LINK8-ROLLBACK] INFO: %s\n' \
    "reload only the GrayHaired child after any additional app-code patches"
