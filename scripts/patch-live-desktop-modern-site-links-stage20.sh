#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-modern-site-links-stage20"

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

if grep -Fq 'GRAYHAIRED-MODERN-SITE-LINKS-STAGE20' "$GRID"; then
    pass "promoted Stage 20 modern-site link handling is already installed"
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

# Do not stack the promoted implementation on top of the physical-test markers.
for marker in (
    'GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20',
    'GRAYHAIRED-CREATE-HANDOFF-STAGE20',
    'GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B',
    'GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20C',
):
    if marker in text:
        raise SystemExit(
            f'{marker} is already present; use a clean installed baseline before applying promoted Stage 20'
        )

load_anchor = "        this._liveWebView.load_uri('"
idx = text.find(load_anchor)
if idx < 0:
    raise SystemExit('live WebView load_uri anchor not found')

create_block = """        // GRAYHAIRED-MODERN-SITE-LINKS-STAGE20
        // JavaScript-heavy sites can request a new browsing context through
        // WebKit's create signal. Hand off only explicit user-gesture HTTP(S)
        // requests to the user's default browser; leave every other create
        // request under WebKit's existing fallback behavior.
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

                const isWebUri = uri &&
                    (uri.startsWith('https://') || uri.startsWith('http://'));
                if (!gesture || !isWebUri)
                    return null;

                try {
                    print(
                        `[GRAYHAIRED-LINK20] handoff browser uri=${uri} ` +
                        `navType=${navType}`
                    );
                    Gio.AppInfo.launch_default_for_uri(uri, null);
                } catch (e) {
                    printerr(`[GRAYHAIRED-LINK20] handoff failed: ${e.message}`);
                }

                // Do not create a hidden secondary WebView. The requested page
                // has already been handed to the normal browser above.
                return null;
            });

"""
text = text[:idx] + create_block + text[idx:]

nav_anchor = "                // GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19\n"
auth_block = """                // GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20
                // MSN performs silent Microsoft-account probes during ordinary
                // page load. Keep those inside WebKit. Physical testing showed
                // that the explicit Sign in action becomes an interactive OAuth
                // request with prompt=select_account. Hand off only that narrow
                // Microsoft authorization request to the default browser.
                const isInteractiveMicrosoftAuth = uri &&
                    uri.startsWith('https://login.microsoftonline.com/') &&
                    uri.includes('/oauth2/v2.0/authorize') &&
                    uri.includes('prompt=select_account');

                if (isInteractiveMicrosoftAuth) {
                    try {
                        print(`[GRAYHAIRED-LINK20] handoff Microsoft sign-in uri=${uri}`);
                        Gio.AppInfo.launch_default_for_uri(uri, null);
                        decision.ignore();
                        return true;
                    } catch (e) {
                        printerr(`[GRAYHAIRED-LINK20] Microsoft sign-in handoff failed: ${e.message}`);
                        return false;
                    }
                }

"""
if nav_anchor not in text:
    raise SystemExit('Stage 19 navigation-policy anchor not found')
text = text.replace(nav_anchor, auth_block + nav_anchor, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-MODERN-SITE-LINKS-STAGE20' "$GRID" || fail "Stage 20 create-handoff marker missing after patch"
grep -Fq 'GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20' "$GRID" || fail "Stage 20 Microsoft-auth marker missing after patch"
grep -Fq '[GRAYHAIRED-LINK20] handoff browser uri=' "$GRID" || fail "Stage 20 browser-handoff diagnostic missing"
grep -Fq '[GRAYHAIRED-LINK20] handoff Microsoft sign-in uri=' "$GRID" || fail "Stage 20 Microsoft-auth diagnostic missing"

pass "promoted Stage 20 modern-site link handling installed"
printf '[GRAYHAIRED-LINK20] INFO: user-gesture HTTP(S) create requests open in the default browser.\n'
printf '[GRAYHAIRED-LINK20] INFO: interactive MSN/Microsoft sign-in opens in the default browser; silent auth probes remain embedded.\n'
