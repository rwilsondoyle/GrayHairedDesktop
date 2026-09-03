#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-stage23b-http-v1"

fail() {
    printf '[GRAYHAIRED-SITE23B] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23B] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V12' "$GRID" || \
    fail "Stage 23A v12 must be installed before Stage 23B HTTP handling"

if grep -Fq 'GRAYHAIRED-HTTP-ERROR-STAGE23B-V1' "$GRID"; then
    pass "Stage 23B HTTP error handling is already installed"
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
marker = 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V12'
marker_pos = text.find(marker)
if marker_pos < 0:
    raise SystemExit('Stage 23A v12 marker not found')

state = 'let liveRetryAttempted = false;'
state_pos = text.find(state, marker_pos)
if state_pos < 0:
    raise SystemExit('Stage 23A retry state not found')
state_end = state_pos + len(state)

block = r'''

        // GRAYHAIRED-HTTP-ERROR-STAGE23B-V1
        let liveHttpErrorPageActive = false;

        const showLiveHttpError = (webView, uri, statusCode) => {
            liveHttpErrorPageActive = true;
            const retryFailed = liveRetryAttempted;
            const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';
            const statusMessage = retryFailed
                ? 'The website is still unavailable after trying again.'
                : 'My Desktop reached the website, but the website returned an error.';
            const safeUri = String(uri || liveDesktopUrl)
                .replaceAll('&', '&amp;')
                .replaceAll('<', '&lt;')
                .replaceAll('>', '&gt;')
                .replaceAll('"', '&quot;')
                .replaceAll("'", '&#39;');

            const httpErrorHtml = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${heading}</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0; min-height: 100vh; display: flex; align-items: center;
    justify-content: center; box-sizing: border-box; padding: 42px;
    font-family: system-ui, sans-serif; background: #f5f5f5; color: #242424;
  }
  .card {
    width: min(680px, 100%); background: #fff; border: 1px solid #d0d0d0;
    border-radius: 16px; padding: 34px; box-sizing: border-box;
    box-shadow: 0 4px 18px rgba(0,0,0,.10);
  }
  h1 { margin: 0 0 16px; font-size: 32px; }
  p { font-size: 20px; line-height: 1.5; margin: 12px 0; }
  .site {
    margin: 20px 0; padding: 12px 14px; border-radius: 10px;
    background: #eceff1; overflow-wrap: anywhere; font-size: 17px;
  }
  .button {
    display: inline-block; margin: 10px 0 14px; padding: 12px 22px;
    border-radius: 10px; background: #3564c5; color: #fff;
    text-decoration: none; font-weight: 700; font-size: 18px;
  }
  .help { color: #666; font-size: 17px; }
  @media (prefers-color-scheme: dark) {
    body { background: #202326; color: #f4f4f4; }
    .card { background: #292d31; border-color: #50555a; }
    .site { background: #363b40; }
    .help { color: #c9c9c9; }
  }
</style>
</head>
<body>
  <main class="card">
    <h1>${heading}</h1>
    <p>${statusMessage}</p>
    <p>The website reported error <strong>${statusCode}</strong>.</p>
    <div class="site">${safeUri}</div>
    <a class="button" href="grayhaired-retry://retry">Try Again</a>
    <p class="help">To choose a different website, open <strong>My Desktop Settings</strong> from the application menu.</p>
  </main>
</body>
</html>`;

            print(`[GRAYHAIRED-SITE23B] HTTP error status=${statusCode} uri=${uri}`);
            webView.load_html(httpErrorHtml, 'about:blank');
        };

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

                print(`[GRAYHAIRED-SITE23B] finished uri=${uri} status=${statusCode}`);

                if (statusCode >= 400 && statusCode <= 599) {
                    showLiveHttpError(webView, uri, statusCode);
                    return;
                }

                if (statusCode >= 200 && statusCode <= 399)
                    liveRetryAttempted = false;
            } catch (e) {
                print(`[GRAYHAIRED-SITE23B] status check failed uri=${uri} error=${e.message}`);
            }
        });
'''

text = text[:state_end] + block + text[state_end:]

# A retry must leave the HTTP error page state before the delayed load starts.
retry_anchor = 'liveRetryAttempted = true;'
retry_pos = text.find(retry_anchor, state_end + len(block))
if retry_pos < 0:
    raise SystemExit('Stage 23A retry action not found')
retry_end = retry_pos + len(retry_anchor)
text = text[:retry_end] + '\n                liveHttpErrorPageActive = false;' + text[retry_end:]

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-HTTP-ERROR-STAGE23B-V1' "$GRID" || fail "Stage 23B marker missing"
grep -Fq 'get_status_code()' "$GRID" || fail "HTTP status inspection missing"
grep -Fq 'statusCode >= 400 && statusCode <= 599' "$GRID" || fail "HTTP 4xx/5xx range check missing"
grep -Fq 'liveHttpErrorPageActive = false;' "$GRID" || fail "HTTP retry reset missing"

pass "Stage 23B HTTP 4xx/5xx friendly handling installed"
printf '[GRAYHAIRED-SITE23B] INFO: reload GrayHaired and retest https://httpbin.org/status/404.\n'
