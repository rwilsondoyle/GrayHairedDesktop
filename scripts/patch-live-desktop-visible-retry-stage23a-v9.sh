#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

fail() {
    printf '[GRAYHAIRED-SITE23A] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SITE23A] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding='utf-8')

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V9' in text:
    print('[GRAYHAIRED-SITE23A] Stage 23A v9 visible retry feedback is already installed')
    raise SystemExit(0)

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8' not in text:
    raise SystemExit('Stage 23A v8 must be installed before applying v9')

old_action = '''        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
        liveRetryAttempted = true;
        decision.use();
        return true;
'''

new_action = r'''        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
        liveRetryAttempted = true;
        decision.ignore();

        // Show a real intermediate document from the owning GJS process.
        // This does not depend on inline JavaScript executing inside the
        // error page, so the user always sees that Retry was accepted.
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

        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 900, () => {
            print(`[GRAYHAIRED-SITE23A] retry load ${liveDesktopUrl}`);
            webView.load_uri(liveDesktopUrl);
            return GLib.SOURCE_REMOVE;
        });
        return true;
'''

if old_action not in text:
    raise SystemExit('Stage 23A v8 retry action anchor not found; no changes made')

text = text.replace(old_action, new_action, 1)
text = text.replace(
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8',
    'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V9',
    1,
)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V9' "$GRID" || fail "Stage 23A v9 marker missing"
grep -Fq 'Trying Again…' "$GRID" || fail "visible Trying Again screen missing"
grep -Fq 'GLib.timeout_add(GLib.PRIORITY_DEFAULT, 900' "$GRID" || fail "delayed retry load missing"
grep -Fq "Retry Failed" "$GRID" || fail "Retry Failed result logic missing"

pass "Stage 23A v9 installs a visible Trying Again screen before retrying"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
