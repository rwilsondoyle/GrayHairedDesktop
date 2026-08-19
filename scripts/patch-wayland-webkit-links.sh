#!/usr/bin/env bash
set -euo pipefail

TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
TEST_EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"
GRID="$TEST_EXT/app/desktopGrid.js"
BACKUP="$GRID.before-webkit-link-handoff"

if [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
    echo "This patch is intended for the Wayland prototype."
    echo "Current session: ${XDG_SESSION_TYPE:-unknown}"
    exit 2
fi

if [[ ! -f "$GRID" ]]; then
    echo "GrayHaired Wayland prototype desktopGrid.js not found:"
    echo "  $GRID"
    exit 2
fi

if pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' >/dev/null 2>&1; then
    echo "The GrayHaired Wayland prototype is still running."
    echo "Disable it first with:"
    echo "  gnome-extensions disable $TEST_UUID"
    exit 2
fi

cp "$GRID" "$BACKUP"

python3 - "$GRID" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

old_imports = """const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const WebKit2 = imports.gi.WebKit2;
"""
new_imports = """const Gtk = imports.gi.Gtk;
const Gdk = imports.gi.Gdk;
const Gio = imports.gi.Gio;
const WebKit2 = imports.gi.WebKit2;
"""
if old_imports not in text:
    raise SystemExit("Expected WebKit import block not found; refusing to patch")
text = text.replace(old_imports, new_imports, 1)

old_webview = """        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);
        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');
        this._liveLayout.pack_start(this._liveWebView, true, true, 0);
"""
new_webview = """        this._liveWebView = new WebKit2.WebView();
        this._liveWebView.set_hexpand(true);
        this._liveWebView.set_vexpand(true);

        // GrayHairedDesktop Wayland research: the desktop page contains many
        // links that request a new browser window/tab. A bare WebKitWebView has
        // no visible browser chrome, so hand user-initiated external
        // navigations to the user's default browser instead.
        this.connectSignal(this._liveWebView, 'decide-policy',
            (webView, decision, decisionType) => {
                if (decisionType !== WebKit2.PolicyDecisionType.NAVIGATION_ACTION &&
                    decisionType !== WebKit2.PolicyDecisionType.NEW_WINDOW_ACTION) {
                    return false;
                }

                let action;
                let request;
                let uri;
                try {
                    action = decision.get_navigation_action();
                    request = action.get_request();
                    uri = request.get_uri();
                } catch (e) {
                    print(`[GRAYHAIRED-WEBKIT] Unable to inspect navigation: ${e.message}`);
                    return false;
                }

                const isNewWindow =
                    decisionType === WebKit2.PolicyDecisionType.NEW_WINDOW_ACTION;
                let isUserGesture = false;
                try {
                    isUserGesture = action.is_user_gesture();
                } catch (e) {
                    // NEW_WINDOW_ACTION is itself enough evidence that the
                    // page is asking for a separate browsing context.
                }

                if (!uri || (!isNewWindow && !isUserGesture)) {
                    return false;
                }

                // Keep the initial My Desktop document inside WebKit. Hand
                // actual clicked destinations to the normal default browser.
                if (uri.startsWith('https://grayhaired.tech/desktop-d')) {
                    return false;
                }

                try {
                    print(`[GRAYHAIRED-WEBKIT] Opening in default browser: ${uri}`);
                    Gio.AppInfo.launch_default_for_uri(uri, null);
                    decision.ignore();
                    return true;
                } catch (e) {
                    printerr(`[GRAYHAIRED-WEBKIT] Browser handoff failed: ${e.message}`);
                    return false;
                }
            });

        this._liveWebView.load_uri('https://grayhaired.tech/desktop-d');
        this._liveLayout.pack_start(this._liveWebView, true, true, 0);
"""
if old_webview not in text:
    raise SystemExit("Expected live WebView block not found; refusing to patch")
text = text.replace(old_webview, new_webview, 1)

path.write_text(text, encoding="utf-8")
print("Added WebKit external-link handoff to the Wayland prototype.")
PY

echo
echo "=== WAYLAND WEBKIT LINK PATCH APPLIED ==="
echo "Patched:"
echo "  $GRID"
echo "Backup:"
echo "  $BACKUP"
echo
echo "Enable the prototype with:"
echo "  gnome-extensions enable $TEST_UUID"
