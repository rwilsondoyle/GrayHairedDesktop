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
    grep -Fq 'this._liveWebView.load_uri(liveDesktopUrl);' "$GRID" || \
        fail "Stage 21 marker exists but configured load_uri call is missing"
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

# Replace the one actual startup load_uri call, regardless of whether an older
# controlled test left desktop-c, desktop-d, MSN, DuckDuckGo, or another HTTP(S)
# URL hard-coded there.
pattern = re.compile(
    r"(?m)^(?P<indent>\s*)this\._liveWebView\.load_uri\('(?P<url>https?://[^']+)'\);\s*$"
)
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit(
        f"Expected exactly one hard-coded live WebView startup load_uri; found {len(matches)}"
    )

match = matches[0]
indent = match.group('indent')
old_url = match.group('url')
print(f"[GRAYHAIRED-SITE21] replacing hard-coded startup URL: {old_url}")

block_lines = [
    "// GRAYHAIRED-WEBSITE-CONFIG-STAGE21",
    "// Read the selected live-desktop website from a user config file.",
    "// A missing, malformed, or non-web URL safely falls back to desktop-d.",
    "let liveDesktopUrl = 'https://grayhaired.tech/desktop-d';",
    "try {",
    "    const siteConfigPath = GLib.build_filenamev([",
    "        GLib.get_user_config_dir(),",
    "        'grayhaired-live-desktop',",
    "        'site.json',",
    "    ]);",
    "    const [ok, contents] = GLib.file_get_contents(siteConfigPath);",
    "    if (ok) {",
    "        const payload = JSON.parse(ByteArray.toString(contents));",
    "        const configuredUrl = String(payload.url || '').trim();",
    "        if (configuredUrl.startsWith('https://') ||",
    "            configuredUrl.startsWith('http://')) {",
    "            liveDesktopUrl = configuredUrl;",
    "        }",
    "    }",
    "} catch (e) {",
    "    print(`[GRAYHAIRED-SITE21] config fallback: ${e.message}`);",
    "}",
    "print(`[GRAYHAIRED-SITE21] loading ${liveDesktopUrl}`);",
    "this._liveWebView.load_uri(liveDesktopUrl);",
]
replacement = "\n".join(indent + line for line in block_lines)
text = text[:match.start()] + replacement + text[match.end():]
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-WEBSITE-CONFIG-STAGE21' "$GRID" || fail "Stage 21 marker missing after patch"
grep -Fq 'this._liveWebView.load_uri(liveDesktopUrl);' "$GRID" || fail "Stage 21 configured load_uri call missing"
grep -Fq '[GRAYHAIRED-SITE21] loading' "$GRID" || fail "Stage 21 load diagnostic missing"

if grep -Eq "^[[:space:]]*this\._liveWebView\.load_uri\('https?://" "$GRID"; then
    fail "a hard-coded HTTP(S) startup load_uri still remains"
fi

pass "Stage 21 persistent website config installed and startup URL is config-driven"
printf '[GRAYHAIRED-SITE21] INFO: reload only the GrayHaired child; it will read ~/.config/grayhaired-live-desktop/site.json.\n'
