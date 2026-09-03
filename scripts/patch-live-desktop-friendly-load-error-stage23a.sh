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

if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V4' "$GRID"; then
    pass "Stage 23A v4 friendly load error handling is already installed"
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

# Upgrade the physically tested v3 error page in place. WebKit displays the
# custom grayhaired-retry:// URI but does not reliably route it through the
# policy callback. An about:blank fragment is a normal WebKit navigation, so
# the retry click is observable and can be intercepted safely.
if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3' in text:
    old_handler = """        if (uri !== 'grayhaired-retry://retry')
            return false;

        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
"""
    new_handler = """        if (uri !== 'about:blank#grayhaired-retry')
            return false;

        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
"""
    if old_handler not in text:
        raise SystemExit('Stage 23A v3 retry handler anchor not found; no changes made')
    text = text.replace(old_handler, new_handler, 1)
    text = text.replace(
        '<a class="button" href="grayhaired-retry://retry">Try Again</a>',
        '<a class="button" href="about:blank#grayhaired-retry">Try Again</a>',
        1,
    )
    text = text.replace(
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3',
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V4',
        1,
    )
    path.write_text(text, encoding='utf-8')
    print('[GRAYHAIRED-SITE23A] upgraded v3 retry navigation to v4')
    raise SystemExit(0)

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A' in text:
    raise SystemExit(
        'An unsupported older Stage 23A marker is already present; restore the pre-Stage23A backup before applying v4.'
    )

pattern = re.compile(
    r'(?m)^(?P<indent>\s*)this\._liveWebView\.load_uri\(liveDesktopUrl\);\s*$'
)
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit(
        f'Expected exactly one configured liveDesktopUrl load call; found {len(matches)}; no changes made'
    )

match = matches[0]
indent = match.group('indent')

block_lines = r'''// GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V4
// Friendly recovery for the configured desktop website.
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

        // Use a normal about:blank fragment rather than a custom URI scheme.
        // WebKit reliably emits decide-policy for this navigation.
        if (uri !== 'about:blank#grayhaired-retry')
            return false;

        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
        decision.ignore();
        webView.load_uri(liveDesktopUrl);
        return true;
    });

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
            // Technical detail is diagnostic only.
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
    <a class="button" href="about:blank#grayhaired-retry">Try Again</a>
    <p class="help">To choose a different website, open <strong>My Desktop Settings</strong> from the application menu.</p>
  </main>
</body>
</html>`;

        webView.load_html(errorHtml, 'about:blank');
        return true;
    });

this._liveWebView.load_uri(liveDesktopUrl);'''

replacement = '\n'.join(indent + line if line else '' for line in block_lines.splitlines())
text = text[:match.start()] + replacement + text[match.end():]
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V4' "$GRID" || fail "Stage 23A v4 marker missing after patch"
grep -Fq "'load-failed'" "$GRID" || fail "WebKit load-failed handler missing after patch"
grep -Fq 'about:blank#grayhaired-retry' "$GRID" || fail "retry navigation missing after patch"
grep -Fq 'Website Not Available' "$GRID" || fail "friendly error heading missing after patch"

pass "Stage 23A v4 friendly configured-website failure screen installed"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
