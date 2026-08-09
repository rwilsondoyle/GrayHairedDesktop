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

1. `grayhaired_desktop.app` configures logging, creates `QApplication`, applies Qt application metadata, creates `QSettings`, and shows the main window.
2. `grayhaired_desktop.ui.mainwindow.MainWindow` coordinates the launch page, external-link status, Settings workflow, and persistent window geometry. Focused UI modules create its shared actions, menu bar, and toolbar.
3. `grayhaired_desktop.browser.BrowserView` wraps `QWebEngineView`, stores the configured home URL, and uses a `QWebEnginePage` navigation policy plus `QDesktopServices` to open clicked links externally. Same-page fragment navigation remains embedded.
4. `grayhaired_desktop.settings` defines the immutable, alphabetically ordered built-in website configuration, matches saved addresses to built-in choices, loads and saves settings through `QSettings`, and provides reusable HTTP/HTTPS address validation.
5. `grayhaired_desktop.ui.preferences.PreferencesDialog` presents the **Settings** screen. It places **Another Website...** first, builds the remaining radio buttons from the reusable built-in configuration, and enables **Website Address** only for a custom selection. Preview does not save; Save applies the selection; Cancel changes nothing.

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `app.py` | Application entry point, Qt application metadata, settings construction, main event loop. |
| `browser.py` | Embedded launch-page widget, external-link policy, and page-load logging hooks. |
| `config.py` | Application metadata and `QSettings` factory. |
| `logger.py` | Central logging configuration. |
| `settings.py` | Default values, built-in website configuration and matching, address validation, and persistence helpers. |
| `desktop_mode.py` | Detects session facts and makes a conservative, testable X11/Wayland mode decision. |
| `x11_window.py` | Applies and clears Qt's supported X11 EWMH desktop-window attribute while keeping platform details isolated. |
| `autostart.py` | Creates or removes the single user-level XDG autostart entry. |
| `ui/actions.py` | Creates and connects the shared Home, Reload, Settings, About, and Exit actions. |
| `ui/menus.py` | Populates the application menu bar from the shared actions. |
| `ui/toolbar.py` | Builds the non-movable main toolbar from the shared actions. |
| `ui/mainwindow.py` | Main desktop window coordination, external-link status messages, Settings and About dialogs, window state persistence. |
| `ui/preferences.py` | Settings dialog for choosing, previewing, and applying a built-in or custom Desktop Website. |
| `scripts/setup-zorin.sh` | First-time Zorin/Ubuntu setup, system dependency checks, virtual environment creation, editable install. |
| `scripts/run.sh` | Starts the installed app from the project virtual environment. |
| `scripts/update.sh` | Safely updates a clean checkout and reinstalls into the existing virtual environment. |

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
