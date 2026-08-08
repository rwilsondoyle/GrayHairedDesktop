# GrayHaired Desktop

GrayHaired Desktop is a native desktop application for Zorin OS. It displays a
saved **Desktop Website** in its main window, provides native controls and
configurable shortcut buttons, and hands ordinary website links and shortcuts to
the operating system's default browser or web application. It is not itself a
general-purpose browser.

GrayHairedDesktop is the repository and package identity. "GrayHaired Desktop"
is the current working display wording; the final public product name has not
been selected. This release-readiness review does not make that branding decision.

The current implementation-review build is **0.9.0**. Version 1.0 has not been
declared: code review and the manual Zorin release checklist in
[`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md) must be completed first.
Windows and macOS are not supported.

## Supported environment

- Zorin OS (the only currently tested and supported target)
- Python 3.12 or newer
- Internet access for setup and web content
- PySide6 6.7 or newer, below 7 (installed by the setup script)

QtWebEngine is supplied by PySide6. The setup script also installs the matching
Python virtual-environment package, `python3-pip`, and `libxcb-cursor0` through
Zorin/Ubuntu's package manager when they are missing.

Other Linux distributions and desktop environments have not been verified. The
apt-based `setup-zorin.sh` is specifically the Zorin installation path, not a
universal Linux installer. See the detailed portability audit in the release
readiness report.

## Download and first-time setup

The current distribution is a source checkout; there is no packaged installer or
desktop launcher yet. A new user needs Git and permission to install missing OS
packages:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/rwilsondoyle/GrayHairedDesktop.git
cd GrayHairedDesktop
./scripts/setup-zorin.sh
```

`setup-zorin.sh` verifies Python, installs missing Zorin/Ubuntu dependencies,
creates `.venv`, and installs the application into it. It is safe to run again to
repair or refresh the environment. It may ask for the user's password only when
`sudo apt-get` is required.

## Run

From the checkout:

```bash
./scripts/run.sh
```

The script uses the checkout's `.venv` and starts the installed
`grayhaired-desktop` command. Application and Qt/Chromium diagnostic errors remain
visible in the terminal.

On first launch, the GrayHaired Tech Desktop Website and a small starter shortcut
set are shown. The gear button opens native controls; **Done** hides them again so
the Desktop Website retains priority. **Home** returns to the saved Desktop
Website and **Reload** reloads it. There are intentionally no Back or Forward
controls.

## Settings and shortcuts

**Settings** selects a built-in Desktop Website or **Another Website...**.
Complete `http://` or `https://` addresses are required. **Preview in Browser**
opens the selection externally without saving; **Save** persists it and **Cancel**
leaves the saved and displayed website unchanged. Ordinary Desktop Website links
also open externally, leaving the Desktop Website in place.

Shortcut buttons open externally. Use **+ Add Shortcut** to add one and right-click
a shortcut to edit or remove it. Order and duplicates are preserved. At most two
rows are displayed; overflow is available through **More...**. **Shortcut
Appearance** can match the computer or force shortcut buttons light or dark
without changing the native application appearance.

The native interface reads Zorin's light/dark preference at startup and otherwise
inherits system fonts, scaling, and appearance. Theme changes made while the
application is running take effect after restart.

## Update

Close the application, then run from a clean checkout on `main`:

```bash
git switch main
./scripts/update.sh
```

The update stops if the checkout has local changes, performs a fast-forward-only
`git pull`, and reinstalls project dependencies into `.venv`. User settings,
shortcuts, window state, and logs live outside the checkout and are not removed.

## Logs

The rotating application log is:

```text
~/.local/state/GrayHairedDesktop/grayhaired-desktop.log
```

It rotates at about 1 MB and retains three backups. **Help → Open Log Folder**
opens its location. For application logs plus terminal diagnostics:

```bash
./scripts/run.sh 2>&1 | tee ~/grayhaired-desktop-startup.log
```

No telemetry or analytics are collected.

## Development

For a manual editable install:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
```

Run checks with:

```bash
python -m compileall src
ruff check src
PYTHONPATH=src python -m pytest
```

Project history and design details are in [`docs/`](docs/), including the
[`roadmap`](docs/ROADMAP.md), [`architecture`](docs/ARCHITECTURE.md), and current
[`release-readiness report`](docs/RELEASE_READINESS.md).
