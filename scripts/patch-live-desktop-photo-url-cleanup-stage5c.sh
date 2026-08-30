#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-url-cleanup-stage5c"

fail() {
    printf '[GRAYHAIRED-PHOTO5C] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO5C] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5' "$GRID" || \
    fail "Stage 5 curl-cache code is not installed"

if grep -Fq 'GRAYHAIRED-PHOTO-URL-CLEANUP-STAGE5C' "$GRID"; then
    pass "Stage 5C URL cleanup is already installed"
    exit 0
fi

if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved one-time rollback copy: $BACKUP"
else
    pass "rollback copy already exists: $BACKUP"
fi

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

anchor = r'''                                const localPath = `/tmp/grayhaired-live-photo-${Date.now()}.img`;
                                const process = Gio.Subprocess.new(
                                    [
                                        'curl', '-L', '--fail', '--silent', '--show-error',
                                        '--output', localPath, payload.url
                                    ],
'''

replacement = r'''                                // GRAYHAIRED-PHOTO-URL-CLEANUP-STAGE5C
                                // Some CSS background-image parsers can leave wrapping
                                // parentheses and/or quotes around the discovered URL.
                                // Normalize immediately before curl so the download path
                                // is independent of which discovery experiment produced it.
                                let photoUrl = String(payload.url || '').trim();
                                if (photoUrl.startsWith('(') && photoUrl.endsWith(')'))
                                    photoUrl = photoUrl.slice(1, -1).trim();
                                while ((photoUrl.startsWith('"') && photoUrl.endsWith('"')) ||
                                       (photoUrl.startsWith("'") && photoUrl.endsWith("'"))) {
                                    photoUrl = photoUrl.slice(1, -1).trim();
                                }
                                if (!/^https:\/\//i.test(photoUrl)) {
                                    printerr(`[GRAYHAIRED-PHOTO5C] invalid cleaned URL raw=${payload.url} cleaned=${photoUrl}`);
                                    return;
                                }
                                print(`[GRAYHAIRED-PHOTO5C] raw=${payload.url} cleaned=${photoUrl}`);

                                const localPath = `/tmp/grayhaired-live-photo-${Date.now()}.img`;
                                const process = Gio.Subprocess.new(
                                    [
                                        'curl', '-L', '--fail', '--silent', '--show-error',
                                        '--output', localPath, photoUrl
                                    ],
'''

if anchor not in text:
    raise SystemExit("expected Stage 5 curl invocation block not found; refusing to patch")

text = text.replace(anchor, replacement, 1)
text = text.replace('`[GRAYHAIRED-PHOTO5] curl failed url=${payload.url}`', '`[GRAYHAIRED-PHOTO5] curl failed url=${photoUrl}`', 1)
text = text.replace('`[GRAYHAIRED-PHOTO5] cached/applied url=${payload.url} ` +', '`[GRAYHAIRED-PHOTO5] cached/applied url=${photoUrl} ` +', 1)

path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-URL-CLEANUP-STAGE5C' "$GRID" || \
    fail "Stage 5C marker missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO5C] raw=' "$GRID" || \
    fail "Stage 5C cleaned-URL log marker missing after patch"

pass "Stage 5C URL cleanup installed"
printf '[GRAYHAIRED-PHOTO5C] INFO: %s\n' \
    "reload only the GrayHaired child, then inspect PHOTO5C and PHOTO5 logs"
