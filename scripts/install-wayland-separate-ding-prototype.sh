#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
SYSTEM_EXT="/usr/share/gnome-shell/extensions/$SYSTEM_UUID"
USER_ROOT="$HOME/.local/share/gnome-shell/extensions"
TEST_EXT="$USER_ROOT/$TEST_UUID"
GRID="$TEST_EXT/app/desktopGrid.js"
META="$TEST_EXT/metadata.json"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS="$SCRIPT_DIR/wayland-layout-defaults.sh"

if [[ ! -f "$DEFAULTS" ]]; then
    echo "Shared Wayland layout defaults are missing:"
    echo "  $DEFAULTS"
    exit 2
fi
# shellcheck source=/dev/null
source "$DEFAULTS"

for value_name in \
    GRAYHAIRED_WAYLAND_ICON_COLUMNS \
    GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING \
    GRAYHAIRED_WAYLAND_ICON_STRIP_MIN \
    GRAYHAIRED_WAYLAND_ICON_STRIP_MAX \
    GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK; do
    value="${!value_name:-}"
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        echo "Invalid adaptive Wayland layout default: $value_name=${value:-unset}"
        exit 2
    fi
done

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    echo "This prototype installer is intended for a Wayland login."
    echo "Current session: ${XDG_SESSION_TYPE:-unknown}"
    exit 2
fi

if [[ ! -d "$SYSTEM_EXT" ]]; then
    echo "System Zorin desktop-icons extension not found:"
    echo "  $SYSTEM_EXT"
    exit 2
fi

# Refuse to build from an unverified Zorin/DING base. This read-only preflight
# catches structural changes from future Zorin updates before the user-local
# GrayHaired tree is replaced.
bash "$SCRIPT_DIR/check-wayland-zorin-base.sh"

if pgrep -f '/zorin-desktop-icons@zorinos.com/app/ding.js' >/dev/null 2>&1; then
    echo "The normal Zorin DING process is still running."
    echo "Disable it first with:"
    echo "  gnome-extensions disable $SYSTEM_UUID"
    exit 2
fi

if pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' >/dev/null 2>&1; then
    echo "The GrayHaired Wayland prototype DING process is still running."
    echo "This installer replaces the user-local extension tree, so use it only for installation/reinstallation."
    echo "For normal development reloads use:"
    echo "  bash $SCRIPT_DIR/reload-grayhaired.sh"
    exit 2
fi

mkdir -p "$USER_ROOT"
rm -rf "$TEST_EXT"
cp -a "$SYSTEM_EXT" "$TEST_EXT"

python3 - "$META" "$TEST_UUID" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
uuid = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
data["uuid"] = uuid
data["name"] = "GrayHaired Live Desktop Wayland Prototype"
data["description"] = (
    "Research-only GrayHairedDesktop copy of Zorin Desktop Icons with a "
    "dedicated adaptive DING icon strip and live My Desktop WebKit surface."
)
path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
PY

# First construct the physically proven split surface using the safe fallback
# width. The adaptive patch immediately below then replaces the fixed width
# with DING-derived startup geometry. Keeping these steps separate preserves
# the well-tested structural patch and gives the adaptive patch a known input.
python3 - "$GRID" "$GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK" "$GRAYHAIRED_WAYLAND_DESKTOP_URL" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
strip_width = int(sys.argv[2])
desktop_url = sys.argv[3]
text = path.read_text(encoding="utf-8")

if strip_width < 100:
    raise SystemExit("Wayland fallback icon strip width is unexpectedly small; refusing to patch")
if not desktop_url.startswith("https://"):
    raise SystemExit("Wayland desktop URL must use HTTPS; refusing to patch")

old_imports = """'use strict';
const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
"""
new_imports = """'use strict';
imports.gi.versions.WebKit2 = '4.1';
const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const WebKit2 = imports.gi.WebKit2;
"""
if old_imports not in text:
    raise SystemExit("Expected desktopGrid.js import block not found; refusing to patch")
text = text.replace(old_imports, new_imports, 1)

old_description = """        this._desktopDescription = desktopDescription;
        this.updateWindowGeometry();
        this.updateUnscaledHeightWidthMargins();
"""
new_description = f"""        // GrayHairedDesktop Wayland research prototype:
        // keep the top-level desktop window at the monitor's full size, but
        // constrain DING's usable icon grid to a {strip_width}-pixel fallback
        // strip on the left. The adaptive installer step replaces this fixed
        // width with DING-derived geometry before verification completes.
        desktopDescription = Object.assign({{}}, desktopDescription);
        const liveIconStripWidth = {strip_width};
        desktopDescription.marginRight = Math.max(
            desktopDescription.marginRight,
            desktopDescription.width - desktopDescription.marginLeft - liveIconStripWidth
        );
        this._desktopDescription = desktopDescription;
        this.updateWindowGeometry();
        this.updateUnscaledHeightWidthMargins();
"""
if old_description not in text:
    raise SystemExit("Expected desktop description block not found; refusing to patch")
text = text.replace(old_description, new_description, 1)

old_widgets = """        this._eventBox = new Gtk.EventBox({visible: true});
        this.sizeEventBox();
        this._window.add(this._eventBox);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);
        this.gridGlobalRectangle = new Gdk.Rectangle();
        this.setDropDestination(this._eventBox);
"""
new_widgets = f"""        this._eventBox = new Gtk.EventBox({{visible: true}});

        // Tell sizeEventBox() that the large right margin is grid geometry
        // only. If GTK also applies that margin to this widget inside the
        // horizontal split, it consumes the space intended for WebKit.
        this._liveSplitSurface = true;
        this.sizeEventBox();

        // Keep DING's original EventBox -> Gtk.Fixed hierarchy intact in the
        // left-side strip. WebKit lives beside it, so the two input systems do
        // not overlap.
        this._eventBox.set_size_request({strip_width}, -1);
        this._eventBox.set_vexpand(true);
        this._container = new Gtk.Fixed();
        this._eventBox.add(this._container);

        this._liveLayout = new Gtk.Box({{orientation: Gtk.Orientation.HORIZONTAL}});
        this._liveLayout.pack_start(this._eventBox, false, false, 0);

        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);
        this._liveWebView.load_uri('{desktop_url}');
        this._liveLayout.pack_start(this._liveWebView, true, true, 0);

        this._window.add(this._liveLayout);
        this.gridGlobalRectangle = new Gdk.Rectangle();
        this.setDropDestination(this._eventBox);
"""
if old_widgets not in text:
    raise SystemExit("Expected DING widget block not found; refusing to patch")
text = text.replace(old_widgets, new_widgets, 1)

old_size_event_box = """    sizeEventBox() {
        this._eventBox.margin_top = this._marginTop;
        this._eventBox.margin_bottom = this._marginBottom;
        const leftToRight =
            this._eventBox.get_direction() === Gtk.TextDirection.LTR;
        if (leftToRight) {
            this._eventBox.margin_start = this._marginLeft;
            this._eventBox.margin_end = this._marginRight;
        } else {
            this._eventBox.margin_start = this._marginRight;
            this._eventBox.margin_end = this._marginLeft;
        }
    }
"""
new_size_event_box = """    sizeEventBox() {
        this._eventBox.margin_top = this._marginTop;
        this._eventBox.margin_bottom = this._marginBottom;

        // GrayHairedDesktop split-surface prototype: marginRight is still used
        // by DING's grid calculations, but must not become a GTK widget margin
        // or it will consume WebKit's horizontal allocation.
        if (this._liveSplitSurface) {
            this._eventBox.margin_start = 0;
            this._eventBox.margin_end = 0;
            return;
        }

        const leftToRight =
            this._eventBox.get_direction() === Gtk.TextDirection.LTR;
        if (leftToRight) {
            this._eventBox.margin_start = this._marginLeft;
            this._eventBox.margin_end = this._marginRight;
        } else {
            this._eventBox.margin_start = this._marginRight;
            this._eventBox.margin_end = this._marginLeft;
        }
    }
"""
if old_size_event_box not in text:
    raise SystemExit("Expected sizeEventBox() method not found; refusing to patch")
text = text.replace(old_size_event_box, new_size_event_box, 1)

path.write_text(text, encoding="utf-8")
print(
    "Patched separate-UUID desktopGrid.js for split allocation "
    f"(fallback strip {strip_width}px, URL {desktop_url})."
)
PY

# Build the physically verified two-column geometry in the same order used by
# the successful Wayland experiments. The result supports startup adaptation,
# a hard two-column GTK boundary, automatic icon-size following, and DING's
# own safe remove/resize/update/re-place sequence on live size changes.
bash "$SCRIPT_DIR/patch-wayland-adaptive-icon-strip.sh"
bash "$SCRIPT_DIR/patch-wayland-fixed-two-column-boundary.sh"
bash "$SCRIPT_DIR/patch-wayland-live-icon-size-tracking.sh"
bash "$SCRIPT_DIR/patch-wayland-live-size-manager-reflow.sh"

# Build the complete known-good WebKit child-process code during installation.
# These patchers remain useful independently during development.
bash "$SCRIPT_DIR/patch-wayland-webkit-links.sh"
bash "$SCRIPT_DIR/patch-wayland-webkit-keyboard-focus.sh"
bash "$SCRIPT_DIR/patch-wayland-webkit-lifecycle-logging.sh"

# Reproducibility gate: verify the generated user-local tree before declaring
# installation complete. This is read-only and does not start/stop anything.
bash "$SCRIPT_DIR/verify-wayland-known-good.sh" --files-only

cat <<EOF

=== SEPARATE WAYLAND DING PROTOTYPE INSTALLED ===

System extension remains untouched:
  $SYSTEM_EXT

Separate user extension:
  $TEST_EXT

UUID:
  $TEST_UUID

Adaptive Wayland layout defaults used:
  DING columns:      $GRAYHAIRED_WAYLAND_ICON_COLUMNS
  strip padding:     $GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING px
  strip minimum:     $GRAYHAIRED_WAYLAND_ICON_STRIP_MIN px
  strip maximum:     $GRAYHAIRED_WAYLAND_ICON_STRIP_MAX px
  fallback width:    $GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK px
  My Desktop URL:    $GRAYHAIRED_WAYLAND_DESKTOP_URL

The installed Wayland layout now includes the physically verified fixed
adaptive two-column boundary and automatic Tiny/Small/Standard/Large reflow.

The normal Zorin desktop-icons extension must remain disabled while testing.

If this UUID has already been discovered by GNOME Shell, enable it with:
  gnome-extensions enable $TEST_UUID

For a first-time installation, log out and back into Wayland before enabling it.
A reboot is NOT required.

IMPORTANT DEVELOPMENT WORKFLOW:
  Do not repeatedly disable/enable the GNOME extension to reload app code.
  For desktopGrid.js, desktopManager.js, ding.js, WebKit, or other app/ code changes use:
    bash $SCRIPT_DIR/reload-grayhaired.sh

For changes to extension.js itself, prefer a normal logout/login so GNOME Shell
loads a fresh extension module without churning unrelated Zorin extensions.

Read-only verification of an active installation:
  bash $SCRIPT_DIR/verify-wayland-known-good.sh

Recovery/removal preflight:
  bash $SCRIPT_DIR/check-wayland-recovery.sh

Actual recovery/removal requires explicit confirmation:
  bash $SCRIPT_DIR/remove-wayland-separate-ding-prototype.sh --apply
EOF
