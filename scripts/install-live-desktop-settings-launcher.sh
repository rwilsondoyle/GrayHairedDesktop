#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/grayhaired-live-desktop-settings.desktop"
LAUNCHER="$SCRIPT_DIR/open-live-desktop-settings.sh"

fail() {
    printf '[GRAYHAIRED-SETTINGS22] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SETTINGS22] PASS: %s\n' "$*"
}

[[ -f "$LAUNCHER" ]] || fail "settings hub launcher is missing: $LAUNCHER"
mkdir -p "$APPLICATIONS_DIR"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=My Desktop Settings
Comment=Change the GrayHaired live desktop website and background
Exec=/bin/bash $LAUNCHER
Icon=preferences-system
Terminal=false
Categories=Settings;Utility;
Keywords=desktop;website;background;grayhaired;settings;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

pass "installed Zorin application-menu entry: $DESKTOP_FILE"
printf '[GRAYHAIRED-SETTINGS22] INFO: search the app menu for "My Desktop Settings".\n'
