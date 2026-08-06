# Architecture

GrayHairedDesktop is the current repository name for a small native Linux desktop shell. The Alpha 0.5 codebase is intentionally simple: Python starts a Qt application, a main window owns the desktop chrome, and an embedded QtWebEngine launch page loads and retains the configured home URL. Clicked destinations are handed to the operating system's default browser.

## Runtime stack

- **Language:** Python 3.12 or newer.
- **Desktop toolkit:** PySide6, including Qt Widgets and QtWebEngine.
- **Target environment:** Zorin OS, with compatibility expected on close Ubuntu-based desktop environments when QtWebEngine runtime packages are available.
- **Packaging:** `pyproject.toml` exposes the `grayhaired-desktop` console script, which calls `grayhaired_desktop.app:main`.

## Naming

GrayHairedDesktop is the current repository name, but the public product name is not final before Version 1.0. Possible future names include PersonalDesktop or MyDesktop; this documentation does not select one. Use neutral wording such as "the application" or "the desktop application" where practical. Ron Doyle and GrayHaired.Tech remain appropriate author/About attribution, but they should not be treated as required long-term product branding.

## Application flow

1. `grayhaired_desktop.app` configures logging, creates `QApplication`, applies Qt application metadata, creates `QSettings`, and shows the main window.
2. `grayhaired_desktop.ui.mainwindow.MainWindow` coordinates the launch page, external-link status, preferences workflow, and persistent window geometry. Focused UI modules create its shared actions, menu bar, and toolbar.
3. `grayhaired_desktop.browser.BrowserView` wraps `QWebEngineView`, stores the configured home URL, and uses a `QWebEnginePage` navigation policy plus `QDesktopServices` to open clicked links externally. Same-page fragment navigation remains embedded.
4. `grayhaired_desktop.settings` loads and saves user preferences through `QSettings` and provides reusable HTTP/HTTPS URL validation.
5. `grayhaired_desktop.ui.preferences.PreferencesDialog` lets the user edit, externally preview, validate, or restore the home page URL. Edits remain local to the dialog until OK is selected.

## Module responsibilities

| Module | Responsibility |
| --- | --- |
| `app.py` | Application entry point, Qt application metadata, settings construction, main event loop. |
| `browser.py` | Embedded launch-page widget, external-link policy, and page-load logging hooks. |
| `config.py` | Application metadata and `QSettings` factory. |
| `logger.py` | Central logging configuration. |
| `settings.py` | Default preference values, URL validation, and persistence helpers. |
| `ui/actions.py` | Creates and connects the shared Home, Reload, Preferences, About, and Exit actions. |
| `ui/menus.py` | Populates the application menu bar from the shared actions. |
| `ui/toolbar.py` | Builds the non-movable main toolbar from the shared actions. |
| `ui/mainwindow.py` | Main desktop window coordination, external-link status messages, preferences and About dialogs, window state persistence. |
| `ui/preferences.py` | Preferences dialog for editing, opening, validating, and restoring the configurable home page URL. |
| `scripts/setup-zorin.sh` | First-time Zorin/Ubuntu setup, system dependency checks, virtual environment creation, editable install. |
| `scripts/run.sh` | Starts the installed app from the project virtual environment. |
| `scripts/update.sh` | Safely updates a clean checkout and reinstalls into the existing virtual environment. |

## Persistence

The application uses Qt `QSettings` under the current author/About attribution metadata. It currently persists:

- `preferences/homePageUrl` for the configurable home page URL.
- `mainwindow/geometry` for window size and placement.
- `mainwindow/windowState` for Qt window state.

## Current boundaries

- The desktop launch page retains the configured home page in the application, while clicked links open in the operating system's default browser.
- The application source code is a native shell only; the configured web destination can evolve as branding and product direction mature.
- There is no local database, background service, or custom network protocol layer in the desktop app.
- The app does not currently ship automated GUI tests. Manual Zorin verification remains important for each alpha milestone.
- Alpha 0.5 does not add a widget system, dashboards, themes, accounts, or synchronization.
