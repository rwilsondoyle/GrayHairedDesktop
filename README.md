# GrayHaired Desktop

GrayHaired Desktop Alpha 0.2 is a native Python 3.12+ desktop application for Zorin OS. It uses PySide6 and QtWebEngine to display the GrayHaired Tech desktop web experience inside a native Qt main window.

## Alpha 0.2 features

- Native `QMainWindow` shell with the title `GrayHaired Desktop Alpha 0.2`
- Embedded `QWebEngineView` browser surface
- Automatically loads `https://grayhaired.tech/desktop-c/`
- File menu with **Exit**
- View menu with **Reload**
- Help menu with **About**
- Status bar with page load state updates
- Structured logging for application startup, page loading, page loaded, page failed, and application shutdown
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
    ui/
      __init__.py
      mainwindow.py
```
