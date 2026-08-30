#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-background-diagnostic"

fail() {
    printf '[GRAYHAIRED-PHOTO] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-SAMPLER' "$GRID" || \
    fail "Automatic Blend sampler is not installed"
grep -Fq 'this._liveWebView.load_uri' "$GRID" || \
    fail "live WebKit load marker not found"

if grep -Fq 'GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC' "$GRID"; then
    pass "photo background diagnostic is already installed"
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

anchor = """        this._liveWebView.load_uri('https://grayhaired.tech/desktop-c');\n        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n"""
if anchor not in text:
    anchor = """        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');\n        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n"""

if anchor not in text:
    raise SystemExit("expected WebKit load/packing anchor not found; refusing to patch")

load_line = anchor.splitlines()[0]
pack_line = anchor.splitlines()[1]

replacement = rf'''        // GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC
        // Read-only diagnostic for photographic backgrounds. Report the first
        // rendered ancestor/background that actually carries a CSS image so a
        // later visual experiment can mirror or blur it without guessing.
        this.connectSignal(this._liveWebView, 'load-changed', (webView, loadEvent) => {{
            if (loadEvent !== WebKit2.LoadEvent.FINISHED)
                return;

            const photoDiagnosticScript = `(() => {{
                const results = [];
                const seen = new Set();

                function pushNode(node, label) {{
                    if (!node || seen.has(node) || node.nodeType !== 1)
                        return;
                    seen.add(node);
                    const style = getComputedStyle(node);
                    if (!style)
                        return;
                    const image = String(style.backgroundImage || 'none');
                    if (image === 'none')
                        return;
                    results.push({{
                        label,
                        tag: node.tagName,
                        id: node.id || null,
                        className: typeof node.className === 'string' ? node.className : null,
                        backgroundImage: image,
                        backgroundColor: String(style.backgroundColor || ''),
                        backgroundSize: String(style.backgroundSize || ''),
                        backgroundPosition: String(style.backgroundPosition || ''),
                        backgroundRepeat: String(style.backgroundRepeat || ''),
                        backgroundAttachment: String(style.backgroundAttachment || ''),
                        rect: (() => {{
                            const r = node.getBoundingClientRect();
                            return {{x:r.x, y:r.y, width:r.width, height:r.height}};
                        }})()
                    }});
                }}

                pushNode(document.documentElement, 'documentElement');
                pushNode(document.body, 'body');

                const width = Math.max(1, window.innerWidth || 1);
                const height = Math.max(1, window.innerHeight || 1);
                const points = [
                    [2, Math.round(height * 0.1)],
                    [2, Math.round(height * 0.5)],
                    [2, Math.round(height * 0.9)],
                    [Math.round(width * 0.5), Math.round(height * 0.5)]
                ];

                points.forEach(([x, y], index) => {{
                    let node = document.elementFromPoint(x, y);
                    let depth = 0;
                    while (node && node.nodeType === 1 && depth < 12) {{
                        pushNode(node, `point${{index}}-ancestor${{depth}}`);
                        node = node.parentElement;
                        depth++;
                    }}
                }});

                return JSON.stringify({{
                    uri: location.href,
                    viewport: {{width, height}},
                    imageBackgrounds: results
                }});
            }})()`;

            try {{
                webView.evaluate_javascript(
                    photoDiagnosticScript,
                    -1,
                    null,
                    null,
                    null,
                    (source, result) => {{
                        try {{
                            const value = source.evaluate_javascript_finish(result);
                            print(`[GRAYHAIRED-PHOTO] ${{value.to_string()}}`);
                        }} catch (e) {{
                            printerr(`[GRAYHAIRED-PHOTO] evaluation failed: ${{e.message}}`);
                        }}
                    }}
                );
            }} catch (e) {{
                printerr(`[GRAYHAIRED-PHOTO] diagnostic launch failed: ${{e.message}}`);
            }}
        }});

{load_line}
{pack_line}
'''

path.write_text(text.replace(anchor, replacement, 1), encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC' "$GRID" || \
    fail "photo diagnostic marker missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO]' "$GRID" || \
    fail "photo diagnostic log marker missing after patch"

pass "read-only photographic-background diagnostic installed"
printf '[GRAYHAIRED-PHOTO] INFO: %s\n' \
    "reload only the GrayHaired child, then inspect GRAYHAIRED-PHOTO logs"
