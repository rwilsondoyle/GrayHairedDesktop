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

if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V2' "$GRID"; then
    pass "Stage 23A v2 friendly load error handling is already installed"
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

# If the first Stage 23A attempt partially landed, refuse to stack another
# handler on top of it. The physical baseline showed no Stage 23A markers, so
# this guard is primarily for repeatability on later test machines.
if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A' in text:
    raise SystemExit(
        'An older Stage 23A marker is already present; restore the pre-Stage23A backup before applying v2.'
    )

load_anchor = """        print(`[GRAYHAIRED-SITE21] loading ${liveDesktopUrl}`);
        this._liveWebView.load_uri(liveDesktopUrl);
"""

if load_anchor not in text:
    raise SystemExit('Expected Stage 21 configured load anchor not found; no changes made')

block = r"""        // GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V2
        // Handle the private retry action in its own policy callback so this
        // remains compatible with both the earlier physically tested Stage 20B
        // navigation diagnostics and the later promoted Stage 20 handler.
        this.connectSignal(this._liveWebView, 'decide-policy',
            (webView, decision, decisionType) => {
                if (decisionType !== WebKit2.PolicyDecisionType.NAVIGATION_ACTION &&
                    decisionType !== WebKit2.PolicyDecisionType.NEW_WINDOW_ACTION)
                    return false;

                let uri = null;
                try {
                    const action = decision.get_navigation_action();
                    const request = action ? action.get_request() : null;
                    uri = request ? request.get_uri() : null;
                } catch (e) {
                    return false;
                }

                if (uri !== 'grayhaired-retry://retry')
                    return false;

                print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
                decision.ignore();
                webView.load_uri(liveDesktopUrl);
                return true;
            });

        // WebKit may canonicalize a host-only URL by adding a trailing slash.
        // Compare normalized forms so a failure for https://example.invalid/
        // is still recognized as the configured https://example.invalid site.
        this.connectSignal(this._liveWebView, 'load-failed',
            (webView, loadEvent, failingUri, error) => {
                if (!failingUri)
                    return false;

                const normalizeUri = value => String(value || '').replace(/\/$/, '');
                if (normalizeUri(failingUri) !== normalizeUri(liveDesktopUrl))
                    return false;

                let detail = '';
                try {
                    detail = error && error.message ? String(error.message) : '';
                } catch (e) {
                    // Diagnostic detail only.
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

text = text.replace(load_anchor, block, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V2' "$GRID" || fail "Stage 23A v2 marker missing after patch"
grep -Fq "'load-failed'" "$GRID" || fail "WebKit load-failed handler missing after patch"
grep -Fq 'grayhaired-retry://retry' "$GRID" || fail "private retry action missing after patch"
grep -Fq 'Website Not Available' "$GRID" || fail "friendly error heading missing after patch"

pass "Stage 23A v2 friendly configured-website failure screen installed"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
