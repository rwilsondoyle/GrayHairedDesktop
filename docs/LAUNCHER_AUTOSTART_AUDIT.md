# Launcher and autostart audit

Status: **diagnostic evidence is required from the physical target.** This audit
does not install a launcher, add a competing sign-in mechanism, or change runtime
behavior. GrayHaired Desktop remains version 0.9.0.

## Finding

GrayHaired Desktop was observed to start successfully at login on the physical
Dell Inspiron-3147 running Zorin OS, GNOME, and an X11 session. This is valuable
**OBSERVED-RUNTIME** evidence, but the repository alone cannot identify the
launcher that GNOME executed. One run of the read-only
`scripts/collect-launcher-autostart-info.sh` script on that machine is needed
before launcher or autostart installation is changed.

## Current launch mechanisms

| Mechanism | Status | Checkout / `.venv` dependency |
| --- | --- | --- |
| `./scripts/run.sh` | Supported source-development run path | Yes. It locates the checkout, activates `.venv`, then executes `grayhaired-desktop`. |
| `.venv/bin/grayhaired-desktop` | Console script created by editable `pip install -e .` | Yes. Its interpreter and editable package both belong to the checkout. |
| `python -m grayhaired_desktop.app` | Possible development invocation, used with an activated environment or `PYTHONPATH=src` | Yes; not a documented installed launcher. |
| `grayhaired-desktop` from a future non-checkout Python installation | Packaging entry point already declared by `pyproject.toml` | No in principle, but no current repository installer creates this stable installation. |

`scripts/setup-zorin.sh` is the current setup path. It may install missing OS
packages, creates a project-local `.venv`, and performs an editable install. It
does not install an application-menu `.desktop` file or copy an executable into
`~/.local/bin`, `/usr/bin`, or another stable application directory.
`scripts/update.sh` performs a fast-forward Git pull and refreshes that same
editable `.venv` installation. It neither installs nor updates desktop/autostart
entries. There is no separate repository installer or uninstaller.

No application-menu `.desktop` asset exists in the repository. No script installs
one under `~/.local/share/applications` or a system data directory. The repository
does not use `XDG_DATA_HOME` for launcher installation. `PYTHONPATH=src` is a test
and development path, not a supported end-user startup contract.

## Current autostart mechanism

The application contains one intentional XDG user-autostart implementation:

1. Settings stores an opt-in `preferences/autostart` value, defaulting to off.
2. When launched through an absolute `grayhaired-desktop` console-script path
   that is not inside a `.venv`, the Settings control can create
   `$XDG_CONFIG_HOME/autostart/grayhaired-desktop.desktop` (falling back to
   `~/.config/autostart/grayhaired-desktop.desktop`).
3. The entry directly executes that absolute console script and includes
   `X-GNOME-Autostart-enabled=true`.
4. Enabling is idempotent, disabling removes that one entry, and startup repairs
   it if the saved preference is enabled and a stable executable is available.

The normal source run resolves to `.venv/bin/grayhaired-desktop`, which is
deliberately rejected as unstable. Therefore the current documented
`setup-zorin.sh` plus `run.sh` path cannot create the intentional entry through
Settings. There are no repository-provided systemd user units, session scripts,
GNOME extension launch hooks, or additional autostart files. The disabled GNOME
Shell research prototype is not a launcher and must not be used for this purpose.

## What could have caused the observed X11 startup?

Repository evidence does not establish an exact cause. The candidates are:

- **An existing user autostart `.desktop` file:** plausible and the first item to
  inspect. It might be the application's intentional entry from an earlier
  non-`.venv` installation, or a manually/development-created entry.
- **An existing user application `.desktop` file:** not itself autostart, but its
  command may reveal a manually installed launcher referenced elsewhere.
- **A repository installer:** not supported by the current scripts. The setup and
  update scripts do not create launchers or autostart entries.
- **GNOME session restore:** plausible external state, but not established by the
  repository and distinguishable only after standard entries and process command
  lines are inspected.
- **Prior testing or manual user configuration:** plausible, especially if an
  entry points to `scripts/run.sh`, the checkout, or `.venv`.
- **An extension-managed path:** no current GrayHaired Desktop extension code
  launches the application. Installed third-party/local state still requires
  physical inspection.
- **A systemd user unit or another external script:** no such unit or script is
  shipped here, but physical user configuration may contain one.

The most likely class of explanation is existing machine-local configuration—an
XDG autostart entry, whether previously generated or manual—rather than the
current repository setup script. That is a hypothesis, not a finding. Do not add
another entry until its filename, `Exec=`, and origin are known.

## Physical read-only diagnostic

On the affected machine, from any checkout of this branch, run:

```bash
./scripts/collect-launcher-autostart-info.sh
```

The collector prints session/XDG environment values, standard user launcher and
autostart directories (including symlinked entries), matching desktop-entry
fields, matching process command lines, and systemd user units whose names or
unit contents reference GrayHaired Desktop. It writes only to stdout and does not
install, launch, terminate, enable, disable, or modify anything. Preserve the
complete output for review. Earlier collector output that did not inspect
symlinked entries and generically named systemd unit contents did not rule those
sources out; run the updated collector on the physical target. If no standard
mechanism is found, inspect GNOME session-restore behavior and other user login
configuration as a separate, read-only follow-up rather than guessing.

## Duplicate launch behavior

There is no application singleton, lock file, D-Bus ownership check, or other
double-launch guard. Two valid launch requests can create two independent
processes and windows. This makes it especially important not to introduce a
second autostart path. Production installation should own one canonical entry;
a lightweight single-instance decision can be evaluated once the real startup
source and packaging lifecycle are known.

## X11 and Wayland

- **X11 autostart:** observed working on the Inspiron-3147; exact source unknown.
- **Wayland autostart:** not yet confirmed.

XDG autostart itself is session-type independent and is the standard preferred
mechanism for a GNOME login. The executable it invokes can start the normal safe,
windowed Desktop Launch Page on either X11 or Wayland. This does not prove equal
login timing, environment, Qt startup, or Desktop Mode behavior. Desktop Mode
layering remains a separate unresolved architecture problem and is not addressed
by this audit.

## Recommended production design

Use one user-local or intentionally packaged installation flow:

```text
~/.local/share/applications/grayhaired-desktop.desktop
    -> stable absolute grayhaired-desktop console entry point
    -> installed grayhaired_desktop Python package
```

A distro package could use equivalent `/usr` locations, but this project should
not require ad-hoc `sudo` installation. The application-menu launcher should use
the package's declared console entry point, include a stable icon, and never use
a repository working directory, `scripts/run.sh`, `.venv`, or `PYTHONPATH`.
Updates and uninstall must own and consistently remove the same files.

After the physical diagnostic identifies and accounts for the current source,
retain exactly one XDG entry at
`$XDG_CONFIG_HOME/autostart/grayhaired-desktop.desktop`. Its `Exec=` should name
the stable installed entry point. Installer, updater, application Settings, and
uninstaller behavior must agree on ownership and migration so stale or duplicate
entries cannot remain.

## Remaining Version 1.0 blockers

- Identify the exact source of the observed physical X11 startup.
- Design and test a stable installed package, application-menu launcher, update,
  and uninstall lifecycle that does not depend on a checkout or `.venv`.
- Validate one canonical XDG autostart lifecycle on clean and upgraded Zorin OS
  installations; separately confirm Wayland login startup.
- Decide whether lightweight duplicate-launch protection is required.
- Resolve Desktop Mode architecture while preserving Zorin's real desktop icons;
  GNOME Shell 46 / Mutter 46 research has not found a supported extension-facing
  background-content mechanism that meets the layering requirement.
- Complete the remaining physical release-readiness checks. Version 1.0 is not
  ready and no Windows, macOS, or other-Linux-distribution support is claimed.

## Implemented user-local lifecycle (0.9.0)

The production design above is now implemented by `scripts/install-user.sh`.
It builds a dedicated, non-editable venv at
`$XDG_DATA_HOME/grayhaired-desktop/venv` (default
`~/.local/share/grayhaired-desktop/venv`) and installs the package into it. The
only public command is `$XDG_BIN_HOME/grayhaired-desktop` (default
`~/.local/bin/grayhaired-desktop`); the application-menu entry is
`$XDG_DATA_HOME/applications/grayhaired-desktop.desktop`. Neither points into the
source checkout, uses `scripts/run.sh`, `PYTHONPATH`, or the development `.venv`.

Install with `./scripts/install-user.sh`, refresh from a newer source release
with `./scripts/update-user-install.sh`, and remove owned installed files with
`./scripts/uninstall-user.sh`. Update constructs the replacement venv before
switching it into place. Settings and logs remain in their existing Qt/XDG
locations and are not removed. Files and the runtime directory carry installer
ownership markers; a collision with an unowned destination causes a safe failure.
The uninstaller leaves unrecognized files alone.

Autostart remains the existing, single opt-in XDG mechanism at
`$XDG_CONFIG_HOME/autostart/grayhaired-desktop.desktop` (default
`~/.config/autostart/grayhaired-desktop.desktop`). Installation does not enable
it. The stable wrapper is eligible for the existing Settings logic, which creates
or repairs the canonical entry on launch when the saved preference is enabled.
Uninstall removes that entry only when its product name and `Exec` exactly match
the installed wrapper. No systemd or GNOME mechanism was added.

The launcher is session-type independent. It is intended to start the normal
safe/windowed Desktop Launch Page on supported Zorin X11 and Wayland sessions;
this is not a claim that Wayland Desktop Mode works. Duplicate launches remain
possible because no single-instance guard was added.

### Inspiron-3147 physical test plan (not yet performed)

1. Install the user-local build.
2. Launch GrayHaired Desktop from the application menu.
3. Confirm the normal safe/windowed Desktop Launch Page opens.
4. Close the application normally.
5. Temporarily rename the checkout and confirm the installed launcher still works.
6. Opt into autostart in Settings and verify the one canonical entry.
7. Log out and back in on Wayland.
8. Confirm exactly one application instance starts.
9. Repeat the login test on X11 later.
10. Uninstall and verify the owned runtime, launcher, menu entry, and matching
    canonical autostart entry are removed while preferences remain.
