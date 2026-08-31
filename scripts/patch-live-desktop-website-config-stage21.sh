#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-website-config-stage21"

fail() {
    printf '[GRAYHAIRED-SITE21] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE21] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-CREATE-HANDOFF-STAGE20' "$GRID" || fail "Stage 20 modern-site handoff is missing"
grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID" || fail "Stage 19 local-file guard is missing"

if grep -Fq 'GRAYHAIRED-WEBSITE-CONFIG-STAGE21' "$GRID"; then
    pass "Stage 21 website config is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

if "const GLib = imports.gi.GLib;" not in text:
    anchor = "const Gio = imports.gi.Gio;\n"
    if anchor not in text:
        raise SystemExit("Gio import anchor not found")
    text = text.replace(anchor, anchor + "const GLib = imports.gi.GLib;\n", 1)

if "const ByteArray = imports.byteArray;" not in text:
    import_anchor = "const GLib = imports.gi.GLib;\n"
    text = text.replace(import_anchor, import_anchor + "const ByteArray = imports.byteArray;\n", 1)

pattern = re.compile(r"\s*this\._liveWebView\.load_uri\('https?://[^']+'\);", re.MULTILINE)
match = pattern.search(text)
if not match:
    raise SystemExit("live WebView load_uri call not found")

replacement = r'''
        // GRAYHAIRED-WEBSITE-CONFIG-STAGE21
        // Read the selected live-desktop website from a user config file.
        // A missing, malformed, or non-web URL safely falls back to desktop-d.
        let liveDesktopUrl = 'https://grayhaired.tech/desktop-d';
        try {
            const siteConfigPath = GLib.build_filenamev([
                GLib.get_user_config_dir(),
                'grayhaired-live-desktop',
                'site.json',
            ]);
            const [ok, contents] = GLib.file_get_contents(siteConfigPath);
            if (ok) {
                const payload = JSON.parse(ByteArray.toString(contents));
                const configuredUrl = String(payload.url || '').trim();
                if (configuredUrl.startsWith('https://') ||
                    configuredUrl.startsWith('http://')) {
                    liveDesktopUrl = configuredUrl;
                }
            }
        } catch (e) {
            print(`[GRAYHAIRED-SITE21] config fallback: ${e.message}`);
        }
        print(`[GRAYHAIRED-SITE21] loading ${liveDesktopUrl}`);
        this._liveWebView.load_uri(liveDesktopUrl);'''

text = text[:match.start()] + replacement + text[match.end():]
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-WEBSITE-CONFIG-STAGE21' "$GRID" || fail "Stage 21 marker missing after patch"
grep -Fq '[GRAYHAIRED-SITE21] loading' "$GRID" || fail "Stage 21 load diagnostic missing"

pass "Stage 21 persistent website config installed"
printf '[GRAYHAIRED-SITE21] INFO: choose a website with scripts/set-live-desktop-website.sh, then reload only the GrayHaired child.\n'
