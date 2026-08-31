#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/grayhaired-live-desktop-background.desktop"
LAUNCHER="$SCRIPT_DIR/open-live-desktop-background-settings.sh"

fail() {
    printf '[GRAYHAIRED-BG-LAUNCHER] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-BG-LAUNCHER] PASS: %s\n' "$*"
}

[[ -f "$LAUNCHER" ]] || fail "settings launcher is missing: $LAUNCHER"
mkdir -p "$APPLICATIONS_DIR"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=My Desktop Background
Comment=Choose Automatic Blend or a manual desktop background color
Exec=/bin/bash $LAUNCHER
Icon=preferences-desktop-wallpaper
Terminal=false
Categories=Settings;Utility;
Keywords=desktop;background;color;wallpaper;grayhaired;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

pass "installed Zorin application-menu entry: $DESKTOP_FILE"
printf '[GRAYHAIRED-BG-LAUNCHER] INFO: search the app menu for "My Desktop Background".\n'
