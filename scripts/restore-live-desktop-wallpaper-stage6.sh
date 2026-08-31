#!/usr/bin/env bash
set -euo pipefail

SETTINGS_BACKUP="$HOME/.config/grayhaired-live-desktop-wallpaper-backup.txt"

fail() {
    printf '[GRAYHAIRED-WALLPAPER6-RESTORE] FAIL: %s\n' "$*" >&2
    exit 1
}

[[ -f "$SETTINGS_BACKUP" ]] || fail "wallpaper settings backup not found: $SETTINGS_BACKUP"

picture_uri="$(sed -n 's/^picture-uri=//p' "$SETTINGS_BACKUP")"
picture_uri_dark="$(sed -n 's/^picture-uri-dark=//p' "$SETTINGS_BACKUP")"
picture_options="$(sed -n 's/^picture-options=//p' "$SETTINGS_BACKUP")"

[[ -n "$picture_uri" ]] || fail "saved picture-uri is missing"
[[ -n "$picture_options" ]] || fail "saved picture-options is missing"

gsettings set org.gnome.desktop.background picture-uri "$picture_uri"
if [[ -n "$picture_uri_dark" ]]; then
    gsettings set org.gnome.desktop.background picture-uri-dark "$picture_uri_dark" 2>/dev/null || true
fi
gsettings set org.gnome.desktop.background picture-options "$picture_options"

printf '[GRAYHAIRED-WALLPAPER6-RESTORE] PASS: restored original GNOME wallpaper settings\n'
