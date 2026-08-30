#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-continuation-stage3"

fail() {
    printf '[GRAYHAIRED-PHOTO3] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO3] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-AUTOMATIC-BLEND-STAGE2' "$GRID" || \
    fail "Automatic Blend Stage 2 is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC' "$GRID" || \
    fail "photo diagnostic marker not found"
grep -Fq "https://grayhaired.tech/desktop-c" "$GRID" || \
    fail "installed live URL is not desktop-c"

if grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID"; then
    pass "photo continuation Stage 3 is already installed"
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

anchor = """        // GRAYHAIRED-PHOTO-BACKGROUND-DIAGNOSTIC\n"""
if anchor not in text:
    raise SystemExit("photo diagnostic anchor not found")

setup = """        // GRAYHAIRED-PHOTO-CONTINUATION-STAGE3
        // Reversible photographic continuation experiment for desktop-c.
        // Detect the currently active BODY background image on every page load
        // so rotating photographic backgrounds are followed automatically.
        // Appearance only: DING geometry, placement, focus, and input are untouched.
        this._livePhotoCssProvider = new Gtk.CssProvider();
        this._livePhotoStyleContext = this._eventBox.get_style_context();
        this._livePhotoStyleContext.add_class('grayhaired-photo-continuation');
        this._livePhotoStyleContext.add_provider(
            this._livePhotoCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

"""
text = text.replace(anchor, setup + anchor, 1)

callback_anchor = """            if (loadEvent !== WebKit2.LoadEvent.FINISHED)
                return;

            const photoDiagnosticScript = `(() => {
"""
if callback_anchor not in text:
    raise SystemExit("photo load callback anchor not found")

callback_replacement = r'''            if (loadEvent !== WebKit2.LoadEvent.FINISHED)
                return;

            // First discover whichever photographic BODY background this load chose.
            const livePhotoDiscoveryScript = `(() => {
                if (!document.body)
                    return JSON.stringify({ok:false, reason:'no-body'});
                const style = getComputedStyle(document.body);
                const image = String(style.backgroundImage || 'none');
                const match = image.match(/^url\(["']?(.*?)["']?\)$/i);
                if (!match || !match[1])
                    return JSON.stringify({ok:false, reason:'no-url', backgroundImage:image});
                return JSON.stringify({
                    ok: true,
                    url: match[1],
                    size: String(style.backgroundSize || ''),
                    position: String(style.backgroundPosition || ''),
                    repeat: String(style.backgroundRepeat || ''),
                    attachment: String(style.backgroundAttachment || '')
                });
            })()`;

            try {
                webView.evaluate_javascript(
                    livePhotoDiscoveryScript,
                    -1,
                    null,
                    null,
                    null,
                    (source, result) => {
                        try {
                            const value = source.evaluate_javascript_finish(result);
                            const payload = JSON.parse(value.to_string());
                            if (!payload.ok || !payload.url) {
                                print(`[GRAYHAIRED-PHOTO3] no-photo ${value.to_string()}`);
                                return;
                            }

                            const fullWidth = Math.max(1, this._liveLayout.get_allocated_width());
                            const fullHeight = Math.max(1, this._liveLayout.get_allocated_height());
                            const iconWidth = this._liveIconBoundary
                                ? Math.max(1, this._liveIconBoundary.get_allocated_width())
                                : Math.max(1, this._eventBox.get_allocated_width());
                            const safeUrl = String(payload.url).replace(/"/g, '\\"');

                            // For this visual experiment use one shared full-desktop image
                            // coordinate system. That guarantees continuity at the seam.
                            const panelCss = `.grayhaired-photo-continuation { ` +
                                `background-image: url("${safeUrl}"); ` +
                                `background-repeat: no-repeat; ` +
                                `background-size: ${fullWidth}px ${fullHeight}px; ` +
                                `background-position: 0px 0px; }`;
                            this._livePhotoCssProvider.load_from_data(panelCss);

                            const webPhotoScript = `(() => {
                                if (!document.body) return 'no-body';
                                document.body.style.backgroundImage = 'url("${safeUrl}")';
                                document.body.style.backgroundRepeat = 'no-repeat';
                                document.body.style.backgroundAttachment = 'fixed';
                                document.body.style.backgroundSize = '${fullWidth}px ${fullHeight}px';
                                document.body.style.backgroundPosition = '-${iconWidth}px 0px';
                                return JSON.stringify({
                                    photo: '${safeUrl}',
                                    fullWidth:${fullWidth},
                                    fullHeight:${fullHeight},
                                    iconWidth:${iconWidth}
                                });
                            })()`;

                            webView.evaluate_javascript(
                                webPhotoScript, -1, null, null, null,
                                (webSource, webResult) => {
                                    try {
                                        const applied = webSource.evaluate_javascript_finish(webResult);
                                        print(`[GRAYHAIRED-PHOTO3] applied ${applied.to_string()}`);
                                    } catch (e) {
                                        printerr(`[GRAYHAIRED-PHOTO3] WebKit apply failed: ${e.message}`);
                                    }
                                }
                            );
                        } catch (e) {
                            printerr(`[GRAYHAIRED-PHOTO3] discovery/apply failed: ${e.message}`);
                        }
                    }
                );
            } catch (e) {
                printerr(`[GRAYHAIRED-PHOTO3] discovery launch failed: ${e.message}`);
            }

            const photoDiagnosticScript = `(() => {
'''
text = text.replace(callback_anchor, callback_replacement, 1)

path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID" || \
    fail "Stage 3 marker missing after patch"
grep -Fq 'livePhotoDiscoveryScript' "$GRID" || \
    fail "dynamic photo discovery code missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO3] applied' "$GRID" || \
    fail "Stage 3 apply log missing after patch"

pass "dynamic photographic continuation Stage 3 installed"
printf '[GRAYHAIRED-PHOTO3] INFO: %s\n' \
    "reload only the GrayHaired child; whichever photo desktop-c selected should continue behind the icon pane"
