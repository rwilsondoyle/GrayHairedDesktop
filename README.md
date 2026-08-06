# GrayHairedDesktop

GrayHairedDesktop is the current repository name for an Alpha 0.6 native Python 3.12+ desktop application for Zorin OS. It uses PySide6 and QtWebEngine as a desktop launch page: the configured home page stays inside the native Qt window, while clicked links open in the operating system's default browser. The public product name is still undecided before Version 1.0.

## Naming

GrayHairedDesktop is the current repository name, but the public product name is not final before Version 1.0. Possible future names include PersonalDesktop or MyDesktop; this documentation does not select one. Use neutral wording such as "the application" or "the desktop application" where practical. Ron Doyle and GrayHaired.Tech remain appropriate author/About attribution, but they should not be treated as required long-term product branding.

## Alpha 0.6 features

- Native `QMainWindow` shell with the title `GrayDesk Alpha 0.6`
- Embedded `QWebEngineView` that keeps the selected Desktop Website in the application
- Ordinary links and new-window requests open in the operating system's default browser
- **Settings** screen with **Another Website...** first, followed by Bing, DuckDuckGo, Google, MSN, and Yahoo in alphabetical order
- Reusable built-in website configuration containing display names and addresses
- Custom **Website Address** editing, enabled only for **Another Website...**, with complete HTTP/HTTPS address validation
- **Preview in Browser** opens the current selection externally without saving or changing the embedded page
- **Save** applies and loads the selection; **Cancel** preserves both saved settings and the displayed page
- Persistent settings and window geometry through `QSettings`
- Home, Reload, Settings, About, and Exit actions, status messages, and structured logging
- Zorin setup, update, and run helper scripts
- No widget system, dashboards, themes, accounts, or cloud synchronization

## Requirements

- Python 3.12 or newer
- Zorin OS or a compatible Linux desktop environment
- QtWebEngine runtime dependencies supported by PySide6

## Zorin OS quick start

These helper scripts are intended for the user's Zorin OS computers. Run them from the repository root after cloning the project.

### First-time setup

```bash
./scripts/setup-zorin.sh
```

The setup script checks for Python 3.12 or newer, installs missing Zorin/Ubuntu packages, creates `.venv` when needed, installs the application, and can be safely run more than once.

### Run the desktop application

```bash
./scripts/run.sh
```

If the script says `.venv` is missing, run `./scripts/setup-zorin.sh` first.

### Update the desktop application

```bash
./scripts/update.sh
```

The update script stops if you have uncommitted local changes, pulls the latest code with `git pull --ff-only`, and reinstalls the project into the existing `.venv`.

## Manual development install

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
```

Alternatively, install dependencies directly:

```bash
python -m pip install -r requirements.txt
```

## Manual run

```bash
grayhaired-desktop
```

Or run the module directly from a source checkout:

```bash
python -m grayhaired_desktop.app
```

## Documentation

The project documentation lives in [`docs/`](docs/):

- [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) explains the current native shell architecture and module responsibilities.
- [`ROADMAP.md`](docs/ROADMAP.md) describes the project vision and planned milestones.
- [`DEVELOPMENT_LOG.md`](docs/DEVELOPMENT_LOG.md) records milestone history and Zorin verification status.
- [`CHANGELOG.md`](docs/CHANGELOG.md) summarizes notable alpha changes.
- [`PROJECT_PRINCIPLES.md`](docs/PROJECT_PRINCIPLES.md) captures the project principles for contributors.
- [`UI_GUIDELINES.md`](docs/UI_GUIDELINES.md) defines practical rules for clear, approachable interfaces.

## Project structure

```text
src/
  grayhaired_desktop/
    __init__.py
    app.py
    browser.py
    config.py
    logger.py
    settings.py
    ui/
      __init__.py
      mainwindow.py
      preferences.py
```
