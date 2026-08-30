#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-continuation-stage3"
PHOTO_URL="https://grayhaired.tech/desktop-c/images/FL-VA.png"

fail() {
    printf '[GRAYHAIRED-PHOTO3] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO3] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID" || \
    fail "Automatic Blend Stage 2 is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC' "$GRID" || \
    fail "photo diagnostic marker not found"
grep -Fq "https://grayhaired.tech/desktop-c" "$GRID" || \
    fail "installed live URL is not desktop-c"

if grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID"; then
    pass "photo continuation Stage 3 is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved one-time rollback copy: $BACKUP"
else
    pass "rollback copy already exists: $BACKUP"
fi

python3 - "$GRID" "$PHOTO_URL" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
photo_url = sys.argv[2]
text = path.read_text(encoding="utf-8")

anchor = """        // GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC\n"""
if anchor not in text:
    raise SystemExit("photo diagnostic anchor not found")

setup = f"""        // GRAYHAIRED-PHOTO-CONTINUATION-STAGE3\n        // Reversible photographic continuation experiment for desktop-c.\n        // Render the same photo across the full GTK desktop width, then shift\n        // the WebKit body background left by the live DING icon-pane width.\n        // This changes appearance only; DING geometry and input are untouched.\n        this._livePhotoCssProvider = new Gtk.CssProvider();\n        this._livePhotoStyleContext = this._eventBox.get_style_context();\n        this._livePhotoStyleContext.add_class('grayhaired-photo-continuation');\n        this._livePhotoStyleContext.add_provider(\n            this._livePhotoCssProvider,\n            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION\n        );\n\n"""
text = text.replace(anchor, setup + anchor, 1)

callback_anchor = """            if (loadEvent !== WebKit2.LoadEvent.FINISHED)\n                return;\n\n            const photoDiagnosticScript = `(() => {\n"""
if callback_anchor not in text:
    raise SystemExit("photo load callback anchor not found")

callback_replacement = f"""            if (loadEvent !== WebKit2.LoadEvent.FINISHED)\n                return;\n\n            try {{\n                const fullWidth = Math.max(1, this._liveLayout.get_allocated_width());\n                const fullHeight = Math.max(1, this._liveLayout.get_allocated_height());\n                const iconWidth = this._liveIconBoundary\n                    ? Math.max(1, this._liveIconBoundary.get_allocated_width())\n                    : Math.max(1, this._eventBox.get_allocated_width());\n\n                const panelCss = `.grayhaired-photo-continuation {{ ` +\n                    `background-image: url(\\\"{photo_url}\\\"); ` +\n                    `background-repeat: no-repeat; ` +\n                    `background-size: ${{fullWidth}}px ${{fullHeight}}px; ` +\n                    `background-position: 0px 0px; }}`;\n                this._livePhotoCssProvider.load_from_data(panelCss);\n\n                const webPhotoScript = `(() => {{\n                    if (!document.body) return 'no-body';\n                    document.body.style.backgroundImage = 'url(\\\"{photo_url}\\\")';\n                    document.body.style.backgroundRepeat = 'no-repeat';\n                    document.body.style.backgroundAttachment = 'fixed';\n                    document.body.style.backgroundSize = '${{fullWidth}}px ${{fullHeight}}px';\n                    document.body.style.backgroundPosition = '-${{iconWidth}}px 0px';\n                    return JSON.stringify({{fullWidth:${{fullWidth}}, fullHeight:${{fullHeight}}, iconWidth:${{iconWidth}}}});\n                }})()`;\n\n                webView.evaluate_javascript(\n                    webPhotoScript, -1, null, null, null,\n                    (source, result) => {{\n                        try {{\n                            const value = source.evaluate_javascript_finish(result);\n                            print(`[GRAYHAIRED-PHOTO3] applied ${{value.to_string()}}`);\n                        }} catch (e) {{\n                            printerr(`[GRAYHAIRED-PHOTO3] WebKit apply failed: ${{e.message}}`);\n                        }}\n                    }}\n                );\n            }} catch (e) {{\n                printerr(`[GRAYHAIRED-PHOTO3] setup failed: ${{e.message}}`);\n            }}\n\n            const photoDiagnosticScript = `(() => {{\n"""
text = text.replace(callback_anchor, callback_replacement, 1)

path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID" || \
    fail "Stage 3 marker missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO3] applied' "$GRID" || \
    fail "Stage 3 apply log missing after patch"

pass "photographic continuation Stage 3 installed"
printf '[GRAYHAIRED-PHOTO3] INFO: %s\n' \
    "reload only the GrayHaired child; the beach photo should continue behind the icon pane"
