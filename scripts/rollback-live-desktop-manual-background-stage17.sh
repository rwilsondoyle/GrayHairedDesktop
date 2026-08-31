#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-manual-background-stage17"

fail() {
    printf '[GRAYHAIRED-MANUAL17-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
[[ -f "$BACKUP" ]] || fail "Stage 17 rollback copy not found: $BACKUP"

cp -a "$BACKUP" "$GRID"
printf '[GRAYHAIRED-MANUAL17-ROLLBACK] PASS: restored pre-Stage-17 desktopGrid.js\n'
printf '[GRAYHAIRED-MANUAL17-ROLLBACK] INFO: reload only the GrayHaired child with:\n'
printf '  bash %s/GrayHairedDesktop/scripts/reload-grayhaired.sh\n' "$HOME"
