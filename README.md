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

## Install for development

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

## Run

```bash
grayhaired-desktop
```

Or run the module directly from a source checkout:

```bash
python -m grayhaired_desktop.app
```

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
