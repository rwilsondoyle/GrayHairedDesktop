# Architecture

GrayHaired Desktop is a small native Linux desktop application. The codebase is intentionally simple: Python starts a Qt application, a main window owns the desktop controls, and an embedded QtWebEngine launch page loads and retains the configured Desktop Website. Clicked destinations are handed to the operating system's default browser.

## Runtime stack

- **Language:** Python 3.12 or newer.
- **Desktop toolkit:** PySide6, including Qt Widgets and QtWebEngine.
- **Tested target environment:** Zorin OS. Other Linux distributions and desktop environments are unverified.
- **Packaging:** `pyproject.toml` exposes the `grayhaired-desktop` console script, which calls `grayhaired_desktop.app:main`.

## Naming

GrayHairedDesktop is the repository and package identity. **GrayHaired Desktop** is current working/display wording, not a final public-name decision. The public product name remains undecided before Version 1.0. This review does not rename the repository, Python package, QSettings identity, or application data paths. GrayHaired Tech and Ron Doyle remain appropriate project attribution.

## Application flow

1. `grayhaired_desktop.app` configures logging, creates `QApplication`, applies Qt application metadata, and acquires the user-local single-instance endpoint. A secondary launch sends an activation request and exits before importing the WebEngine UI; the primary creates `QSettings` and shows the main window.
2. `grayhaired_desktop.ui.mainwindow.MainWindow` coordinates the launch page, external-link status, Settings workflow, and persistent window geometry. Focused UI modules create its shared actions, menu bar, and toolbar.
3. `grayhaired_desktop.browser.BrowserView` wraps `QWebEngineView`, stores the configured home URL, and uses a `QWebEnginePage` navigation policy plus `QDesktopServices` to open clicked links externally. Same-page fragment navigation remains embedded.
4. `grayhaired_desktop.settings` defines the immutable, alphabetically ordered built-in website configuration, matches saved addresses to built-in choices, loads and saves settings through `QSettings`, and provides reusable HTTP/HTTPS address validation.
5. `grayhaired_desktop.ui.preferences.PreferencesDialog` presents the **Settings** screen. It places **Another Website...** first, builds the remaining radio buttons from the reusable built-in configuration, and enables **Website Address** only for a custom selection. Preview does not save; Save applies the selection; Cancel changes nothing.

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `app.py` | Application entry point, Qt application metadata, settings construction, main event loop. |
| `single_instance.py` | User-local `QLocalServer`/`QLocalSocket` ownership, activation messages, and conservative stale-endpoint recovery. |
| `browser.py` | Embedded launch-page widget, external-link policy, and page-load logging hooks. |
| `config.py` | Application metadata and `QSettings` factory. |
| `logger.py` | Central logging configuration. |
| `settings.py` | Default values, built-in website configuration and matching, address validation, and persistence helpers. |
| `desktop_mode.py` | Detects session facts and makes a conservative, testable X11/Wayland mode decision. |
| `x11_window.py` | Configures and reverses the X11 normal-window/stays-below strategy while explicitly avoiding GNOME's obscured desktop-type layer. |
| `autostart.py` | Creates or removes the single user-level XDG autostart entry. |
| `ui/actions.py` | Creates and connects the shared Home, Reload, Settings, About, and Exit actions. |
| `ui/menus.py` | Populates the application menu bar from the shared actions. |
| `ui/toolbar.py` | Builds the non-movable main toolbar from the shared actions. |
| `ui/mainwindow.py` | Main desktop window coordination, external-link status messages, Settings and About dialogs, window state persistence. |
| `ui/preferences.py` | Settings dialog for choosing, previewing, and applying a built-in or custom Desktop Website. |
| `scripts/setup-zorin.sh` | First-time Zorin/Ubuntu setup, system dependency checks, virtual environment creation, editable install. |
| `scripts/run.sh` | Starts the installed app from the project virtual environment. |
| `scripts/update.sh` | Safely updates a clean checkout and reinstalls into the existing virtual environment. |
| `scripts/install-user.sh` | Creates the checkout-independent user-local runtime, stable command, and application-menu launcher. |
| `scripts/update-user-install.sh` | Atomically refreshes the user-local runtime while preserving preferences and restoring the prior runtime on failure. |
| `scripts/uninstall-user.sh` | Removes installer-owned runtime and launchers, and only the matching canonical autostart entry; preserves preferences. |

## Persistence

The application uses Qt `QSettings` under the current author/About attribution metadata. It currently persists:

- `preferences/homePageUrl` for the configurable home page URL.
- `mainwindow/geometry` for window size and placement.
- `mainwindow/windowState` for Qt window state.
- `preferences/desktopMode` for the explicit Desktop Mode choice (default off).
- `preferences/autostart` for the explicit sign-in startup choice (default off).

## Current boundaries

- The desktop launch page retains the configured home page in the application, while clicked links open in the operating system's default browser.
- The application source code is a native shell only; the configured web destination can evolve as branding and product direction mature.
- There is no local database, background service, or custom network protocol layer in the desktop app.
- The app ships focused offscreen Qt tests, but manual Zorin verification remains important for release decisions.
- The application does not add a widget system, dashboards, accounts, or synchronization.
- Qt local IPC avoids another dependency and keeps the endpoint scoped to the current desktop user. A repeated launch asks the existing window to restore, show, raise, and activate through ordinary Qt APIs. Desktop environments, particularly Wayland compositors, may refuse the focus request; single-instance enforcement does not depend on focus being granted.

## Single-instance physical verification

PR #43 was physically verified on the Dell Inspiron-3147 under Zorin OS / GNOME
in both X11 and Wayland sessions. In each session, canonical XDG autostart
produced exactly one installed application instance. A second invocation through
`~/.local/bin/grayhaired-desktop` returned normally, created no second window,
and left exactly one real GrayHaired Desktop application process. GNOME used a
visual attention/flashing indication instead of consistently forcing the window
to the foreground on both sessions. That result is acceptable: the Qt activation
request is best-effort, while the single-instance guarantee is enforced by the
local IPC endpoint without X11- or compositor-specific focus workarounds.

PR #42's installed launcher, application-menu entry, update/uninstall lifecycle,
and single canonical XDG autostart entry were also physically verified on that
machine. Login/autostart passed in X11 and Wayland. The installed runtime remains
independent of its source checkout, and uninstall preserves preferences.

## GNOME desktop-layer boundary

The confirmed target is Zorin OS 18.1 with GNOME Shell 46.0. Its real desktop-
icon provider is the active `zorin-desktop-icons@zorinos.com` extension, named
**Zorin Desktop Icons**. Its metadata describes a fork of the original Desktop
Icons extension, while installed source headers identify substantial code as
“DING: Desktop Icons New Generation for GNOME Shell.” Provider identity and
implementation ancestry are therefore distinct: this is Zorin Desktop Icons with
DING-derived code. Targeted inspection confirms that a separate application
renders icons in client windows and that Zorin's Shell code manages their
`Meta.Window` lifecycle, stacking, workspaces, monitor geometry, and Wayland
desktop-window emulation.

The pure-Qt trials still establish an application boundary: a normal PySide6
window cannot independently guarantee the required background → application →
real-icons order on GNOME. Read-only inspection found no supported third-party
layer-registration point in the installed Zorin provider. A Shell-owned mirror
would require private placement plus a substantial external frame/input bridge,
so it is not currently suitable for Version 1.0. The continuing investigation is documented in
[`GNOME_SHELL_FEASIBILITY.md`](GNOME_SHELL_FEASIBILITY.md).

The required layer is specifically wallpaper → interactive GrayHaired Desktop →
real Zorin icons → ordinary windows → Shell chrome. PR #39 rejected a pure Qt
desktop-type window, a normal stays-below window, `Meta.Window.lower()`, direct
`MetaWindowActorWayland` sibling ordering, managed window-list hiding, and the
tested Shell-owned actor above `backgroundGroup`. The actor experiment also
persisted across reboot until its development extension was disabled. Read-only
inspection found no supported Zorin third-party registration/relative-layer API.
Managed `Meta.WaylandClient` ownership passed, but ownership did not solve this
relative order.

The Version 1.0 architecture gate is therefore explicit: either retain Desktop
Mode and investigate a materially different safe integration, or make a later
owner-approved product decision to scope Version 1.0 to the existing windowed
launch page and move Desktop Mode forward. No ordinary maximized/borderless
window is called Desktop Mode, and this documentation makes no scope decision.

PR #45 completed the materially different architecture review. A companion
extension can likely inspect GNOME Shell's private runtime record and Zorin
implementation instance, but the provider exposes no supported cross-extension
contract and no shared GTK/Wayland surface. Icon pixels remain in external
per-monitor GTK client windows. GNOME Shell 46 offers neither foreign-surface
adoption nor a Mutter-supported layer-shell equivalent for the required slot.
Frame mirroring would still require unsupported placement and a custom
focus/input/accessibility bridge.

The classification is **Result 3 — no practical supported path found**. Path A
remains blocked at `0.9.0`; PR #46 must ask the owner whether to adopt PR #44
Path B rather than redefining Desktop Mode. Full evidence and the candidate
matrix are in [`GNOME_SHELL_FEASIBILITY.md`](GNOME_SHELL_FEASIBILITY.md).
