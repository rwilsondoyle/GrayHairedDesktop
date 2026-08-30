#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-curl-cache-stage5"

fail() {
    printf '[GRAYHAIRED-PHOTO5] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO5] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-PHOTO-LOCAL-CACHE-STAGE4' "$GRID" || \
    fail "photo local-cache Stage 4 is not installed"
grep -Fq 'const Gio = imports.gi.Gio;' "$GRID" || \
    fail "Gio import is missing"
command -v curl >/dev/null 2>&1 || fail "curl is not installed"

if grep -Fq 'GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5' "$GRID"; then
    pass "photo curl-cache Stage 5 is already installed"
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

old = r'''                            // GRAYHAIRED-PHOTO-LOCAL-CACHE-STAGE4
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
                                            `background-image: url("${localUri}"); ` +
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
'''

new = r'''                            // GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5
                            // GIO cannot fetch the page's https:// photo on this system.
                            // Use curl asynchronously to cache the already-discovered active
                            // photo, then point GTK CSS at the local file. Appearance only:
                            // DING geometry, placement, focus, and pointer handling stay intact.
                            try {
                                const localPath = `/tmp/grayhaired-live-photo-${Date.now()}.img`;
                                const process = Gio.Subprocess.new(
                                    [
                                        'curl', '-L', '--fail', '--silent', '--show-error',
                                        '--output', localPath, payload.url
                                    ],
                                    Gio.SubprocessFlags.STDERR_PIPE
                                );

                                process.wait_check_async(null, (subprocess, waitResult) => {
                                    try {
                                        const ok = subprocess.wait_check_finish(waitResult);
                                        if (!ok) {
                                            printerr(`[GRAYHAIRED-PHOTO5] curl failed url=${payload.url}`);
                                            return;
                                        }

                                        const localPhoto = Gio.File.new_for_path(localPath);
                                        const info = localPhoto.query_info(
                                            'standard::size',
                                            Gio.FileQueryInfoFlags.NONE,
                                            null
                                        );
                                        const bytes = info.get_size();
                                        if (bytes <= 0) {
                                            printerr(`[GRAYHAIRED-PHOTO5] downloaded file is empty: ${localPath}`);
                                            return;
                                        }

                                        const localUri = localPhoto.get_uri();
                                        const panelCss = `.grayhaired-photo-continuation { ` +
                                            `background-image: url("${localUri}"); ` +
                                            `background-repeat: no-repeat; ` +
                                            `background-size: ${fullWidth}px ${fullHeight}px; ` +
                                            `background-position: 0px 0px; }`;
                                        this._livePhotoCssProvider.load_from_data(panelCss);
                                        print(
                                            `[GRAYHAIRED-PHOTO5] cached/applied url=${payload.url} ` +
                                            `bytes=${bytes} local=${localUri} ` +
                                            `full=${fullWidth}x${fullHeight} icon=${iconWidth}`
                                        );
                                    } catch (e) {
                                        printerr(`[GRAYHAIRED-PHOTO5] apply failed: ${e.message}`);
                                    }
                                });
                            } catch (e) {
                                printerr(`[GRAYHAIRED-PHOTO5] launch failed: ${e.message}`);
                            }
'''

if old not in text:
    raise SystemExit("expected Stage 4 GIO cache block not found; refusing to patch")

path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-CURL-CACHE-STAGE5' "$GRID" || \
    fail "Stage 5 marker missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO5] cached/applied' "$GRID" || \
    fail "Stage 5 success log marker missing after patch"

pass "photographic curl-cache Stage 5 installed"
printf '[GRAYHAIRED-PHOTO5] INFO: %s\n' \
    "reload only the GrayHaired child; the detected rotating photo will be cached with curl and painted into the icon pane"
