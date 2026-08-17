# My Desktop

My Desktop is a native desktop launch-page application for Zorin OS that
displays a selected **Desktop Website** and provides easy access to favorite
shortcuts. It hands ordinary website links and shortcuts to the operating
system's default browser or web application; it is not itself a general-purpose
browser.

**My Desktop** is the public/display product name. **GrayHairedDesktop** remains
the technical/internal compatibility identity for the repository, Python
package, launcher, application IDs, settings scope, data paths, logs, and
single-instance endpoint.

**My Desktop 1.0.0 is released.** Its supported product scope is the stable,
normal windowed launch-page application. Stable user-local installation,
canonical autostart, and single-instance behavior are complete and were
physically verified on both X11 and Wayland. The final manual Zorin checklist in
[`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md) passed on both sessions,
and PR #53 recorded the final release-readiness decision as **GO**.
True Desktop Mode is future research, not the name of the supported windowed
experience. Windows and macOS are not supported.

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

## User-local installation

From a downloaded release or source checkout, install without `sudo`:

```bash
./scripts/install-user.sh
```

This creates a dedicated, non-editable virtual environment under
`~/.local/share/grayhaired-desktop/`, the stable command
`~/.local/bin/grayhaired-desktop`, and the application-menu entry
`~/.local/share/applications/grayhaired-desktop.desktop` (respecting
`XDG_DATA_HOME` and `XDG_BIN_HOME`). Python 3.12+, its `venv` module, and access
to the declared PySide6 dependency are required. No repository file or project
`.venv` is used at runtime, so the checkout may be renamed or removed afterward.
Existing application preferences are preserved.

To refresh from a newer downloaded release or clean checkout, close the app and
run:

```bash
./scripts/update-user-install.sh
```

Because Python virtual environments embed absolute paths, update temporarily moves
the old runtime aside, creates and validates the replacement venv directly at its
final path, and restores the old runtime if creation or package installation fails.
The newly generated venv is never relocated. The stable wrapper and menu launcher
are published only after validation. To uninstall the owned runtime and launchers
while preserving preferences:

```bash
./scripts/uninstall-user.sh
```

The scripts refuse to overwrite or delete destinations without their ownership
markers. The uninstaller removes the canonical autostart entry only when its
identity and `Exec` match this installation. It never removes the checkout.

## Run

Launch the installed desktop application from the application menu or:

```bash
grayhaired-desktop
```

For development from the checkout:

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

### Desktop Wallpaper (post-1.0 development)

Settings provides **Set My Desktop as Wallpaper**, **Refresh Wallpaper**, and
**Restore Previous Wallpaper**. Wallpaper Mode creates a static PNG of the saved
Desktop Website and sets it through GNOME's supported background settings. It
does not capture application controls, change GNOME Shell, or replace Zorin's
real desktop icons. The image is not clickable; open My Desktop to use links and
native shortcuts.

The image is saved at
`~/.local/share/GrayHairedDesktop/wallpaper/my-desktop-wallpaper.png`. The first
apply preserves the existing light URI, dark URI, and picture option; refresh
does not replace that restore record. Rendering is bounded and uses only the
primary screen's pixel dimensions. Mixed-DPI multi-monitor composition and
automatic refresh are not included.

The uninstaller deliberately leaves this generated user-data image and settings
in place, so GNOME is never left pointing at an image it just deleted. Restore
the previous wallpaper in Settings before uninstalling when desired.

Wallpaper Mode passed physical testing on the Dell Inspiron-3147 running Zorin
OS 18.1 / GNOME Shell 46 in both Wayland and X11 sessions. The static Desktop
Website picture was correctly sized and readable, real Zorin desktop icons
remained visible and usable, manual refresh worked, and Restore returned the
original wallpaper. Wayland Light/Dark switching also retained the generated
wallpaper. GNOME may briefly redraw after the same PNG is replaced during a
refresh; the observed wallpaper returned without intervention.

### Real desktop shortcuts (post-1.0 development)

My Desktop can also synchronize its configured shortcuts to launchers on the
user's real desktop. These launchers are deliberately separate from Wallpaper
Mode: Wallpaper Mode remains a static picture, while the operating system owns
and opens the real, interactive desktop launchers. Synchronization removes only
launchers managed by My Desktop; unrelated desktop files and Zorin's **Home**
and **Trash** icons are preserved.

Physical verification on the Dell Inspiron-3147 running Zorin OS 18.1 / GNOME
Shell 46 **PASSED** on both Wayland and X11. Launcher creation and opening, the
GNOME/Zorin **Allow Launching** trust flow, shortcut-configuration
synchronization, stale managed-launcher removal, and an X11 remove/add-back
cycle all passed. Trusted launcher state survived **Refresh Wallpaper** and a
Wayland-to-X11 session change. PR #55 Wallpaper Mode and PR #56 real shortcuts
also coexisted successfully.

The version remains **1.0.0**. This safe use of ordinary desktop launchers does
not implement a live web surface behind Zorin's icons; **True Desktop Mode**
remains separate Future Research.

## Development-checkout update

This is separate from the user-local update above. Close the application, then run from a clean checkout on `main`:

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

For an editable contributor install, include the optional development tools:

```bash
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
```

The normal Zorin setup uses `pip install -e .` without `[dev]`, so it installs
runtime requirements only. `requirements.txt` likewise lists runtime requirements
for direct dependency installation; contributors should use the command above.

Run checks with:

```bash
python -m compileall src
ruff check src
PYTHONPATH=src python -m pytest
```

Project history and design details are in [`docs/`](docs/), including the
[`roadmap`](docs/ROADMAP.md), [`architecture`](docs/ARCHITECTURE.md), and current
[`release-readiness report`](docs/RELEASE_READINESS.md).

The GNOME Wayland desktop-layer investigation and its read-only target-system
diagnostic steps are in
[`docs/GNOME_SHELL_FEASIBILITY.md`](docs/GNOME_SHELL_FEASIBILITY.md). The project
does not install or enable a GNOME Shell extension automatically.
