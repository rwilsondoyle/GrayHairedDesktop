#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-vertical-scroll-stage14"

fail() {
    printf '[GRAYHAIRED-SCROLL14-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SCROLL14-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$BACKUP" ]] || fail "Stage 14 rollback copy not found: $BACKUP"

if ! grep -Fq 'GRAYHAIRED-VERTICAL-SCROLL-STAGE14' "$GRID"; then
    pass "Stage 14 marker is already absent; nothing to roll back"
    exit 0
fi

cp -a "$BACKUP" "$GRID"

grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "restored file does not contain known-good Stage 11 marker"
if grep -Fq 'GRAYHAIRED-VERTICAL-SCROLL-STAGE14' "$GRID"; then
    fail "Stage 14 marker remains after rollback"
fi
if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    fail "failed Stage 10 marker unexpectedly present after rollback"
fi
if grep -Fq 'GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12' "$GRID"; then
    fail "Stage 12 marker unexpectedly present after rollback"
fi
if grep -Fq 'GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E' "$GRID"; then
    fail "failed Stage 13E marker unexpectedly present after rollback"
fi

pass "restored exact pre-Stage-14 desktopGrid.js"
printf '[GRAYHAIRED-SCROLL14-ROLLBACK] INFO: %s\n' \
    "reload only the GrayHaired child to return to the Stage 11 layout"
