#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-automatic-blend-sampler"

fail() {
    printf '[GRAYHAIRED-BLEND] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-BLEND] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'this._liveWebView = new WebKit2.WebView();' "$GRID" || \
    fail "live WebKit view marker not found"
grep -Fq 'GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE' "$GRID" || \
    fail "known-good live geometry marker not found"

if grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER' "$GRID"; then
    pass "Automatic Blend sampler is already installed"
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

anchor = """        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');\n        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n"""

replacement = r'''        // GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER
        // Stage 1 is intentionally read-only. After the page finishes loading,
        // inspect a set of points near the rendered WebKit left edge and report
        // the most common non-transparent CSS background color. Nothing here
        // changes DING geometry, WebKit appearance, wallpaper, focus, or input.
        this.connectSignal(this._liveWebView, 'load-changed', (webView, loadEvent) => {
            if (loadEvent !== WebKit2.LoadEvent.FINISHED)
                return;

            const blendSamplerScript = `(() => {
                const width = Math.max(1, window.innerWidth || 1);
                const height = Math.max(1, window.innerHeight || 1);
                const xs = [2, 6, 12, 20, 28].filter(x => x < width);
                const ys = [0.08, 0.20, 0.35, 0.50, 0.65, 0.80, 0.92]
                    .map(f => Math.min(height - 1, Math.max(0, Math.round(height * f))));

                function normalizeColor(value) {
                    if (!value)
                        return null;
                    const color = String(value).trim().toLowerCase();
                    if (!color || color === 'transparent' ||
                        color === 'rgba(0, 0, 0, 0)' || color === 'rgba(0,0,0,0)')
                        return null;
                    return color;
                }

                function backgroundAt(x, y) {
                    let node = document.elementFromPoint(x, y);
                    while (node && node.nodeType === 1) {
                        const color = normalizeColor(getComputedStyle(node).backgroundColor);
                        if (color)
                            return color;
                        node = node.parentElement;
                    }

                    for (const fallback of [document.body, document.documentElement]) {
                        if (!fallback)
                            continue;
                        const color = normalizeColor(getComputedStyle(fallback).backgroundColor);
                        if (color)
                            return color;
                    }
                    return null;
                }

                const samples = [];
                const counts = Object.create(null);
                for (const x of xs) {
                    for (const y of ys) {
                        const color = backgroundAt(x, y);
                        samples.push({x, y, color});
                        if (color)
                            counts[color] = (counts[color] || 0) + 1;
                    }
                }

                let dominant = null;
                let dominantCount = 0;
                for (const [color, count] of Object.entries(counts)) {
                    if (count > dominantCount) {
                        dominant = color;
                        dominantCount = count;
                    }
                }

                return JSON.stringify({
                    uri: location.href,
                    viewport: {width, height},
                    dominant,
                    dominantCount,
                    sampleCount: samples.length,
                    counts,
                    samples
                });
            })()`;

            try {
                webView.evaluate_javascript(
                    blendSamplerScript,
                    -1,
                    null,
                    null,
                    null,
                    (source, result) => {
                        try {
                            const value = source.evaluate_javascript_finish(result);
                            print(`[GRAYHAIRED-BLEND-SAMPLE] ${value.to_string()}`);
                        } catch (e) {
                            printerr(`[GRAYHAIRED-BLEND-SAMPLE] evaluation failed: ${e.message}`);
                        }
                    }
                );
            } catch (e) {
                printerr(`[GRAYHAIRED-BLEND-SAMPLE] sampler launch failed: ${e.message}`);
            }
        });

        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');
        this._liveLayout.pack_start(this._liveWebView, true, true, 0);
'''

if anchor not in text:
    raise SystemExit("expected WebKit load/packing anchor not found; refusing to patch")

path.write_text(text.replace(anchor, replacement, 1), encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER' "$GRID" || \
    fail "sampler marker missing after patch"
grep -Fq '[GRAYHAIRED-BLEND-SAMPLE]' "$GRID" || \
    fail "sampler diagnostic log marker missing after patch"

pass "read-only Automatic Blend sampler installed"
printf '[GRAYHAIRED-BLEND] INFO: %s\n' \
    "reload only the GrayHaired DING/WebKit child, then inspect GRAYHAIRED-BLEND-SAMPLE logs"
