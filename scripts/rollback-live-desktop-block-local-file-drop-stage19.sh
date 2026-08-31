#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-block-local-file-drop-stage19"

fail() {
    printf '[GRAYHAIRED-DROP19-ROLLBACK] FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$BACKUP" ]] || fail "rollback copy not found: $BACKUP"
cp -a "$BACKUP" "$GRID"
printf '[GRAYHAIRED-DROP19-ROLLBACK] PASS: restored pre-Stage-19 desktopGrid.js\n'
printf '[GRAYHAIRED-DROP19-ROLLBACK] INFO: reload only the GrayHaired child with scripts/reload-grayhaired.sh\n'
