#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-solid-wallpaper-sync-stage9"

fail() {
    printf '[GRAYHAIRED-SOLID9] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SOLID9] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID" || fail "Stage 2 solid blend is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID" || fail "Stage 3 photo detection is not installed"
grep -Fq 'const Gio = imports.gi.Gio;' "$GRID" || fail "Gio import is missing"

if grep -Fq 'GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9' "$GRID"; then
    pass "solid-page GNOME wallpaper sync Stage 9 is already installed"
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
text = path.read_text(encoding='utf-8')

# Remember the accepted Stage 2 color so the no-photo branch can synchronize
# the real GNOME background beneath translucent shell surfaces.
anchor = """                                this._liveBlendCssProvider.load_from_data(css);\n                                print(\n                                    `[GRAYHAIRED-BLEND] applied color=${dominant} ` +\n"""
replacement = """                                this._liveBlendCssProvider.load_from_data(css);\n                                // GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9\n                                // Preserve the accepted sampled color for the later\n                                // no-photo decision. This avoids changing GNOME's real\n                                // wallpaper until we know the page is not photographic.\n                                this._liveBlendDominantColor = dominant;\n                                print(\n                                    `[GRAYHAIRED-BLEND] applied color=${dominant} ` +\n"""
if anchor not in text:
    raise SystemExit('Stage 2 accepted-color anchor not found')
text = text.replace(anchor, replacement, 1)

no_photo = """                            if (!payload.ok || !payload.url) {\n                                print(`[GRAYHAIRED-PHOTO3] no-photo ${value.to_string()}`);\n                                return;\n                            }\n"""
no_photo_replacement = r'''                            if (!payload.ok || !payload.url) {
                                print(`[GRAYHAIRED-PHOTO3] no-photo ${value.to_string()}`);

                                // GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9
                                // A translucent Zorin taskbar reveals GNOME's real
                                // background. If the live page has no page-level photo,
                                // clear any stale photo left by a previous page and use
                                // the same accepted Automatic Blend color underneath.
                                // If the sampler did not produce a confident color, use
                                // a neutral charcoal fallback rather than stale artwork.
                                try {
                                    let solidColor = String(
                                        this._liveBlendDominantColor || 'rgb(48, 48, 48)'
                                    );
                                    const m = solidColor.match(
                                        /^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)/i
                                    );
                                    if (!m)
                                        throw new Error(`unsupported sampled color: ${solidColor}`);

                                    const toHex = n => Math.max(0, Math.min(255, Number(n)))
                                        .toString(16).padStart(2, '0');
                                    const hex = `#${toHex(m[1])}${toHex(m[2])}${toHex(m[3])}`;

                                    const wallpaperSettings = new Gio.Settings({
                                        schema_id: 'org.gnome.desktop.background'
                                    });
                                    wallpaperSettings.set_string('picture-uri', '');
                                    try {
                                        wallpaperSettings.set_string('picture-uri-dark', '');
                                    } catch (e) {
                                        // Optional on some GNOME versions.
                                    }
                                    wallpaperSettings.set_string('primary-color', hex);
                                    try {
                                        wallpaperSettings.set_string('secondary-color', hex);
                                    } catch (e) {
                                        // Optional on some schemas.
                                    }
                                    Gio.Settings.sync();
                                    print(
                                        `[GRAYHAIRED-SOLID9] synced color=${solidColor} ` +
                                        `hex=${hex}`
                                    );
                                } catch (e) {
                                    printerr(`[GRAYHAIRED-SOLID9] sync failed: ${e.message}`);
                                }
                                return;
                            }
'''
if no_photo not in text:
    raise SystemExit('Stage 3 no-photo branch not found')
text = text.replace(no_photo, no_photo_replacement, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9' "$GRID" || fail "Stage 9 marker missing after patch"
grep -Fq '[GRAYHAIRED-SOLID9] synced color=' "$GRID" || fail "Stage 9 sync log marker missing"

pass "solid-page GNOME wallpaper synchronization Stage 9 installed"
printf '[GRAYHAIRED-SOLID9] INFO: %s\n' \
    "reload only the GrayHaired child; no-photo pages should clear stale photos and match the sampled solid color"
