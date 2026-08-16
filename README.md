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

The current implementation-review build is **0.9.0**. The owner has approved the
safe, normal windowed launch-page application as the supported Version 1.0
product scope. Stable user-local installation, canonical autostart, and
single-instance behavior are complete and physically verified on both X11 and
Wayland. Version 1.0 has not been released: the final manual Zorin checklist in
[`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md), any still-required
final physical verification and a separate final version-bump/release decision remain.
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
