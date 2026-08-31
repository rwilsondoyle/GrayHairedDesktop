#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-live-reflow-stage7"

fail() {
    printf '[GRAYHAIRED-PHOTO7] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO7] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6' "$GRID" || \
    fail "Stage 6 wallpaper synchronization is not installed"
grep -Fq 'updateLiveIconBoundaryWidth()' "$GRID" || \
    fail "live icon boundary reflow method is missing"

if grep -Fq 'GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7' "$GRID"; then
    pass "photo live-reflow Stage 7 is already installed"
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
text = path.read_text(encoding='utf-8')

# Remember the currently active local and remote photo immediately after the
# Stage 5C cache succeeds. The existing Stage 5/6 application logic remains in
# place; Stage 7 only adds the state needed for later geometry changes.
local_anchor = """                                        const localUri = localPhoto.get_uri();\n\n                                        // GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6\n"""
local_replacement = """                                        const localUri = localPhoto.get_uri();\n\n                                        // GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7\n                                        // Keep the active photo available after the page-load\n                                        // callback so icon-size/layout changes can realign it.\n                                        this._livePhotoActiveLocalUri = localUri;\n                                        this._livePhotoActiveRemoteUrl = photoUrl;\n                                        this._livePhotoLastGeometry = '';\n\n                                        // GRAYHAIRED-GNOME-WALLPAPER-SYNC-STAGE6\n"""
if local_anchor not in text:
    raise SystemExit('Stage 6 cached-photo anchor not found')
text = text.replace(local_anchor, local_replacement, 1)

# Connect to the Gtk layout's allocation changes. This is the safest place to
# react because by then GTK has assigned the new icon-strip and WebKit widths.
layout_anchor = """        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n\n        this._window.add(this._liveLayout);\n"""
layout_replacement = """        this._liveLayout.pack_start(this._liveWebView, true, true, 0);\n\n        // GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7\n        // Reapply active photographic geometry after GTK reallocates the\n        // split surface (for example after DING icon-size changes).\n        this._liveLayout.connect('size-allocate', () => {\n            if (this.updateLivePhotoGeometry)\n                this.updateLivePhotoGeometry();\n        });\n\n        this._window.add(this._liveLayout);\n"""
if layout_anchor not in text:
    raise SystemExit('live layout pack/window anchor not found')
text = text.replace(layout_anchor, layout_replacement, 1)

# Add one reusable geometry method immediately before the existing live icon
# boundary method. It updates both sides from the same full-desktop coordinate
# system and skips redundant work when the allocation has not changed.
method_anchor = """    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n    updateLiveIconBoundaryWidth() {\n"""
method_replacement = r'''    // GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7
    updateLivePhotoGeometry() {
        if (!this._livePhotoActiveLocalUri ||
            !this._livePhotoActiveRemoteUrl ||
            !this._livePhotoCssProvider ||
            !this._liveWebView ||
            !this._liveLayout)
            return;

        const fullWidth = Math.max(1, this._liveLayout.get_allocated_width());
        const fullHeight = Math.max(1, this._liveLayout.get_allocated_height());
        const iconWidth = this._liveIconBoundary
            ? Math.max(1, this._liveIconBoundary.get_allocated_width())
            : Math.max(1, this._eventBox.get_allocated_width());
        const geometry = `${fullWidth}x${fullHeight}:${iconWidth}`;
        if (geometry === this._livePhotoLastGeometry)
            return;
        this._livePhotoLastGeometry = geometry;

        const localUri = String(this._livePhotoActiveLocalUri).replace(/"/g, '\\"');
        const remoteUrl = String(this._livePhotoActiveRemoteUrl).replace(/"/g, '\\"');

        const panelCss = `.grayhaired-photo-continuation { ` +
            `background-image: url("${localUri}"); ` +
            `background-repeat: no-repeat; ` +
            `background-size: ${fullWidth}px ${fullHeight}px; ` +
            `background-position: 0px 0px; }`;
        this._livePhotoCssProvider.load_from_data(panelCss);

        const webPhotoScript = `(() => {
            if (!document.body) return 'no-body';
            document.body.style.backgroundImage = 'url("${remoteUrl}")';
            document.body.style.backgroundRepeat = 'no-repeat';
            document.body.style.backgroundAttachment = 'fixed';
            document.body.style.backgroundSize = '${fullWidth}px ${fullHeight}px';
            document.body.style.backgroundPosition = '-${iconWidth}px 0px';
            return 'ok';
        })()`;

        try {
            this._liveWebView.evaluate_javascript(
                webPhotoScript, -1, null, null, null,
                (source, result) => {
                    try {
                        source.evaluate_javascript_finish(result);
                        print(
                            `[GRAYHAIRED-PHOTO7] reflow full=${fullWidth}x${fullHeight} ` +
                            `icon=${iconWidth}`
                        );
                    } catch (e) {
                        printerr(`[GRAYHAIRED-PHOTO7] WebKit reflow failed: ${e.message}`);
                    }
                }
            );
        } catch (e) {
            printerr(`[GRAYHAIRED-PHOTO7] reflow launch failed: ${e.message}`);
        }
    }

    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE
    updateLiveIconBoundaryWidth() {
'''
if method_anchor not in text:
    raise SystemExit('live icon boundary method anchor not found')
text = text.replace(method_anchor, method_replacement, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7' "$GRID" || \
    fail "Stage 7 marker missing after patch"
grep -Fq 'updateLivePhotoGeometry()' "$GRID" || \
    fail "Stage 7 geometry method missing after patch"
grep -Fq "this._liveLayout.connect('size-allocate'" "$GRID" || \
    fail "Stage 7 layout allocation hook missing after patch"
grep -Fq '[GRAYHAIRED-PHOTO7] reflow full=' "$GRID" || \
    fail "Stage 7 reflow log marker missing after patch"

pass "photographic live-size reflow Stage 7 installed"
printf '[GRAYHAIRED-PHOTO7] INFO: %s\n' \
    "reload only the GrayHaired child once; then resize DING icons without reloading"
