#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-overflow-control@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"

pass() {
    printf '[GRAYHAIRED-OVERFLOW13F-ROLLBACK] PASS: %s\n' "$*"
}

gnome-extensions disable "$UUID" >/dev/null 2>&1 || true
rm -rf "$EXT"
pass "Stage 13F helper extension removed"
printf '[GRAYHAIRED-OVERFLOW13F-ROLLBACK] INFO: %s\n' \
    "The main GrayHaired Live Desktop extension was not changed."
