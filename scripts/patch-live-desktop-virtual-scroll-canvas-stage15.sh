#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
BACKUP="$GRID.pre-virtual-scroll-canvas-stage15"

fail() {
    printf '[GRAYHAIRED-SCROLL15] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-SCROLL15] PASS: %s\n' "$*"
}

[[ -f "$GRID" ]] || fail "installed desktopGrid.js not found: $GRID"
grep -Fq 'GRAYHAIRED-COMPRESSED-WIDTH-STAGE11' "$GRID" || \
    fail "known-good Stage 11 marker missing"
grep -Fq 'GRAYHAIRED-FIXED-TWO-COLUMN-BOUNDARY' "$GRID" || \
    fail "known-good fixed two-column boundary marker missing"

for bad in \
    GRAYHAIRED-FIXED-SCROLL-PANE-STAGE10 \
    GRAYHAIRED-LARGE-ROW-DENSITY-STAGE12 \
    GRAYHAIRED-OVERFLOW-OVERLAY-STAGE13E \
    GRAYHAIRED-VERTICAL-SCROLL-STAGE14; do
    if grep -Fq "$bad" "$GRID"; then
        fail "failed experimental marker is still installed: $bad"
    fi
done

if grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID"; then
    pass "Stage 15 virtual scrolling canvas is already installed"
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

# desktopGrid.js does not normally need Gio. Stage 15 uses it only to count
# visible Desktop-folder entries so the virtual canvas is exactly as tall as
# needed instead of inventing a fixed number of extra rows.
if 'const Gio = imports.gi.Gio;' not in text:
    anchor = 'const Gdk = imports.gi.Gdk;\n'
    if anchor not in text:
        raise SystemExit('Gdk import anchor not found')
    text = text.replace(anchor, anchor + 'const Gio = imports.gi.Gio;\n', 1)

# Keep the proven Stage 11 ScrolledWindow and simply allow a vertical bar when
# the child canvas becomes taller than the visible pane.
old_policy = '            vscrollbar_policy: Gtk.PolicyType.NEVER,\n'
new_policy = '            vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,\n'
if old_policy not in text:
    raise SystemExit('known-good vertical scrollbar policy not found')
text = text.replace(old_policy, new_policy, 1)

old_create = """    createGrids() {
        this._width = Math.floor(this._width / this._size_divisor);
        this._height = Math.floor(this._height / this._size_divisor);
        this._marginTop = Math.floor(this._marginTop / this._size_divisor);
        this._marginBottom = Math.floor(this._marginBottom / this._size_divisor);
        this._marginLeft = Math.floor(this._marginLeft / this._size_divisor);
        this._marginRight = Math.floor(this._marginRight / this._size_divisor);
        this._maxColumns = Math.floor(this._width / (Prefs.get_desired_width() + 4 * elementSpacing));
        this._maxRows =  Math.floor(this._height / (Prefs.get_desired_height() + 4 * elementSpacing));
        this._elementWidth = Math.floor(this._width / this._maxColumns);
        this._elementHeight = Math.floor(this._height / this._maxRows);
    }
"""

new_create = """    // GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15
    _grayhairedScrollableItemCount() {
        let count = 0;

        // Count the regular files/launchers DING can place from ~/Desktop.
        // Ignore hidden files and the backups created by our retired tests.
        try {
            const desktopPath = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_DESKTOP) ||
                GLib.build_filenamev([GLib.get_home_dir(), 'Desktop']);
            const desktop = Gio.File.new_for_path(desktopPath);
            const enumerator = desktop.enumerate_children(
                'standard::name,standard::is-hidden',
                Gio.FileQueryInfoFlags.NOFOLLOW_SYMLINKS,
                null
            );
            let info;
            while ((info = enumerator.next_file(null)) !== null) {
                const name = info.get_name();
                if (!name || info.get_is_hidden() ||
                    name.endsWith('.pre-grayhaired-stage13c'))
                    continue;
                count++;
            }
            enumerator.close(null);
        } catch (e) {
            print(`[GRAYHAIRED-SCROLL15] desktop count failed: ${e.message}`);
        }

        // Home and Trash are DING special icons, not files in ~/Desktop.
        // Zorin has used more than one key spelling over time, so inspect the
        // schema and fall back to the physically observed Home + Trash pair.
        let special = 0;
        let matchedSpecialKey = false;
        try {
            const keys = Prefs.desktopSettings.list_keys();
            for (const candidate of [
                'show-home', 'show-home-icon', 'show-home-folder',
                'show-trash', 'show-trash-icon',
            ]) {
                if (!keys.includes(candidate))
                    continue;
                matchedSpecialKey = true;
                try {
                    if (Prefs.desktopSettings.get_boolean(candidate))
                        special++;
                } catch (e) {
                    // Ignore a candidate with an unexpected type.
                }
            }
        } catch (e) {
            matchedSpecialKey = false;
        }
        if (!matchedSpecialKey)
            special = 2;

        return count + special;
    }

    createGrids() {
        this._width = Math.floor(this._width / this._size_divisor);
        this._height = Math.floor(this._height / this._size_divisor);
        this._marginTop = Math.floor(this._marginTop / this._size_divisor);
        this._marginBottom = Math.floor(this._marginBottom / this._size_divisor);
        this._marginLeft = Math.floor(this._marginLeft / this._size_divisor);
        this._marginRight = Math.floor(this._marginRight / this._size_divisor);

        const desiredCellWidth = Prefs.get_desired_width() + 4 * elementSpacing;
        const desiredCellHeight = Prefs.get_desired_height() + 4 * elementSpacing;
        this._maxColumns = Math.max(1, Math.floor(this._width / desiredCellWidth));

        // The visible monitor remains unchanged. Only DING's internal icon
        // canvas grows when more rows are needed than fit on screen.
        const visibleHeight = this._height;
        const visibleRows = Math.max(1, Math.floor(visibleHeight / desiredCellHeight));
        const itemCount = this._grayhairedScrollableItemCount();
        const requiredRows = Math.max(1, Math.ceil(itemCount / this._maxColumns));
        this._maxRows = Math.max(visibleRows, requiredRows);

        if (this._maxRows > visibleRows)
            this._height = this._maxRows * desiredCellHeight;

        this._elementWidth = Math.floor(this._width / this._maxColumns);
        this._elementHeight = Math.floor(this._height / this._maxRows);

        // Gtk.ScrolledWindow only gets a scrollbar when its child really has
        // a larger natural/minimum height. Grow Gtk.Fixed, not the EventBox's
        // width, so Stage 11's proven horizontal boundary remains untouched.
        if (this._container)
            this._container.set_size_request(-1, this._height);

        print(
            `[GRAYHAIRED-SCROLL15] items=${itemCount} columns=${this._maxColumns} ` +
            `visibleRows=${visibleRows} rows=${this._maxRows} ` +
            `visibleHeight=${visibleHeight}px canvasHeight=${this._height}px`
        );
    }
"""

if old_create not in text:
    raise SystemExit('known-good createGrids() block not found')
text = text.replace(old_create, new_create, 1)

# Stage 15 needs GLib for the standard Desktop directory lookup. Most Zorin
# DING builds already import it; add it only if this copy does not.
if 'const GLib = imports.gi.GLib;' not in text:
    anchor = 'const Gio = imports.gi.Gio;\n'
    if anchor not in text:
        raise SystemExit('Gio import anchor not found while adding GLib')
    text = text.replace(anchor, anchor + 'const GLib = imports.gi.GLib;\n', 1)

path.write_text(text, encoding='utf-8')
PY

grep -Fq 'GRAYHAIRED-VIRTUAL-SCROLL-CANVAS-STAGE15' "$GRID" || \
    fail "Stage 15 marker missing after patch"
grep -Fq 'vscrollbar_policy: Gtk.PolicyType.AUTOMATIC' "$GRID" || \
    fail "automatic vertical scrollbar policy missing"
grep -Fq '_grayhairedScrollableItemCount()' "$GRID" || \
    fail "Stage 15 item counter missing"
grep -Fq 'this._container.set_size_request(-1, this._height);' "$GRID" || \
    fail "virtual canvas height request missing"

pass "Stage 15 virtual scrolling icon canvas experiment installed"
printf '[GRAYHAIRED-SCROLL15] INFO: %s\n' \
    "Reload only the GrayHaired child, then test Tiny, Small, Standard, and Large."
printf '[GRAYHAIRED-SCROLL15] INFO: %s\n' \
    "A normal vertical scrollbar should appear only when required rows exceed visible rows."
printf '[GRAYHAIRED-SCROLL15] INFO: %s\n' \
    "Stage 11 pane width and WebKit allocation are not changed."
