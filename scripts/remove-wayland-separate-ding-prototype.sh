#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
TEST_EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"

echo "=== REMOVE SEPARATE WAYLAND DING PROTOTYPE ==="

gnome-extensions disable "$TEST_UUID" >/dev/null 2>&1 || true
rm -rf "$TEST_EXT"

gnome-extensions enable "$SYSTEM_UUID" >/dev/null 2>&1 || true

cat <<EOF
Removed separate GrayHairedDesktop Wayland prototype:
  $TEST_EXT

Requested re-enable of normal Zorin desktop icons:
  $SYSTEM_UUID

If the normal icons do not reappear immediately, log out and back into Wayland.
A reboot is not required.
EOF
