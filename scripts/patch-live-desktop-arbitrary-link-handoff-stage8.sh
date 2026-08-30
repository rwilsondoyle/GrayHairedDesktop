#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-arbitrary-link-handoff-stage8"

fail() {
    printf '[GRAYHAIRED-LINK8] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LINK8] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq '[GRAYHAIRED-WEBKIT] Opening in default browser:' "$GRID" || \
    fail "existing WebKit browser handoff is not installed"

if grep -Fq 'GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8' "$GRID"; then
    pass "arbitrary-site link handoff Stage 8 is already installed"
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

# Discover the currently configured live-desktop URL from load_uri().
m = re.search(r"this\._liveWebView\.load_uri\('([^']+)'\);", text)
if not m:
    raise SystemExit('configured live WebKit URL not found')
root_url = m.group(1)

# Add root URL state immediately before the decide-policy signal.
anchor = """        this.connectSignal(this._liveWebView, 'decide-policy',
"""
insert = f"""        // GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8
        // Remember the chosen live desktop URL. Modern sites often convert a
        // physical click into JavaScript navigation, which can lose WebKit's
        // user-gesture flag. We still keep the desktop site's own document and
        // redirects inside WebKit, while handing later top-level destinations
        // to the user's normal browser.
        this._liveDesktopRootUri = '{root_url}';
        this._liveDesktopInitialLoadComplete = false;
        this.connectSignal(this._liveWebView, 'load-changed',
            (_view, loadEvent) => {{
                if (loadEvent === WebKit2.LoadEvent.FINISHED)
                    this._liveDesktopInitialLoadComplete = true;
            }});

"""
if 'GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8' not in text:
    if anchor not in text:
        raise SystemExit('decide-policy signal anchor not found')
    text = text.replace(anchor, insert + anchor, 1)

old = """                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
                // actual clicked destinations to the normal default browser.
                if (uri.startsWith('https://grayhaired.tech/desktop-d')) {
                    return false;
                }
"""
new = """                if (!uri)
                    return false;

                // GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8
                // During the initial page load, allow redirects and same-site
                // bootstrapping to remain in WebKit. After FINISHED, a normal
                // user gesture, a requested new window, or any top-level URI
                // that differs from the currently displayed desktop document
                // is treated as a browser destination. This catches SPA/JS
                // cards whose click loses WebKit's user-gesture flag.
                let currentUri = '';
                try {
                    currentUri = webView.get_uri() || '';
                } catch (e) {
                    currentUri = '';
                }

                if (!this._liveDesktopInitialLoadComplete)
                    return false;

                if (uri === currentUri || uri === this._liveDesktopRootUri)
                    return false;

                if (!isNewWindow && !isUserGesture && uri.startsWith('#'))
                    return false;
"""
if old not in text:
    raise SystemExit('existing browser-handoff decision block not found')
text = text.replace(old, new, 1)

# Add a concise diagnostic so inconsistent clicks are observable.
text = text.replace(
    "print(`[GRAYHAIRED-WEBKIT] Opening in default browser: ${uri}`);",
    "print(`[GRAYHAIRED-LINK8] handoff gesture=${isUserGesture} newWindow=${isNewWindow} uri=${uri}`);\n                    print(`[GRAYHAIRED-WEBKIT] Opening in default browser: ${uri}`);",
    1,
)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-ARBITRARY-LINK-HANDOFF-STAGE8' "$GRID" || fail "Stage 8 marker missing"
grep -Fq '[GRAYHAIRED-LINK8] handoff' "$GRID" || fail "Stage 8 diagnostic missing"

pass "arbitrary-site browser handoff Stage 8 installed"
printf '[GRAYHAIRED-LINK8] INFO: %s\n' \
    "reload only the GrayHaired child, then retry several MSN cards/links"
