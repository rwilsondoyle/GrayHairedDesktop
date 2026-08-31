#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-microsoft-auth-handoff-stage20c"

fail() {
    printf '[GRAYHAIRED-LINK20C] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-LINK20C] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-CREATE-HANDOFF-STAGE20' "$GRID" || fail "Stage 20 create handoff must be installed first"
grep -Fq 'GRAYHAIRED-NAVIGATION-DIAGNOSTICS-STAGE20B' "$GRID" || fail "Stage 20B navigation diagnostics must be installed first"
grep -Fq 'GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19' "$GRID" || fail "Stage 19 local-file guard is missing"

if grep -Fq 'GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20C' "$GRID"; then
    pass "Stage 20C Microsoft auth handoff is already installed"
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

anchor = """                // GRAYHAIRED-BLOCK-LOCAL-FILE-DROP-STAGE19
"""
insert = """                // GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20C
                // MSN performs silent Microsoft-account probes during ordinary
                // page load. Do NOT hand those to the browser. The explicit
                // Sign in action observed in physical testing transitions to an
                // interactive OAuth request with prompt=select_account. Hand
                // only that narrow Microsoft authorization request to the
                // default browser, leaving all other same-window navigation
                // under WebKit's existing policy.
                const isInteractiveMicrosoftAuth = uri &&
                    uri.startsWith('https://login.microsoftonline.com/') &&
                    uri.includes('/oauth2/v2.0/authorize') &&
                    uri.includes('prompt=select_account');

                if (isInteractiveMicrosoftAuth) {
                    try {
                        print(`[GRAYHAIRED-LINK20C] handoff Microsoft sign-in uri=${uri}`);
                        Gio.AppInfo.launch_default_for_uri(uri, null);
                        decision.ignore();
                        return true;
                    } catch (e) {
                        printerr(`[GRAYHAIRED-LINK20C] Microsoft sign-in handoff failed: ${e.message}`);
                        return false;
                    }
                }

"""

if anchor not in text:
    raise SystemExit('Stage 19 navigation-policy anchor not found')

text = text.replace(anchor, insert + anchor, 1)
path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-MICROSOFT-AUTH-HANDOFF-STAGE20C' "$GRID" || fail "Stage 20C marker missing after patch"
grep -Fq '[GRAYHAIRED-LINK20C] handoff Microsoft sign-in uri=' "$GRID" || fail "Stage 20C diagnostic log missing"

pass "Stage 20C narrow Microsoft sign-in handoff installed"
printf '[GRAYHAIRED-LINK20C] INFO: reload only the GrayHaired child, then click MSN Sign in once.\n'
printf '[GRAYHAIRED-LINK20C] INFO: expected: Microsoft sign-in opens in the default browser while MSN remains on the desktop.\n'
printf '[GRAYHAIRED-LINK20C] INFO: silent prompt=none account probes must remain inside WebKit and must not open browser windows.\n'
