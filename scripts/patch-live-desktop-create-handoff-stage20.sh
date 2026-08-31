#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-create-handoff-stage20"

fail() {
    printf '[GRAYHAIRED-LINK20] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LINK20] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'Opening in default browser' "$GRID" || fail "existing WebKit navigation policy handler is missing"
grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID" || fail "Stage 19 local-file guard is missing"
grep -Fq 'GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20' "$GRID" || fail "Stage 20 diagnostics must be installed first"

if grep -Fq 'GRAYHAIRED-CREATE-HANDOFF-STAGE20' "$GRID"; then
    pass "Stage 20 guarded create handoff is already installed"
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

old = """        // GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20
        // Diagnostic only: observe JavaScript/new-window requests that bypass
        // the normal decide-policy handoff. Do not launch or redirect anything
        // from this signal yet; return null and preserve existing behavior.
        this.connectSignal(this._liveWebView, 'create',
            (webView, navigationAction) => {
                let uri = '<unknown>';
                let gesture = false;
                let navType = '<unknown>';
                try {
                    const request = navigationAction.get_request();
                    if (request)
                        uri = request.get_uri() || '<empty>';
                } catch (e) {
                    uri = `<request-error:${e.message}>`;
                }
                try {
                    gesture = navigationAction.is_user_gesture();
                } catch (e) {
                    // Some WebKit builds may not expose this accessor here.
                }
                try {
                    navType = String(navigationAction.get_navigation_type());
                } catch (e) {
                    // Diagnostic only.
                }
                print(
                    `[GRAYHAIRED-LINK20] create uri=${uri} ` +
                    `gesture=${gesture} navType=${navType}`
                );
                return null;
            });

"""

new = """        // GRAYHAIRED-CREATE-HANDOFF-STAGE20
        // JavaScript-heavy sites can request a new browsing context through
        // WebKit's create signal without reaching the existing decide-policy
        // path in a useful way. Only hand off explicit user-gesture HTTP(S)
        // requests. Anything else keeps WebKit's previous fallback behavior.
        this.connectSignal(this._liveWebView, 'create',
            (webView, navigationAction) => {
                let uri = null;
                let gesture = false;
                let navType = '<unknown>';
                try {
                    const request = navigationAction.get_request();
                    if (request)
                        uri = request.get_uri();
                } catch (e) {
                    print(`[GRAYHAIRED-LINK20] create inspect failed: ${e.message}`);
                    return null;
                }
                try {
                    gesture = navigationAction.is_user_gesture();
                } catch (e) {
                    // If gesture state cannot be confirmed, do not hand off.
                }
                try {
                    navType = String(navigationAction.get_navigation_type());
                } catch (e) {
                    // Diagnostic detail only.
                }

                print(
                    `[GRAYHAIRED-LINK20] create uri=${uri || '<empty>'} ` +
                    `gesture=${gesture} navType=${navType}`
                );

                const isWebUri = uri &&
                    (uri.startsWith('https://') || uri.startsWith('http://'));
                if (!gesture || !isWebUri) {
                    print('[GRAYHAIRED-LINK20] create fallback to WebKit');
                    return null;
                }

                try {
                    print(`[GRAYHAIRED-LINK20] handoff browser uri=${uri}`);
                    Gio.AppInfo.launch_default_for_uri(uri, null);
                } catch (e) {
                    printerr(`[GRAYHAIRED-LINK20] handoff failed: ${e.message}`);
                }

                // Returning null means GrayHaired does not create a hidden
                // secondary WebView; the requested page has already been
                // handed to the user's normal browser above.
                return null;
            });

"""

if old not in text:
    raise SystemExit('Stage 20 diagnostic create block not found')

path.write_text(text.replace(old, new, 1), encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-CREATE-HANDOFF-STAGE20' "$GRID" || fail "Stage 20 guarded create handoff marker missing"
grep -Fq '[GRAYHAIRED-LINK20] handoff browser uri=' "$GRID" || fail "Stage 20 handoff diagnostic missing"

pass "Stage 20 guarded WebKit create handoff installed"
printf '[GRAYHAIRED-LINK20] INFO: reload only the GrayHaired child, then click several MSN cards.\n'
printf '[GRAYHAIRED-LINK20] INFO: user-gesture HTTP(S) create requests should open in the default browser.\n'
printf '[GRAYHAIRED-LINK20] INFO: the live desktop should remain on MSN and no hidden WebKit child should be created.\n'
