#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-wallpaper-sync-stage6"
SETTINGS_BACKUP="$HOME/.config/grayhaired-live-desktop-wallpaper-backup.txt"

fail() {
    printf '[GRAYHAIRED-WALLPAPER6] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-WALLPAPER6] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-PHOTO-URL-CLEANUP-STAGE5C' "$GRID" || \
    fail "Stage 5C rotating-photo cache path is not installed"
command -v gsettings >/dev/null 2>&1 || fail "gsettings is not available"

if [[ ! -e "$SETTINGS_BACKUP" ]]; then
    mkdir -p "$(dirname "$SETTINGS_BACKUP")"
    {
        printf 'picture-uri='; gsettings get org.gnome.desktop.background picture-uri
        printf 'picture-uri-dark='; gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || printf "''\n"
        printf 'picture-options='; gsettings get org.gnome.desktop.background picture-options
    } > "$SETTINGS_BACKUP"
    pass "saved original GNOME wallpaper settings: $SETTINGS_BACKUP"
else
    pass "original GNOME wallpaper settings backup already exists: $SETTINGS_BACKUP"
fi

if grep -Fq 'GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6' "$GRID"; then
    pass "GNOME wallpaper sync Stage 6 is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved one-time rollback copy: $BACKUP"
else
    pass "rollback copy already exists: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

anchor = r'''                                        const localUri = localPhoto.get_uri();
                                        const panelCss = `.grayhaired-photo-continuation { ` +
'''

replacement = r'''                                        const localUri = localPhoto.get_uri();

                                        // GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6
                                        // The translucent Zorin taskbar can reveal the real
                                        // GNOME wallpaper beneath the GrayHaired desktop window.
                                        // Synchronize that wallpaper to the same cached active
                                        // photo so transparent shell surfaces visually match.
                                        // The user's original settings are backed up by the
                                        // installer script and can be restored separately.
                                        try {
                                            const wallpaperSettings = new Gio.Settings({
                                                schema_id: 'org.gnome.desktop.background'
                                            });
                                            wallpaperSettings.set_string('picture-uri', localUri);
                                            try {
                                                wallpaperSettings.set_string('picture-uri-dark', localUri);
                                            } catch (e) {
                                                // Some GNOME versions may not expose picture-uri-dark.
                                            }
                                            wallpaperSettings.set_string('picture-options', 'stretched');
                                            Gio.Settings.sync();
                                            print(`[GRAYHAIRED-WALLPAPER6] synced ${localUri}`);
                                        } catch (e) {
                                            printerr(`[GRAYHAIRED-WALLPAPER6] sync failed: ${e.message}`);
                                        }

                                        const panelCss = `.grayhaired-photo-continuation { ` +
'''

if anchor not in text:
    raise SystemExit("expected Stage 5 cached-photo success block not found; refusing to patch")

path.write_text(text.replace(anchor, replacement, 1), encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6' "$GRID" || \
    fail "Stage 6 marker missing after patch"
grep -Fq '[GRAYHAIRED-WALLPAPER6] synced' "$GRID" || \
    fail "Stage 6 synchronization log marker missing after patch"

pass "GNOME wallpaper synchronization Stage 6 installed"
printf '[GRAYHAIRED-WALLPAPER6] INFO: %s\n' \
    "reload only the GrayHaired child; the GNOME wallpaper should follow the active cached photo"
printf '[GRAYHAIRED-WALLPAPER6] INFO: %s\n' \
    "restore the original wallpaper later with scripts/restore-live-desktop-wallpaper-stage6.sh"
