#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-scroll-canvas-stage16"

fail() {
    printf '[GRAYHAIRED-PHOTO16-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$BACKUP" ]] || fail "rollback copy not found: $BACKUP"
cp -a "$BACKUP" "$GRID"
printf '[GRAYHAIRED-PHOTO16-ROLLBACK] PASS: restored exact pre-Stage-16 desktopGrid.js\n'
printf '[GRAYHAIRED-PHOTO16-ROLLBACK] INFO: reload only the GrayHaired child to return to the Stage 15 layout\n'
