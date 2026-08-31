#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APP_DIR/grayhaired-live-desktop-website.desktop"

mkdir -p "$APP_DIR"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=My Desktop Website
Comment=Choose the website shown on the GrayHaired live desktop
Exec=bash "$SCRIPT_DIR/open-live-desktop-website-settings.sh"
Icon=preferences-system
Terminal=false
Categories=Settings;Utility;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"
printf '[GRAYHAIRED-SITE21] PASS: installed application-menu entry: %s\n' "$DESKTOP_FILE"
