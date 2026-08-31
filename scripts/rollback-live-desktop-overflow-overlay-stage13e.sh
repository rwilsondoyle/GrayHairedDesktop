#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-overflow-overlay-stage13e"

fail() {
    printf '[GRAYHAIRED-OVERFLOW13E-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-OVERFLOW13E-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$BACKUP" ]] || fail "Stage 13E rollback copy not found: $BACKUP"

if ! grep -Fq 'GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E' "$GRID"; then
    pass "Stage 13E marker is already absent; nothing to roll back"
    exit 0
fi

cp -a "$BACKUP" "$GRID"

grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "restored file does not contain known-good Stage 11 marker"
if grep -Fq 'GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E' "$GRID"; then
    fail "Stage 13E marker remains after rollback"
fi
if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    fail "failed Stage 10 marker unexpectedly present after rollback"
fi
if grep -Fq 'GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12' "$GRID"; then
    fail "Stage 12 marker unexpectedly present after rollback"
fi

pass "restored exact pre-Stage-13E desktopGrid.js"
printf '[GRAYHAIRED-OVERFLOW13E-ROLLBACK] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child to return to the Stage 11 layout"
