#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-manual-background-stage17"

fail() {
    printf '[GRAYHAIRED-MANUAL17] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-MANUAL17] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID" || fail "Automatic Blend Stage 2 is not installed"
grep -Fq 'GRAYHAIRED-SOLID-WALLPAPER-SYNC-STAGE9' "$GRID" || fail "solid wallpaper sync Stage 9 is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16' "$GRID" || fail "photo scroll canvas Stage 16 is not installed"

if grep -Fq 'GRAYHAIRED-MANUAL-BACKGROUND-STAGE17' "$GRID"; then
    pass "Stage 17 manual background override is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

# Ensure GLib is available for the per-user config path.
if 'const GLib = imports.gi.GLib;' not in text:
    gio_anchor = 'const Gio = imports.gi.Gio;\n'
    if gio_anchor not in text:
        raise SystemExit('Gio import anchor not found')
    text = text.replace(gio_anchor, gio_anchor + 'const GLib = imports.gi.GLib;\n', 1)

setup_anchor = """        this._liveBlendStyleContext.add_provider(
            this._liveBlendCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER
"""
setup_replacement = """        this._liveBlendStyleContext.add_provider(
            this._liveBlendCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // GRAYHAIRED-MANUAL-BACKGROUND-STAGE17
        // Read a tiny user-local JSON file. Missing/invalid files deliberately
        // fall back to the already proven Automatic Blend behavior.
        this._grayhairedBackgroundPreference = () => {
            const fallback = {mode: 'automatic', color: '#41464C'};
            try {
                const configPath = GLib.build_filenamev([
                    GLib.get_user_config_dir(),
                    'grayhaired-live-desktop',
                    'background.json'
                ]);
                const file = Gio.File.new_for_path(configPath);
                if (!file.query_exists(null))
                    return fallback;
                const [ok, contents] = file.load_contents(null);
                if (!ok)
                    return fallback;
                const value = JSON.parse(new TextDecoder().decode(contents));
                const mode = String(value.mode || '').toLowerCase();
                const color = String(value.color || '').toUpperCase();
                if (mode === 'manual' && /^#[0-9A-F]{6}$/.test(color))
                    return {mode: 'manual', color};
                return fallback;
            } catch (e) {
                printerr(`[GRAYHAIRED-MANUAL17] config read failed: ${e.message}`);
                return fallback;
            }
        };

        // GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER
"""
if setup_anchor not in text:
    raise SystemExit('Stage 2 setup anchor not found')
text = text.replace(setup_anchor, setup_replacement, 1)

# Manual mode overrides only the accepted color path. Automatic mode remains
# byte-for-byte equivalent in its confidence and validation rules.
old_logic = """                                const dominant = payload.dominant;
                                const dominantCount = Number(payload.dominantCount || 0);
                                const sampleCount = Number(payload.sampleCount || 0);
                                const confidence = sampleCount > 0 ? dominantCount / sampleCount : 0;

                                // Stage 2 deliberately accepts only ordinary CSS rgb/rgba
                                // values and requires a clear majority before painting.
                                const validColor = typeof dominant === 'string' &&
                                    /^rgba?\\([^)]*\\)$/i.test(dominant);

                                if (!validColor || confidence < 0.60) {
                                    print(
                                        `[GRAYHAIRED-BLEND] fallback: dominant=${dominant} ` +
                                        `confidence=${confidence.toFixed(3)}`
                                    );
                                    return;
                                }

                                const css = `.grayhaired-auto-blend-panel { ` +
                                    `background-color: ${dominant}; }`;
                                this._liveBlendCssProvider.load_from_data(css);
"""
new_logic = """                                const dominant = payload.dominant;
                                const dominantCount = Number(payload.dominantCount || 0);
                                const sampleCount = Number(payload.sampleCount || 0);
                                const confidence = sampleCount > 0 ? dominantCount / sampleCount : 0;
                                const backgroundPreference = this._grayhairedBackgroundPreference();
                                const manualMode = backgroundPreference.mode === 'manual';

                                // Stage 2 deliberately accepts only ordinary CSS rgb/rgba
                                // values and requires a clear majority before painting.
                                const validColor = typeof dominant === 'string' &&
                                    /^rgba?\\([^)]*\\)$/i.test(dominant);

                                if (!manualMode && (!validColor || confidence < 0.60)) {
                                    print(
                                        `[GRAYHAIRED-BLEND] fallback: dominant=${dominant} ` +
                                        `confidence=${confidence.toFixed(3)}`
                                    );
                                    return;
                                }

                                const effectiveColor = manualMode
                                    ? backgroundPreference.color
                                    : dominant;
                                const css = `.grayhaired-auto-blend-panel { ` +
                                    `background-color: ${effectiveColor}; }`;
                                this._liveBlendCssProvider.load_from_data(css);
                                if (manualMode)
                                    print(`[GRAYHAIRED-MANUAL17] applied color=${effectiveColor}`);
"""
if old_logic not in text:
    raise SystemExit('Stage 2 accepted-color logic anchor not found')
text = text.replace(old_logic, new_logic, 1)

# Stage 9 stores the color for the no-photo backing sync. Store the effective
# manual color, not the sampled page color, when manual mode is selected.
old_store = """                                this._liveBlendDominantColor = dominant;
                                print(
                                    `[GRAYHAIRED-BLEND] applied color=${dominant} ` +
"""
new_store = """                                this._liveBlendDominantColor = effectiveColor;
                                print(
                                    `[GRAYHAIRED-BLEND] applied color=${effectiveColor} ` +
"""
if old_store not in text:
    raise SystemExit('Stage 9 accepted-color store anchor not found')
text = text.replace(old_store, new_store, 1)

# Before the normal photo/no-photo split, manual mode wins. This prevents a
# photographic page from repainting the icon pane and synchronizes GNOME's real
# backing color so translucent shell areas match the chosen manual color.
photo_anchor = """                            if (!payload.ok || !payload.url) {
                                print(`[GRAYHAIRED-PHOTO3] no-photo ${value.to_string()}`);
"""
manual_branch = r'''                            const backgroundPreference = this._grayhairedBackgroundPreference();
                            if (backgroundPreference.mode === 'manual') {
                                const solidColor = backgroundPreference.color;
                                try {
                                    this._liveBlendDominantColor = solidColor;
                                    const hex = solidColor.toLowerCase();
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
                                        `[GRAYHAIRED-MANUAL17] photo override color=${solidColor} ` +
                                        `hex=${hex}`
                                    );
                                } catch (e) {
                                    printerr(`[GRAYHAIRED-MANUAL17] backing sync failed: ${e.message}`);
                                }
                                return;
                            }

                            if (!payload.ok || !payload.url) {
                                print(`[GRAYHAIRED-PHOTO3] no-photo ${value.to_string()}`);
'''
if photo_anchor not in text:
    raise SystemExit('Stage 3 photo decision anchor not found')
text = text.replace(photo_anchor, manual_branch, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-MANUAL-BACKGROUND-STAGE17' "$GRID" || fail "Stage 17 marker missing after patch"
grep -Fq '_grayhairedBackgroundPreference' "$GRID" || fail "Stage 17 preference reader missing"
grep -Fq '[GRAYHAIRED-MANUAL17] applied color=' "$GRID" || fail "Stage 17 apply log missing"
grep -Fq '[GRAYHAIRED-MANUAL17] photo override color=' "$GRID" || fail "Stage 17 photo override log missing"

pass "Stage 17 manual background override installed"
printf '[GRAYHAIRED-MANUAL17] INFO: choose a test color with scripts/set-live-desktop-background.sh\n'
printf '[GRAYHAIRED-MANUAL17] INFO: reload only the GrayHaired child after changing the mode/color\n'
