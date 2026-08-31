#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS="$SCRIPT_DIR/wayland-layout-defaults.sh"

fail() {
    printf '[GRAYHAIRED-ADAPTIVE] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-ADAPTIVE] PASS: %s\n' "$*"
}

[[ -f "$DEFAULTS" ]] || fail "shared Wayland defaults are missing: $DEFAULTS"
# shellcheck source=/dev/null
source "$DEFAULTS"

for value_name in \
    GRAYHAIRED_WAYLAND_ICON_COLUMNS \
    GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING \
    GRAYHAIRED_WAYLAND_ICON_STRIP_MIN \
    GRAYHAIRED_WAYLAND_ICON_STRIP_MAX \
    GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK; do
    value="${!value_name:-}"
    [[ "$value" =~ ^[0-9]+$ ]] || fail "$value_name is invalid: ${value:-unset}"
done

[[ -f "$GRID" ]] || fail "installed GrayHaired desktopGrid.js not found: $GRID"

if grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID"; then
    pass "adaptive icon strip is already installed"
    exit 0
fi

# This experiment intentionally patches only the physically verified fixed-width
# GrayHaired layout. Refuse unknown source rather than guessing.
grep -Fq 'const liveIconStripWidth = 220;' "$GRID" || \
    fail "known-good fixed 220px strip marker not found; refusing to patch"
grep -Fq 'this._eventBox.set_size_request(220, -1);' "$GRID" || \
    fail "known-good fixed EventBox width marker not found; refusing to patch"

backup="$GRID.pre-adaptive"
if [[ ! -e "$backup" ]]; then
    cp -a "$GRID" "$backup"
    pass "saved one-time rollback copy: $backup"
else
    pass "rollback copy already exists: $backup"
fi

python3 - \
    "$GRID" \
    "$GRAYHAIRED_WAYLAND_ICON_COLUMNS" \
    "$GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING" \
    "$GRAYHAIRED_WAYLAND_ICON_STRIP_MIN" \
    "$GRAYHAIRED_WAYLAND_ICON_STRIP_MAX" \
    "$GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
columns = int(sys.argv[2])
padding = int(sys.argv[3])
minimum = int(sys.argv[4])
maximum = int(sys.argv[5])
fallback = int(sys.argv[6])

if columns < 1 or columns > 4:
    raise SystemExit("adaptive icon column count outside safe range")
if minimum < 100 or maximum <= minimum:
    raise SystemExit("adaptive icon strip min/max values are invalid")
if not minimum <= fallback <= maximum:
    raise SystemExit("adaptive icon strip fallback is outside min/max range")

text = path.read_text(encoding="utf-8")

old_width = "        const liveIconStripWidth = 220;\n"
new_width = f"""        // GRAYHAIRED-ADAPTIVE-ICON-STRIP
        // DING itself calculates each grid column from get_desired_width()
        // plus four elementSpacing units. Use that same geometry so the
        // live-desktop icon strip follows the user's DING icon-size setting.
        // The width is chosen once when this desktop child starts, preventing
        // the WebKit surface from jumping around while the user is working.
        const liveIconColumns = {columns};
        const liveIconStripPadding = {padding};
        const liveIconStripMin = {minimum};
        const liveIconStripMax = {maximum};
        const liveIconStripFallback = {fallback};
        const liveDesiredCellWidth = Prefs.get_desired_width() + 4 * elementSpacing;
        let liveIconStripWidth = liveIconStripFallback;
        if (Number.isFinite(liveDesiredCellWidth) && liveDesiredCellWidth > 0) {{
            liveIconStripWidth = Math.max(
                liveIconStripMin,
                Math.min(
                    liveIconStripMax,
                    liveIconColumns * liveDesiredCellWidth + liveIconStripPadding
                )
            );
        }}
        print(
            `[GRAYHAIRED-LAYOUT] icon cell=${{liveDesiredCellWidth}}px ` +
            `columns=${{liveIconColumns}} strip=${{liveIconStripWidth}}px`
        );
"""

if old_width not in text:
    raise SystemExit("expected fixed liveIconStripWidth assignment not found")
text = text.replace(old_width, new_width, 1)

old_request = "        this._eventBox.set_size_request(220, -1);\n"
new_request = "        this._eventBox.set_size_request(liveIconStripWidth, -1);\n"
if old_request not in text:
    raise SystemExit("expected fixed EventBox size request not found")
text = text.replace(old_request, new_request, 1)

text = text.replace(
    "constrain DING's usable icon grid to a 220-pixel strip on the left.",
    "constrain DING's usable icon grid to an adaptive strip on the left.",
    1,
)

path.write_text(text, encoding="utf-8")
PY

grep -Fq 'GRAYHAIRED-ADAPTIVE-ICON-STRIP' "$GRID" || fail "adaptive marker missing after patch"
grep -Fq 'Prefs.get_desired_width() + 4 * elementSpacing' "$GRID" || fail "DING geometry formula missing after patch"
grep -Fq 'this._eventBox.set_size_request(liveIconStripWidth, -1);' "$GRID" || fail "adaptive EventBox width missing after patch"

pass "adaptive DING icon-strip patch installed"
printf '[GRAYHAIRED-ADAPTIVE] INFO: %s\n' \
    "restart only the GrayHaired DING/WebKit child when GrayHaired is ACTIVE"
