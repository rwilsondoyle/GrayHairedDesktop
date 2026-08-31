#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-photo-scroll-canvas-stage16"

fail() {
    printf '[GRAYHAIRED-PHOTO16] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-PHOTO16] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID" || \
    fail "Stage 15 virtual scroll canvas is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-LIVE-REFLOW-STAGE7' "$GRID" || \
    fail "Stage 7 photo live reflow is not installed"
grep -Fq 'GRAYHAIRED-PHOTO-CONTINUATION-STAGE3' "$GRID" || \
    fail "Stage 3 photo continuation is not installed"

if grep -Fq 'GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16' "$GRID"; then
    pass "Stage 16 photo scroll-canvas continuation is already installed"
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

# Apply the photographic CSS provider to both the visible EventBox and the
# taller Stage-15 Gtk.Fixed canvas. The EventBox keeps the seam aligned with
# WebKit; the canvas paints the region revealed by vertical scrolling.
old_setup = """        this._livePhotoCssProvider = new Gtk.CssProvider();
        this._livePhotoStyleContext = this._eventBox.get_style_context();
        this._livePhotoStyleContext.add_class('grayhaired-photo-continuation');
        this._livePhotoStyleContext.add_provider(
            this._livePhotoCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
"""
new_setup = """        // GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16
        this._livePhotoCssProvider = new Gtk.CssProvider();
        this._livePhotoStyleContext = this._eventBox.get_style_context();
        this._livePhotoStyleContext.add_class('grayhaired-photo-continuation');
        this._livePhotoStyleContext.add_provider(
            this._livePhotoCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        // Stage 15 can make Gtk.Fixed taller than the visible monitor. Give
        // that virtual canvas the same photo style so scrolling never reveals
        // the default gray/black widget background.
        this._livePhotoCanvasStyleContext = this._container.get_style_context();
        this._livePhotoCanvasStyleContext.add_class('grayhaired-photo-continuation');
        this._livePhotoCanvasStyleContext.add_provider(
            this._livePhotoCssProvider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );
"""
if old_setup not in text:
    raise SystemExit('photo CSS setup anchor not found')
text = text.replace(old_setup, new_setup, 1)

# The top viewport must retain the exact full-screen crop that already aligns
# with WebKit. Do not stretch that crop to the taller virtual canvas; tile the
# same photographic viewport vertically through the overflow area instead.
# Limit replacements to CSS panel rules, leaving WebKit body no-repeat intact.
old_panel = """        const panelCss = `.grayhaired-photo-continuation { ` +
            `background-image: url(\"${localUri}\"); ` +
            `background-repeat: no-repeat; ` +
            `background-size: ${fullWidth}px ${fullHeight}px; ` +
            `background-position: 0px 0px; }`;
"""
new_panel = """        const panelCss = `.grayhaired-photo-continuation { ` +
            `background-image: url(\"${localUri}\"); ` +
            `background-repeat: repeat-y; ` +
            `background-size: ${fullWidth}px ${fullHeight}px; ` +
            `background-position: 0px 0px; }`;
"""
if old_panel not in text:
    raise SystemExit('Stage 7 local-photo panel CSS anchor not found')
text = text.replace(old_panel, new_panel, 1)

# Also update the initial photographic panel rule used before Stage 7's first
# geometry reflow. Its URL variable may be safeUrl or localUri depending on the
# promoted cache chain, so replace only the unique panel-rule fragment.
needle = "`background-repeat: no-repeat; ` +\n                                `background-size: ${fullWidth}px ${fullHeight}px; ` +\n                                `background-position: 0px 0px; }`;"
replacement = "`background-repeat: repeat-y; ` +\n                                `background-size: ${fullWidth}px ${fullHeight}px; ` +\n                                `background-position: 0px 0px; }`;"
if needle in text:
    text = text.replace(needle, replacement, 1)

# Stage 7 previously cached geometry using only monitor size + icon width.
# Tiny and Small can share the same Stage-11 pane width while Stage 15 gives
# them different canvas heights, so canvas height must participate in the key.
old_geometry = """        const iconWidth = this._liveIconBoundary
            ? Math.max(1, this._liveIconBoundary.get_allocated_width())
            : Math.max(1, this._eventBox.get_allocated_width());
        const geometry = `${fullWidth}x${fullHeight}:${iconWidth}`;
"""
new_geometry = """        const iconWidth = this._liveIconBoundary
            ? Math.max(1, this._liveIconBoundary.get_allocated_width())
            : Math.max(1, this._eventBox.get_allocated_width());
        const canvasHeight = this._container
            ? Math.max(fullHeight, this._container.get_allocated_height())
            : fullHeight;
        const geometry = `${fullWidth}x${fullHeight}:${iconWidth}:${canvasHeight}`;
"""
if old_geometry not in text:
    raise SystemExit('Stage 7 geometry-key anchor not found')
text = text.replace(old_geometry, new_geometry, 1)

old_log = """                        print(
                            `[GRAYHAIRED-PHOTO7] reflow full=${fullWidth}x${fullHeight} ` +
                            `icon=${iconWidth}`
                        );
"""
new_log = """                        print(
                            `[GRAYHAIRED-PHOTO7] reflow full=${fullWidth}x${fullHeight} ` +
                            `icon=${iconWidth}`
                        );
                        print(
                            `[GRAYHAIRED-PHOTO16] canvas=${canvasHeight}px ` +
                            `tile=${fullWidth}x${fullHeight}px repeat=vertical`
                        );
"""
if old_log not in text:
    raise SystemExit('Stage 7 reflow log anchor not found')
text = text.replace(old_log, new_log, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-PHOTO-SCROLL-CANVAS-STAGE16' "$GRID" || \
    fail "Stage 16 marker missing after patch"
grep -Fq '_livePhotoCanvasStyleContext' "$GRID" || \
    fail "scroll-canvas photo style context missing"
grep -Fq 'background-repeat: repeat-y' "$GRID" || \
    fail "vertical photo tiling rule missing"
grep -Fq '[GRAYHAIRED-PHOTO16] canvas=' "$GRID" || \
    fail "Stage 16 diagnostic log missing"

pass "Stage 16 photo continuation across the Stage 15 scroll canvas installed"
printf '[GRAYHAIRED-PHOTO16] INFO: %s\n' \
    "reload only the GrayHaired child; then test Small, Standard, and Large by scrolling to the bottom"
printf '[GRAYHAIRED-PHOTO16] INFO: %s\n' \
    "the visible photo crop stays aligned with WebKit and repeats vertically only in the off-screen overflow canvas"
