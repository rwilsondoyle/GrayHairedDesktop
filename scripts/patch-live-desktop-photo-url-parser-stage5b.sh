#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-url-parser-stage5b"

fail() {
    printf '[GRAYHAIRED-PHOTO5B] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO5B] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5' "$GRID" || \
    fail "Stage 5 curl-cache experiment is not installed"

if grep -Fq 'GRAYHAIRED-PHOTO-URL-PARSER-STAGE5B' "$GRID"; then
    pass "Stage 5B URL parser fix is already installed"
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

old = r'''                const style = getComputedStyle(document.body);
                const image = String(style.backgroundImage || 'none');
                const match = image.match(/^url\\(["']?(.*?)["']?\\)$/i);
                if (!match || !match[1])
                    return JSON.stringify({ok:false, reason:'no-url', backgroundImage:image});
                return JSON.stringify({
                    ok: true,
                    url: match[1],
'''

new = r'''                const style = getComputedStyle(document.body);
                const image = String(style.backgroundImage || 'none').trim();

                // GRAYHAIRED-PHOTO-URL-PARSER-STAGE5B
                // Parse CSS url(...) without a regex so quotes/parentheses cannot
                // accidentally become part of the URL handed to curl.
                if (!image.toLowerCase().startsWith('url(') || !image.endsWith(')'))
                    return JSON.stringify({ok:false, reason:'no-url', backgroundImage:image});

                let photoUrl = image.slice(4, -1).trim();
                if (photoUrl.length >= 2 &&
                    ((photoUrl.startsWith('"') && photoUrl.endsWith('"')) ||
                     (photoUrl.startsWith("'") && photoUrl.endsWith("'")))) {
                    photoUrl = photoUrl.slice(1, -1);
                }

                if (!/^https?:\/\//i.test(photoUrl))
                    return JSON.stringify({ok:false, reason:'unsupported-url', backgroundImage:image, parsed:photoUrl});

                return JSON.stringify({
                    ok: true,
                    url: photoUrl,
'''

if old not in text:
    raise SystemExit("expected dynamic photo URL discovery block not found; refusing to patch")

path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-URL-PARSER-STAGE5B' "$GRID" || \
    fail "Stage 5B parser marker missing after patch"

pass "dynamic photographic URL parser fixed"
printf '[GRAYHAIRED-PHOTO5B] INFO: %s\n' \
    "reload only the GrayHaired child; curl should now receive a clean https:// URL"
