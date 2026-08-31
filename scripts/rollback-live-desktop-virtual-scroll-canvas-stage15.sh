#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-virtual-scroll-canvas-stage15"

fail() {
    printf '[GRAYHAIRED-SCROLL15-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SCROLL15-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$BACKUP" ]] || fail "Stage 15 rollback copy not found: $BACKUP"

if ! grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID"; then
    fail "Stage 15 marker is not installed; refusing to overwrite current desktopGrid.js"
fi

tmp="$GRID.rollback-stage15.tmp"
cp -a "$BACKUP" "$tmp"
mv -f "$tmp" "$GRID"

if grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID"; then
    fail "Stage 15 marker still present after restore"
fi

grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "restored file does not contain known-good Stage 11 marker"

pass "restored exact pre-Stage-15 desktopGrid.js"
printf '[GRAYHAIRED-SCROLL15-ROLLBACK] INFO: %s\n' \
    "reload only the GrayHaired child to return to the Stage 11 layout"
