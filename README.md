# GrayHaired Desktop

GrayHaired Desktop is a native Python 3.12+ desktop application for Zorin OS. It uses PySide6 and QtWebEngine to present the GrayHaired Tech desktop web experience in a native Qt window.

## Features

- Native Qt application window
- QtWebEngine-powered browser surface
- Loads `https://grayhaired.tech/desktop-c/`
- Modular Python package layout
- Application metadata configured for Qt
- Persistent window geometry via `QSettings`
- Structured application logging

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
