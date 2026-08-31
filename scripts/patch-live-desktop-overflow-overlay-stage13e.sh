#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
DRAWER="$HOME/.local/bin/grayhaired-desktop-items"
OLD_WATCHER="$HOME/.local/bin/grayhaired-overflow-watch"
OLD_AUTOSTART="$HOME/.config/autostart/grayhaired-overflow-watch.desktop"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[[ -n "$DESKTOP_DIR" ]] || DESKTOP_DIR="$HOME/Desktop"
OLD_TRIGGER="$DESKTOP_DIR/More Desktop Items.desktop"

fail() {
    printf '[GRAYHAIRED-OVERFLOW13E] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-OVERFLOW13E] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"
[[ -x "$DRAWER" ]] || fail "Stage 13 drawer is not installed: $DRAWER"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "known-good Stage 11 marker missing; refusing to patch unknown layout"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "fixed icon boundary marker missing"
if grep -Fq 'GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10' "$GRID"; then
    fail "failed Stage 10 marker is present; refusing to patch"
fi
if grep -Fq 'GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12' "$GRID"; then
    fail "Stage 12 row-density experiment is still installed; roll it back first"
fi

if grep -Fq 'GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E' "$GRID"; then
    pass "Stage 13E conditional overflow overlay is already installed"
    exit 0
fi

# Retire the Stage 13C/13D trigger mechanism. Stage 13E is rendered by the
# GrayHaired child itself and must not consume a DING icon slot.
pkill -f "$OLD_WATCHER" >/dev/null 2>&1 || true
rm -f "$OLD_AUTOSTART" "$OLD_TRIGGER"

BACKUP="$GRID.pre-overflow-overlay-stage13e"
if [[ ! -e "$BACKUP" ]]; then
    cp -a "$GRID" "$BACKUP"
    pass "saved rollback copy: $BACKUP"
else
    pass "rollback copy already exists: $BACKUP"
fi

python3 - "$GRID" "$DRAWER" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
drawer = sys.argv[2]
text = path.read_text(encoding='utf-8')

anchor = "        this._liveLayout.pack_start(this._liveIconBoundary, false, false, 0);\n"
if text.count(anchor) != 1:
    raise SystemExit(f'expected exactly one liveIconBoundary packing anchor, found {text.count(anchor)}')

overlay = f"""        // GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E
        // Keep the proven DING boundary as the main child. The special More
        // control is an overlay, so it never consumes a DING grid slot and
        // cannot change the WebKit/icon-pane split width.
        this._liveIconOverlay = new Gtk.Overlay({{
            can_focus: false,
        }});
        this._liveIconOverlay.add(this._liveIconBoundary);

        this._liveMoreButton = new Gtk.Button({{
            label: '▼  More Desktop Items',
            halign: Gtk.Align.CENTER,
            valign: Gtk.Align.END,
            can_focus: false,
            no_show_all: true,
            tooltip_text: 'Show desktop items that do not fit on screen',
        }});
        this._liveMoreButton.set_margin_start(8);
        this._liveMoreButton.set_margin_end(8);
        this._liveMoreButton.set_margin_bottom(Math.max(
            8,
            (this._desktopDescription.marginBottom || 0) + 8
        ));

        this._liveMoreCss = new Gtk.CssProvider();
        this._liveMoreCss.load_from_data(
            'button.grayhaired-more-items {{' +
            'background: #ff8a00;' +
            'background-image: none;' +
            'color: #111111;' +
            'font-weight: bold;' +
            'border: 2px solid #ffd080;' +
            'border-radius: 8px;' +
            'padding: 8px 12px;' +
            '}}' +
            'button.grayhaired-more-items:hover {{' +
            'background: #ffa733;' +
            'background-image: none;' +
            '}}'
        );
        this._liveMoreButton.get_style_context().add_class('grayhaired-more-items');
        this._liveMoreButton.get_style_context().add_provider(
            this._liveMoreCss,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        );

        this._liveMoreButton.connect('clicked', () => {{
            try {{
                GLib.spawn_command_line_async('{drawer}');
                print('[GRAYHAIRED-OVERFLOW13E] drawer opened');
            }} catch (e) {{
                printerr(`[GRAYHAIRED-OVERFLOW13E] drawer launch failed: ${{e.message}}`);
            }}
        }});
        this._liveIconOverlay.add_overlay(this._liveMoreButton);
        this._liveLayout.pack_start(this._liveIconOverlay, false, false, 0);

        // Re-evaluate periodically so icon-size changes and Desktop folder
        // changes are reflected without reloading the GrayHaired child.
        this._liveOverflowTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1500, () => {{
            this._updateLiveOverflowButton();
            return GLib.SOURCE_CONTINUE;
        }});
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {{
            this._updateLiveOverflowButton();
            return GLib.SOURCE_REMOVE;
        }});
"""
text = text.replace(anchor, overlay, 1)

# Insert the helper immediately before the known-good live-size method. This is
# deliberately self-contained and does not alter DING placement or resize code.
method_anchor = "    // GRAYHAIRED-MANAGER-SYNCED-LIVE-SIZE\n    updateLiveIconBoundaryWidth() {\n"
if text.count(method_anchor) != 1:
    raise SystemExit(f'expected exactly one manager-synced live-size method anchor, found {text.count(method_anchor)}')

helper = """    // GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E
    _updateLiveOverflowButton() {
        if (!this._liveMoreButton)
            return;

        let desktopCount = 0;
        let desktopPath = null;
        try {
            desktopPath = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP);
        } catch (e) {
            desktopPath = null;
        }
        if (!desktopPath)
            desktopPath = GLib.build_filenamev([GLib.get_home_dir(), 'Desktop']);

        try {
            const desktop = Gio.File.new_for_path(desktopPath);
            const enumerator = desktop.enumerate_children(
                'standard::name',
                Gio.FileQueryInfoFlags.NONE,
                null
            );
            let info = null;
            while ((info = enumerator.next_file(null)) !== null) {
                const name = info.get_name();
                if (name === 'More Desktop Items.desktop' ||
                    name.endsWith('.pre-grayhaired-stage13c'))
                    continue;
                desktopCount++;
            }
            enumerator.close(null);
        } catch (e) {
            printerr(`[GRAYHAIRED-OVERFLOW13E] desktop count failed: ${e.message}`);
        }

        // Home and Trash are real DING items on the supported Zorin desktop
        // even though they are not files inside ~/Desktop. Include them in the
        // capacity calculation so the button appears before those special
        // icons or ordinary Desktop items become unreachable.
        const visibleItemCount = desktopCount + 2;
        const desiredRowHeight = Prefs.get_desired_height() + 4 * elementSpacing;
        const rows = Math.max(1, Math.floor(this._height / desiredRowHeight));
        const columns = 2;
        const capacity = Math.max(1, rows * columns);
        const overflow = visibleItemCount > capacity;

        if (this._liveOverflowLastState !== overflow) {
            print(
                `[GRAYHAIRED-OVERFLOW13E] items=${visibleItemCount} ` +
                `height=${this._height}px row=${desiredRowHeight}px ` +
                `rows=${rows} columns=${columns} capacity=${capacity} ` +
                `overflow=${overflow}`
            );
            this._liveOverflowLastState = overflow;
        }

        this._liveMoreButton.set_visible(overflow);
        if (overflow)
            this._liveMoreButton.show();
        else
            this._liveMoreButton.hide();
    }

"""
text = text.replace(method_anchor, helper + method_anchor, 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E' "$GRID" || fail "Stage 13E marker missing"
grep -Fq 'this._liveIconOverlay.add(this._liveIconBoundary);' "$GRID" || fail "DING boundary is not the overlay main child"
grep -Fq "label: '▼  More Desktop Items'" "$GRID" || fail "More button missing"
grep -Fq '_updateLiveOverflowButton()' "$GRID" || fail "conditional overflow evaluator missing"
grep -Fq "GLib.spawn_command_line_async('$DRAWER')" "$GRID" || fail "drawer launcher missing"
if [[ -e "$OLD_TRIGGER" ]]; then
    fail "old DING-slot-consuming More shortcut still exists: $OLD_TRIGGER"
fi

pass "Stage 13E conditional overflow overlay installed"
printf '[GRAYHAIRED-OVERFLOW13E] INFO: %s\n' \
    "reload only the GrayHaired child; Tiny/Small/Standard/Large can then be tested without further reloads"
printf '[GRAYHAIRED-OVERFLOW13E] INFO: %s\n' \
    "the orange More Desktop Items button appears only when the calculated two-column DING grid is overflowing"
