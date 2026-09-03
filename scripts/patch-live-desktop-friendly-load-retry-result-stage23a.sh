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

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8' in text:
    print('[GRAYHAIRED-SITE23A] Stage 23A v8 retry-result feedback is already installed')
    raise SystemExit(0)

if 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V7' in text:
    text = text.replace(
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V7',
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8',
        1,
    )
    old_button = '''<a class="button" id="retryButton" href="${safeUri}"
       onclick="event.preventDefault(); this.textContent='Trying…'; this.setAttribute('aria-disabled','true'); this.style.pointerEvents='none'; const retryUrl=this.href; setTimeout(() => { window.location.href=retryUrl; }, 650);">Try Again</a>'''
    if old_button not in text:
        raise SystemExit('Stage 23A v7 Retry button anchor not found; no changes made')
    text = text.replace(old_button, '<a class="button" href="${safeUri}">Try Again</a>', 1)
elif 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V6' in text:
    text = text.replace(
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V6',
        'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8',
        1,
    )
else:
    raise SystemExit('Stage 23A v6 or v7 must be installed before adding retry-result feedback')

retry_handler_anchor = '''// Retry uses a real HTTP(S) navigation, because ordinary website-link clicks
// are already physically proven on this desktop WebKit surface.
this.connectSignal(this._liveWebView, 'decide-policy',
'''
retry_handler_replacement = '''// Retry uses a real HTTP(S) navigation, because ordinary website-link clicks
// are already physically proven on this desktop WebKit surface.
let liveRetryAttempted = false;
this.connectSignal(this._liveWebView, 'decide-policy',
'''
if retry_handler_anchor not in text:
    raise SystemExit('Stage 23A retry handler start not found; no changes made')
text = text.replace(retry_handler_anchor, retry_handler_replacement, 1)

retry_action_anchor = '''        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
        decision.use();
        return true;
'''
retry_action_replacement = '''        print(`[GRAYHAIRED-SITE23A] retrying ${liveDesktopUrl}`);
        liveRetryAttempted = true;
        decision.use();
        return true;
'''
if retry_action_anchor not in text:
    raise SystemExit('Stage 23A retry action anchor not found; no changes made')
text = text.replace(retry_action_anchor, retry_action_replacement, 1)

html_anchor = '''        const errorHtml = `<!doctype html>
<html>
<head>
'''
html_replacement = '''        const retryFailed = liveRetryAttempted;
        const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';
        const statusMessage = retryFailed
            ? 'The website is still unavailable after trying again.'
            : 'My Desktop could not reach your selected website.';

        const errorHtml = `<!doctype html>
<html>
<head>
'''
if html_anchor not in text:
    raise SystemExit('Stage 23A error HTML anchor not found; no changes made')
text = text.replace(html_anchor, html_replacement, 1)

text = text.replace('<h1>Website Not Available</h1>', '<h1>${heading}</h1>', 1)
text = text.replace('<p>My Desktop could not reach your selected website.</p>', '<p>${statusMessage}</p>', 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-FRIENDLY-LOAD-ERROR-STAGE23A-V8' "$GRID" || fail "Stage 23A v8 marker missing"
grep -Fq "let liveRetryAttempted = false;" "$GRID" || fail "retry-attempt state missing"
grep -Fq "const heading = retryFailed ? 'Retry Failed' : 'Website Not Available';" "$GRID" || fail "Retry Failed heading logic missing"
grep -Fq "The website is still unavailable after trying again." "$GRID" || fail "Retry Failed message missing"

pass "Stage 23A now shows a clear Retry Failed result after an unsuccessful retry"
printf '[GRAYHAIRED-SITE23A] INFO: reload only the GrayHaired child process to test it.\n'
