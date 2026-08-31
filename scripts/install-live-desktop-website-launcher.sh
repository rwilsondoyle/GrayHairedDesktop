#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/grayhaired-live-desktop-website.desktop"
LAUNCHER="$SCRIPT_DIR/open-live-desktop-website-settings.sh"

fail() {
    printf '[GRAYHAIRED-SITE21] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE21] PASS: %s\n' "$*"
}

[[ -f "$LAUNCHER" ]] || fail "website settings launcher is missing: $LAUNCHER"
mkdir -p "$APPLICATIONS_DIR"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=My Desktop Website
Comment=Choose the website shown on the GrayHaired live desktop
Exec=/bin/bash $LAUNCHER
Icon=web-browser
Terminal=false
Categories=Settings;Utility;
Keywords=desktop;website;web;browser;grayhaired;
StartupNotify=true
EOF

chmod 0644 "$DESKTOP_FILE"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi

pass "installed Zorin application-menu entry: $DESKTOP_FILE"
printf '[GRAYHAIRED-SITE21] INFO: search the app menu for "My Desktop Website".\n'
