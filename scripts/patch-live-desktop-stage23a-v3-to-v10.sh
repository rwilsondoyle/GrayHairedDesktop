#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-stage23a-v10"

fail() {
    printf '[GRAYHAIRED-SITE23A] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23A] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"

if grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' "$GRID"; then
    pass "Stage 23A v10 is already installed"
    exit 0
fi

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3' "$GRID" || \
    fail "This direct upgrade expects the physically installed Stage 23A v3 tree"

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

# Directly upgrade the physically observed v3 block. Do not depend on any of
# the experimental v4-v9 patches having landed.
text = text.replace(
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V3',
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10',
    1,
)

handler_anchor = """        // GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10
        // Friendly recovery for the configured desktop website.
        this.connectSignal(this._liveWebView, 'decide-policy',
"""
handler_replacement = """        // GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10
        // Friendly recovery for the configured desktop website.
        let liveRetryAttempted = false;
        this.connectSignal(this._liveWebView, 'decide-policy',
"""
if handler_anchor not in text:
    raise SystemExit('v3 handler start not found after marker upgrade')
text = text.replace(handler_anchor, handler_replacement, 1)

old_retry = """                if (uri !== 'grayhaired-retry://retry')
                    return false;

                print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
                decision.ignore();
                webView.load_uri(liveDesktopUrl);
                return true;
"""

new_retry = r"""                if (uri !== 'grayhaired-retry://retry')
                    return false;

                print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
                liveRetryAttempted = true;
                decision.ignore();

                const tryingHtml = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Trying Again</title>
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
    text-align: center;
  }
  h1 { margin: 0 0 16px; font-size: 32px; }
  p { font-size: 20px; line-height: 1.5; margin: 12px 0; }
  @media (prefers-color-scheme: dark) {
    body { background: #202326; color: #f4f4f4; }
    .card { background: #292d31; border-color: #50555a; }
  }
</style>
</head>
<body>
  <main class="card">
    <h1>Trying Again…</h1>
    <p>Checking the website one more time.</p>
  </main>
</body>
</html>`;

                webView.load_html(tryingHtml, 'about:blank');
                GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1200, () => {
                    print(`[GRAYHAIRED-SITE23A] retry load ${liveDesktopUrl}`);
                    webView.load_uri(liveDesktopUrl);
                    return GLib.SOURCE_REMOVE;
                });
                return true;
"""

if old_retry not in text:
    raise SystemExit('v3 retry action not found')
text = text.replace(old_retry, new_retry, 1)

html_anchor = """                const errorHtml = `<!doctype html>
<html>
<head>
"""
html_replacement = """                const retryFailed = liveRetryAttempted;
                const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';
                const statusMessage = retryFailed
                    ? 'The website is still unavailable after trying again.'
                    : 'My Desktop could not reach your selected website.';

                const errorHtml = `<!doctype html>
<html>
<head>
"""
if html_anchor not in text:
    raise SystemExit('v3 error HTML start not found')
text = text.replace(html_anchor, html_replacement, 1)

if '<h1>Website Not Available</h1>' not in text:
    raise SystemExit('v3 error heading not found')
text = text.replace('<h1>Website Not Available</h1>', '<h1>${heading}</h1>', 1)

if '<p>My Desktop could not reach your selected website.</p>' not in text:
    raise SystemExit('v3 error status line not found')
text = text.replace(
    '<p>My Desktop could not reach your selected website.</p>',
    '<p>${statusMessage}</p>',
    1,
)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V10' "$GRID" || fail "v10 marker missing"
grep -Fq 'Trying Again…' "$GRID" || fail "Trying Again screen missing"
grep -Fq "Retry Failed" "$GRID" || fail "Retry Failed result missing"
grep -Fq 'retry load ${liveDesktopUrl}' "$GRID" || fail "delayed retry load missing"

pass "Stage 23A v3 upgraded directly to v10 with visible retry feedback"
printf '[GRAYHAIRED-SITE23A] INFO: reload the GrayHaired child and test the invalid site.\n'
