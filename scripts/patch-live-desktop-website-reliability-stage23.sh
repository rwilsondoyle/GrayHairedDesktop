#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-stage23-promoted"

fail() {
    printf '[GRAYHAIRED-SITE23] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-WEBSITE-CONFIG-STAGE21' "$GRID" || fail "Stage 21 persistent website selection is missing"

if grep -Fq 'GRAYHAIRED-WEBSITE-RELIABILITY-STAGE23' "$GRID"; then
    pass "Stage 23 promoted website reliability handling is already installed"
    exit 0
fi

# Refuse to layer the promoted installer over an experimental Stage 23 tree.
if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A' "$GRID" || \
   grep -Fq 'GRAYHAIRED-HTTP-ERROR-STAGE23B' "$GRID"; then
    fail "experimental Stage 23 markers are already present; use a clean Stage 21 install tree before applying the promoted Stage 23 patch"
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

pattern = re.compile(r'(?m)^(?P<indent>\s*)this\._liveWebView\.load_uri\(liveDesktopUrl\);\s*$')
matches = list(pattern.finditer(text))
if len(matches) != 1:
    raise SystemExit(f'Expected exactly one Stage 21 liveDesktopUrl load call; found {len(matches)}')

m = matches[0]
indent = m.group('indent')

block = r'''// GRAYHAIRED-WEBSITE-RELIABILITY-STAGE23
// Friendly recovery for unreachable websites and HTTP 4xx/5xx responses.
let liveRetryAttempted = false;
let liveHttpErrorPageActive = false;

const escapeLiveHtml = value => String(value || '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

const liveFriendlyHtml = (uri, heading, statusMessage, detailMessage) => {
    const safeUri = escapeLiveHtml(uri || liveDesktopUrl);
    return `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${heading}</title>
<style>
  :root { color-scheme: light dark; }
  body { margin:0; min-height:100vh; display:flex; align-items:center; justify-content:center;
    box-sizing:border-box; padding:42px; font-family:system-ui,sans-serif; background:#f5f5f5; color:#242424; }
  .card { width:min(680px,100%); background:#fff; border:1px solid #d0d0d0; border-radius:16px;
    padding:34px; box-sizing:border-box; box-shadow:0 4px 18px rgba(0,0,0,.10); }
  h1 { margin:0 0 16px; font-size:32px; }
  p { font-size:20px; line-height:1.5; margin:12px 0; }
  .site { margin:20px 0; padding:12px 14px; border-radius:10px; background:#eceff1;
    overflow-wrap:anywhere; font-size:17px; }
  .button { display:inline-block; margin:10px 0 14px; padding:12px 22px; border-radius:10px;
    background:#3564c5; color:#fff; text-decoration:none; font-weight:700; font-size:18px; }
  .help { color:#666; font-size:17px; }
  @media (prefers-color-scheme: dark) {
    body { background:#202326; color:#f4f4f4; }
    .card { background:#292d31; border-color:#50555a; }
    .site { background:#363b40; }
    .help { color:#c9c9c9; }
  }
</style>
</head>
<body>
  <main class="card">
    <h1>${heading}</h1>
    <p>${statusMessage}</p>
    ${detailMessage ? `<p>${detailMessage}</p>` : ''}
    <div class="site">${safeUri}</div>
    <a class="button" href="grayhaired-retry://retry">Try Again</a>
    <p class="help">To choose a different website, open <strong>My Desktop Settings</strong> from the application menu.</p>
  </main>
</body>
</html>`;
};

const showLiveFailure = (webView, uri, detailMessage = '') => {
    const retryFailed = liveRetryAttempted;
    const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';
    const statusMessage = retryFailed
        ? 'The website is still unavailable after trying again.'
        : 'My Desktop could not reach your selected website.';
    webView.load_html(liveFriendlyHtml(uri, heading, statusMessage, detailMessage), 'about:blank');
};

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

        print(`[GRAYHAIRED-SITE23] retrying ${liveDesktopUrl}`);
        liveRetryAttempted = true;
        liveHttpErrorPageActive = false;
        decision.ignore();

        const tryingHtml = `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trying Again</title><style>:root{color-scheme:light dark}body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:42px;font-family:system-ui,sans-serif;background:#f5f5f5;color:#242424}.card{width:min(680px,100%);background:#fff;border:1px solid #d0d0d0;border-radius:16px;padding:34px;box-sizing:border-box;text-align:center;box-shadow:0 4px 18px rgba(0,0,0,.10)}h1{margin:0 0 16px;font-size:32px}p{font-size:20px;line-height:1.5;margin:12px 0}@media(prefers-color-scheme:dark){body{background:#202326;color:#f4f4f4}.card{background:#292d31;border-color:#50555a}}</style></head><body><main class="card"><h1>Trying Again…</h1><p>Checking the website one more time.</p></main></body></html>`;
        webView.load_html(tryingHtml, 'about:blank');
        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {
            print(`[GRAYHAIRED-SITE23] retry load ${liveDesktopUrl}`);
            webView.load_uri(liveDesktopUrl);
            return GLib.SOURCE_REMOVE;
        });
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
        try { detail = error && error.message ? String(error.message) : ''; } catch (e) {}
        print(`[GRAYHAIRED-SITE23] configured website failed uri=${failingUri} error=${detail || '<none>'}`);
        liveHttpErrorPageActive = false;
        showLiveFailure(webView, failingUri,
            'This can happen if the Internet connection is down or the website is temporarily unavailable.');
        return true;
    });

this.connectSignal(this._liveWebView, 'load-changed', (webView, loadEvent) => {
    if (loadEvent !== WebKit2.LoadEvent.FINISHED)
        return;

    const uri = webView.get_uri() || '';
    if (!uri.startsWith('http://') && !uri.startsWith('https://'))
        return;
    if (liveHttpErrorPageActive)
        return;

    try {
        const resource = webView.get_main_resource();
        const response = resource ? resource.get_response() : null;
        const statusCode = response ? response.get_status_code() : 0;
        print(`[GRAYHAIRED-SITE23] finished uri=${uri} status=${statusCode}`);

        if (statusCode >= 400 && statusCode <= 599) {
            liveHttpErrorPageActive = true;
            const retryFailed = liveRetryAttempted;
            const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';
            const statusMessage = retryFailed
                ? 'The website is still unavailable after trying again.'
                : 'My Desktop reached the website, but the website returned an error.';
            print(`[GRAYHAIRED-SITE23] HTTP error status=${statusCode} uri=${uri}`);
            webView.load_html(
                liveFriendlyHtml(uri, heading, statusMessage,
                    `The website reported error <strong>${statusCode}</strong>.`),
                'about:blank');
            return;
        }

        if (statusCode >= 200 && statusCode <= 399) {
            liveRetryAttempted = false;
            liveHttpErrorPageActive = false;
        }
    } catch (e) {
        print(`[GRAYHAIRED-SITE23] status check failed uri=${uri} error=${e.message}`);
    }
});

this._liveWebView.load_uri(liveDesktopUrl);'''

replacement = '\n'.join(indent + line if line else '' for line in block.splitlines())
text = text[:m.start()] + replacement + text[m.end():]
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-WEBSITE-RELIABILITY-STAGE23' "$GRID" || fail "Stage 23 marker missing"
grep -Fq "'load-failed'" "$GRID" || fail "load-failed handler missing"
grep -Fq 'get_status_code()' "$GRID" || fail "HTTP status inspection missing"
grep -Fq 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200' "$GRID" || fail "1.2-second retry feedback missing"
grep -Fq 'grayhaired-retry://retry' "$GRID" || fail "Retry action missing"

pass "promoted Stage 23 website reliability handling installed"
printf '[GRAYHAIRED-SITE23] INFO: handles network/TLS failures, HTTP 4xx/5xx responses, and visible 1.2-second retry feedback.\n'
