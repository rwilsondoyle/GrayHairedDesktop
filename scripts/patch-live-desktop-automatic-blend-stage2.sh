#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-automatic-blend-stage2"

fail() {
    printf '[GRAYHAIRED-BLEND] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-BLEND] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER' "$GRID" || \
    fail "Stage 1 Automatic Blend sampler is not installed"
grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" || \
    fail "known-good live geometry marker not found"

if grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID"; then
    pass "Automatic Blend Stage 2 is already installed"
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

setup_anchor = """        // GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER\n        // Stage 1 is intentionally read-only. After the page finishes loading,\n"""
setup_replacement = """        // GRAYHAIRED-AUTOMATIC-BLEND-STAGE2\n        // Reversible visual experiment: color only the real DING icon pane\n        // from the dominant WebKit left-edge sample. Geometry, focus, input,\n        // icon placement, and WebKit content remain unchanged.\n        this._liveBlendCssProvider = new Gtk.CssProvider();\n        this._liveBlendStyleContext = this._eventBox.get_style_context();\n        this._liveBlendStyleContext.add_class('grayhaired-auto-blend-panel');\n        this._liveBlendStyleContext.add_provider(\n            this._liveBlendCssProvider,\n            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION\n        );\n\n        // GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER\n        // Stage 1 samples the rendered WebKit edge after the page finishes loading.\n"""
if setup_anchor not in text:
    raise SystemExit("Automatic Blend sampler setup anchor not found")
text = text.replace(setup_anchor, setup_replacement, 1)

callback_anchor = """                            const value = source.evaluate_javascript_finish(result);\n                            print(`[GRAYHAIRED-BLEND-SAMPLE] ${value.to_string()}`);\n"""
callback_replacement = r'''                            const value = source.evaluate_javascript_finish(result);
                            const payloadText = value.to_string();
                            print(`[GRAYHAIRED-BLEND-SAMPLE] ${payloadText}`);

                            try {
                                const payload = JSON.parse(payloadText);
                                const dominant = payload.dominant;
                                const dominantCount = Number(payload.dominantCount || 0);
                                const sampleCount = Number(payload.sampleCount || 0);
                                const confidence = sampleCount > 0 ? dominantCount / sampleCount : 0;

                                // Stage 2 deliberately accepts only ordinary CSS rgb/rgba
                                // values and requires a clear majority before painting.
                                const validColor = typeof dominant === 'string' &&
                                    /^rgba?\([^)]*\)$/i.test(dominant);

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
                                print(
                                    `[GRAYHAIRED-BLEND] applied color=${dominant} ` +
                                    `confidence=${confidence.toFixed(3)} ` +
                                    `samples=${dominantCount}/${sampleCount}`
                                );
                            } catch (e) {
                                printerr(`[GRAYHAIRED-BLEND] apply failed: ${e.message}`);
                            }
'''
if callback_anchor not in text:
    raise SystemExit("Automatic Blend sampler callback anchor not found")
text = text.replace(callback_anchor, callback_replacement, 1)

path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID" || \
    fail "Stage 2 marker missing after patch"
grep -Fq 'grayhaired-auto-blend-panel' "$GRID" || \
    fail "Stage 2 CSS class missing after patch"
grep -Fq '[GRAYHAIRED-BLEND] applied color=' "$GRID" || \
    fail "Stage 2 applied-color log missing after patch"

pass "Automatic Blend Stage 2 visual experiment installed"
printf '[GRAYHAIRED-BLEND] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child; the icon pane should adopt the sampled page-edge color"
