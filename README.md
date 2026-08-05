# GrayHaired Desktop

GrayHaired Desktop Alpha 0.3 is a native Python 3.12+ desktop application for Zorin OS. It uses PySide6 and QtWebEngine to display the GrayHaired Tech desktop web experience inside a native Qt main window.

## Alpha 0.3 features

- Native `QMainWindow` shell with the title `GrayDesk Alpha 0.3`
- Embedded `QWebEngineView` browser surface
- Configurable home page URL with the default `https://grayhaired.tech/desktop-c/`
- Persistent preferences stored with `QSettings`
- Preferences dialog with **OK**, **Cancel**, and **Restore Defaults** controls
- File menu with **Exit**
- View menu with **Home** and **Reload**
- Settings menu with **Preferences...**
- Help menu with **About**
- Toolbar actions for **Home**, **Reload**, and **Preferences**
- Status bar states for **Loading...**, **Loaded**, **Failed**, and **Ready**
- Structured logging for application startup, application shutdown, preference changes, page loading, finished loading, and load failures
- Modular Python package layout
- Application metadata configured for Qt
- Persistent window geometry via `QSettings`

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

The setup script checks for Python 3.12 or newer, installs missing Zorin/Ubuntu packages, creates `.venv` when needed, installs GrayHaired Desktop, and can be safely run more than once.

### Run GrayHaired Desktop

```bash
./scripts/run.sh
```

If the script says `.venv` is missing, run `./scripts/setup-zorin.sh` first.

### Update GrayHaired Desktop

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
- [`ROADMAP.md`](docs/ROADMAP.md) describes the project vision and milestones through Alpha 0.3.1.
- [`DEVELOPMENT_LOG.md`](docs/DEVELOPMENT_LOG.md) records milestone history and Zorin verification status.
- [`CHANGELOG.md`](docs/CHANGELOG.md) summarizes notable alpha changes.
- [`PROJECT_PRINCIPLES.md`](docs/PROJECT_PRINCIPLES.md) captures the project principles for contributors.

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
