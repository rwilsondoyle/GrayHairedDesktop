#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
MANAGER="$EXT/app/desktopManager.js"
GRID_BACKUP="$GRID.pre-fixed-scroll-pane-stage10"
MANAGER_BACKUP="$MANAGER.pre-fixed-scroll-pane-stage10"

fail() {
    printf '[GRAYHAIRED-PANE10-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PANE10-ROLLBACK] PASS: %s\n' "$*"
}

[[ -f "$GRID_BACKUP" ]] || fail "desktopGrid Stage 10 backup missing: $GRID_BACKUP"
[[ -f "$MANAGER_BACKUP" ]] || fail "desktopManager Stage 10 backup missing: $MANAGER_BACKUP"

cp -a "$GRID_BACKUP" "$GRID"
cp -a "$MANAGER_BACKUP" "$MANAGER"

if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    fail "Stage 10 marker still present after rollback"
fi

grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" || \
    fail "known-good manager-synced geometry marker missing after rollback"
grep -Fq 'GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7' "$GRID" || \
    fail "known-good photo live-reflow marker missing after rollback"
grep -Fq 'GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9' "$GRID" || \
    fail "known-good solid wallpaper-sync marker missing after rollback"

pass "restored exact pre-Stage-10 desktopGrid.js and desktopManager.js"
printf '[GRAYHAIRED-PANE10-ROLLBACK] INFO: reload only the GrayHaired child with:\n'
printf '  bash %s/scripts/reload-grayhaired.sh\n' "$HOME/GrayHairedDesktop"
