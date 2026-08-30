#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-local-cache-stage4"

fail() {
    printf '[GRAYHAIRED-PHOTO4] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO4] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID" || \
    fail "dynamic photographic continuation Stage 3 is not installed"
grep -Fq 'const Gio = imports.gi.Gio;' "$GRID" || \
    fail "Gio import is missing from known-good WebKit link handoff"

if grep -Fq 'GRAYHAIRED-PHOTO-LOCAL-CACHE-STAGE4' "$GRID"; then
    pass "photo local-cache Stage 4 is already installed"
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
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# Match the Stage 3 remote GTK panel structurally rather than depending on
# exact prose or quote escaping. The boundaries are stable parts of the
# promoted Stage 3 implementation: its shared-coordinate comment and the
# WebKit-side photo script that follows the GTK panel setup.
pattern = re.compile(
    r'''                            // For (?:this visual experiment|photographic pages) use one shared full-desktop image\n'''
    r'''                            // coordinate system\. That guarantees continuity at the seam\.\n'''
    r'''                            const panelCss = .*?\n'''
    r'''                            this\._livePhotoCssProvider\.load_from_data\(panelCss\);\n\n'''
    r'''                            const webPhotoScript = `\(\(\) => \{\n''',
    re.DOTALL,
)

new = r'''                            // GRAYHAIRED-PHOTO-LOCAL-CACHE-STAGE4
                            // GTK's CSS provider does not reliably paint remote https://
                            // background-image URLs. Cache the currently selected page
                            // photograph locally first, then use a file:// URL for only
                            // the real DING icon pane. The main WebKit surface continues
                            // to use the page-selected remote image.
                            try {
                                const remotePhoto = Gio.File.new_for_uri(payload.url);
                                remotePhoto.load_contents_async(null, (remoteFile, loadResult) => {
                                    try {
                                        const [ok, contents] = remoteFile.load_contents_finish(loadResult);
                                        if (!ok || !contents || contents.length === 0) {
                                            print(`[GRAYHAIRED-PHOTO4] download-empty url=${payload.url}`);
                                            return;
                                        }

                                        const localPath = `/tmp/grayhaired-live-photo-${Date.now()}.img`;
                                        const localPhoto = Gio.File.new_for_path(localPath);
                                        localPhoto.replace_contents(
                                            contents,
                                            null,
                                            false,
                                            Gio.FileCreateFlags.REPLACE_DESTINATION,
                                            null
                                        );

                                        const localUri = localPhoto.get_uri();
                                        const panelCss = `.grayhaired-photo-continuation { ` +
                                            `background-image: url(\"${localUri}\"); ` +
                                            `background-repeat: no-repeat; ` +
                                            `background-size: ${fullWidth}px ${fullHeight}px; ` +
                                            `background-position: 0px 0px; }`;
                                        this._livePhotoCssProvider.load_from_data(panelCss);
                                        print(
                                            `[GRAYHAIRED-PHOTO4] cached url=${payload.url} ` +
                                            `bytes=${contents.length} local=${localUri} ` +
                                            `full=${fullWidth}x${fullHeight} icon=${iconWidth}`
                                        );
                                    } catch (e) {
                                        printerr(`[GRAYHAIRED-PHOTO4] cache/apply failed: ${e.message}`);
                                    }
                                });
                            } catch (e) {
                                printerr(`[GRAYHAIRED-PHOTO4] cache launch failed: ${e.message}`);
                            }

                            const webPhotoScript = `(() => {
'''

text2, count = pattern.subn(lambda _m: new, text, count=1)
if count != 1:
    raise SystemExit(
        f"expected exactly one Stage 3 remote GTK panel CSS block, found {count}; refusing to patch"
    )

path.write_text(text2, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-LOCAL-CACHE-STAGE4' "$GRID" || \
    fail "Stage 4 marker missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO4] cached url=' "$GRID" || \
    fail "Stage 4 cache-success log missing after patch"

pass "photographic local-cache Stage 4 installed"
printf '[GRAYHAIRED-PHOTO4] INFO: %s\n' \
    "reload only the GrayHaired child; GTK should now paint a local copy of whichever photo the live page selected"
