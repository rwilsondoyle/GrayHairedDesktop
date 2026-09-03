#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-friendly-load-error-stage23a"

fail() {
    printf '[GRAYHAIRED-SITE23A] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23A] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-WEBSITE-CONFIG-STAGE21' "$GRID" || fail "Stage 21 persistent website selection is missing"
grep -Fq 'Opening in default browser' "$GRID" || fail "existing WebKit navigation policy handler is missing"

if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A' "$GRID"; then
    pass "Stage 23A friendly load error handling is already installed"
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

# The retry action is deliberately handled inside the existing navigation
# policy callback. It reloads the saved live-site URL inside WebKit and never
# opens a browser or changes the user's saved setting.
retry_anchor = """                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
"""
retry_block = """                // GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A
                // The friendly error page uses a private retry URI. Keep it
                // inside My Desktop, ignore the synthetic navigation, and try
                // the currently saved live-site URL again without changing it.
                if (uri === 'grayhaired-retry://retry') {
                    print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
                    decision.ignore();
                    webView.load_uri(liveDesktopUrl);
                    return true;
                }

                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
"""
if retry_anchor not in text:
    raise SystemExit('Expected WebKit navigation-policy retry anchor not found')
text = text.replace(retry_anchor, retry_block, 1)

load_anchor = """        print(`[GRAYHAIRED-SITE21] loading ${liveDesktopUrl}`);
        this._liveWebView.load_uri(liveDesktopUrl);
"""
load_block = r"""        // GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A
        // Replace WebKit's terse DNS/network failure text for the configured
        // startup site with a calm recovery screen. Restrict this first
        // reliability checkpoint to the configured URL itself so unrelated
        // background/auth requests cannot replace the desktop by accident.
        this.connectSignal(this._liveWebView, 'load-failed',
            (webView, loadEvent, failingUri, error) => {
                if (!failingUri || failingUri !== liveDesktopUrl)
                    return false;

                let detail = '';
                try {
                    detail = error && error.message ? String(error.message) : '';
                } catch (e) {
                    // Technical detail is diagnostic only; the user message
                    // remains useful even when WebKit provides none.
                }
                print(
                    `[GRAYHAIRED-SITE23A] configured website failed uri=${failingUri} ` +
                    `error=${detail || '<none>'}`
                );

                const safeUri = String(failingUri)
                    .replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/\"/g, '&quot;')
                    .replace(/'/g, '&#39;');

                const errorHtml = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Website Not Available</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    box-sizing: border-box;
    padding: 42px;
    font-family: system-ui, sans-serif;
    background: #f5f5f5;
    color: #242424;
  }
  .card {
    width: min(680px, 100%);
    background: #ffffff;
    border: 1px solid #d0d0d0;
    border-radius: 16px;
    padding: 34px;
    box-sizing: border-box;
    box-shadow: 0 4px 18px rgba(0,0,0,.10);
  }
  h1 { margin: 0 0 16px; font-size: 32px; }
  p { font-size: 20px; line-height: 1.5; margin: 12px 0; }
  .site {
    margin: 20px 0;
    padding: 12px 14px;
    border-radius: 9px;
    background: #eeeeee;
    overflow-wrap: anywhere;
    font-size: 17px;
  }
  .button {
    display: inline-block;
    margin-top: 10px;
    padding: 13px 22px;
    border-radius: 9px;
    background: #3155a6;
    color: white;
    text-decoration: none;
    font-size: 19px;
    font-weight: 600;
  }
  .help { margin-top: 22px; font-size: 17px; color: #555; }
  @media (prefers-color-scheme: dark) {
    body { background: #202326; color: #f4f4f4; }
    .card { background: #292d31; border-color: #50555a; }
    .site { background: #363b40; }
    .help { color: #c5c5c5; }
  }
</style>
</head>
<body>
  <main class="card">
    <h1>Website Not Available</h1>
    <p>My Desktop could not reach your selected website.</p>
    <p>This can happen if the Internet connection is down or the website is temporarily unavailable.</p>
    <div class="site">${safeUri}</div>
    <a class="button" href="grayhaired-retry://retry">Try Again</a>
    <p class="help">To choose a different website, open <strong>My Desktop Settings</strong> from the application menu.</p>
  </main>
</body>
</html>`;

                webView.load_html(errorHtml, 'about:blank');
                return true;
            });

        print(`[GRAYHAIRED-SITE21] loading ${liveDesktopUrl}`);
        this._liveWebView.load_uri(liveDesktopUrl);
"""
if load_anchor not in text:
    raise SystemExit('Expected Stage 21 configured load anchor not found')
text = text.replace(load_anchor, load_block, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A' "$GRID" || fail "Stage 23A marker missing after patch"
grep -Fq "'load-failed'" "$GRID" || fail "WebKit load-failed handler missing after patch"
grep -Fq 'grayhaired-retry://retry' "$GRID" || fail "private retry action missing after patch"
grep -Fq 'Website Not Available' "$GRID" || fail "friendly error heading missing after patch"

pass "Stage 23A friendly configured-website failure screen installed"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
