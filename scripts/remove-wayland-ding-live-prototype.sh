#!/usr/bin/env bash
set -euo pipefail

UUID="zorin-desktop-icons@zorinos.com"
USER_ROOT="$HOME/.local/share/gnome-shell/extensions"
USER_EXT="$USER_ROOT/$UUID"
BACKUP_EXT="$USER_ROOT/${UUID}.grayhaired-backup"

if [[ -d "$USER_EXT" ]]; then
    rm -rf "$USER_EXT"
    echo "Removed GrayHairedDesktop user-local Zorin extension prototype."
else
    echo "No user-local prototype directory found."
fi

if [[ -d "$BACKUP_EXT" ]]; then
    mv "$BACKUP_EXT" "$USER_EXT"
    echo "Restored the user-local Zorin extension that existed before the prototype."
else
    echo "No previous user-local override existed; the system Zorin extension will be used."
fi

cat <<EOF

Cleanup complete.
Log out and log back in for GNOME Shell to reload the extension.
A reboot is NOT required.
EOF
