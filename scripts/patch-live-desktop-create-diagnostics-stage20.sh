#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-create-diagnostics-stage20"

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

if grep -Fq 'GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20' "$GRID"; then
    pass "Stage 20 create diagnostics are already installed"
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

anchor = """        this._liveWebView.load_uri('"""
idx = text.find(anchor)
if idx < 0:
    raise SystemExit('live WebView load_uri anchor not found')

insert = """        // GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20
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
text = text[:idx] + insert + text[idx:]
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-CREATE-DIAGNOSTICS-STAGE20' "$GRID" || fail "Stage 20 marker missing after patch"
grep -Fq '[GRAYHAIRED-LINK20] create uri=' "$GRID" || fail "Stage 20 create diagnostic log missing"

pass "Stage 20 WebKit create diagnostics installed"
printf '[GRAYHAIRED-LINK20] INFO: reload only the GrayHaired child, then test several MSN links that previously did nothing.\n'
printf '[GRAYHAIRED-LINK20] INFO: this stage records create/new-window requests but deliberately changes no link behavior.\n'
