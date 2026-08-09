# Version 1.0 release-readiness review

Status: **Desktop Mode implementation and final manual Zorin verification are
pending.** This report does not declare Version 1.0 complete.

## Release finding

The reviewed source is a credible Version 1.0 candidate, but it must not be
released as 1.0 until the manual checklist below passes on a clean, supported
Zorin installation and the release-readiness pull request is approved.

### Blockers

- Design and verify a GNOME Shell integration that can preserve the user's real
  desktop icons. The actual Zorin session is GNOME, where neither tested Qt X11
  strategy can occupy the required layer. Begin every manual run by recording the
  detected XDG session type, Qt platform, desktop environment, and selected
  Desktop Mode implementation/fallback path.
- On Wayland, a normal Qt application cannot reliably insert an interactive
  window beneath the compositor-managed shell wallpaper. The implementation
  therefore remains in normal/windowed mode and reports the fallback rather than
  presenting a borderless fullscreen window as Desktop Mode.
- Provide a stable installed application launcher before Version 1.0 so the
  intended sign-in startup experience can be enabled. The current source/`.venv`
  distribution deliberately cannot produce a safe autostart entry.
- Complete all 50 manual Zorin checks below, including clean installation,
  upgrade persistence, both Zorin appearances, accessibility, and real external
  browser handoff. These behaviors cannot be fully established in a headless
  development environment.
- After those checks pass, make the explicit release decision and change the
  version from `0.9.0` to `1.0.0` in both version locations. Do not publish
  mismatched package and runtime versions.

### Non-blocking polish

- Refresh older architecture and development-history prose as the implementation
  evolves. Historical milestone names and test records are intentionally retained.
- Decide the final public product name before producing signed, branded artifacts.
  GrayHairedDesktop remains the repository/package identity, while GrayHaired
  Desktop is only current working/display wording. This review selects no name.

### Future distribution

- Provide a native package or installer and an application-menu `.desktop`
  launcher/icon so a public user need not manage a source checkout or terminal.
- Add a documented uninstaller/removal workflow; today removal is manual.
- Add release checksums and, if practical, signed artifacts.
- Publish a concise public instruction sheet and technical release page using the
  checklists below.

These are distribution improvements rather than blockers for a clearly described
source-based 1.0 release.

## Desktop Mode feasibility and implementation

Desktop Mode restores the original goal of showing the live Desktop Website and
interactive shortcuts as a desktop/background layer. It is opt-in and normal
windowed mode remains the default and safe fallback.

- Session detection combines `XDG_SESSION_TYPE`, Qt's runtime platform name, and
  the desktop environment. GNOME sessions are unsupported because the real icon
  layer cannot be preserved by a Qt window. A non-GNOME X11 candidate is selected
  only when the session says X11/Xorg and Qt uses `xcb`; contradictory or unknown
  results are unsupported and logged.
- On non-GNOME X11, the unverified candidate is a normal top-level window using
  `FramelessWindowHint` and `WindowStaysOnBottomHint`, sized to the current/primary
  screen without entering fullscreen mode. It explicitly clears
  `WA_X11NetWmWindowTypeDesktop`: Zorin/GNOME's existing desktop surface hid the
  application when that EWMH desktop classification was used. The stays-below
  hint should place ordinary applications and the GNOME panel above this window,
  but the complete strategy remains pending manual confirmation.
- On Wayland, Desktop Mode safely falls back to the ordinary window with a short
  explanation. No compositor bypass, layer-shell extension, static wallpaper,
  or ordinary fullscreen substitute is used.
- GNOME/Zorin desktop-icon extensions own their own desktop surface. The normal
  below window was proven to sit above that surface and hide the real icons. Qt
  provides no reliable standard layer between GNOME's wallpaper and icon
  extension, so GNOME now falls back safely. This application neither hides icons
  nor implements an icon manager.
- Multi-monitor support deliberately targets one current/primary screen. Qt
  screen geometry is read when mode is entered; live monitor add/remove handling
  and one-window-per-screen behavior remain future work.
- Desktop Mode does not use a no-focus flag: its shortcuts and controls remain
  interactive. The stays-below hint avoids promoting it over ordinary windows.
  Skip-taskbar, skip-pager, and sticky/all-workspaces hints are not requested:
  Qt has no suitable cross-platform flags that preserve the required interactive
  normal-window stacking. A taskbar entry and current-workspace-only behavior are
  known limitations pending manual review.
- Settings always remain available from the lower-left controls button. Saving
  Desktop Mode Off returns to windowed mode. `Ctrl+Shift+D` is an additional
  recovery shortcut that turns the setting off; unlike `Ctrl+Alt+D`, it is not a
  common GNOME Show Desktop binding. Exit remains in the File menu.
- Optional sign-in startup creates exactly one user entry at
  `~/.config/autostart/grayhaired-desktop.desktop` (or under
  `$XDG_CONFIG_HOME`). It uses the absolute installed console-script path,
  requires no root/daemon/systemd, writes idempotently, and removes the file when
  disabled. The present source setup installs that command inside the checkout's
  `.venv`, which is not a stable distribution launcher: enabling autostart in
  that setup therefore fails safely rather than recording a branch/check-out
  path. The implementation becomes available when a future package supplies a
  stable installed console-script path.

  In the current source distribution, Settings disables this option and explains
  in plain language that it will become available after installation as a desktop
  application. The implementation exists, but end-to-end login autostart testing
  is unavailable—not a failed user test—until a stable installed launcher exists.
  Because automatic startup is part of the intended desktop-replacement
  experience, that stable launch/install path remains a pre-1.0 distribution
  blocker. Packaging is not attempted in this Desktop Mode change.

  At startup, a saved enabled preference is reconciled whenever a stable launcher
  is available: a missing entry is recreated, an old launcher path or damaged
  entry is replaced, and an already-correct entry is left untouched. If no stable
  launcher is available, the preference remains saved so it can resume after a
  proper installation, but Settings shows an unchecked disabled control and says
  automatic start is unavailable. Write failures are logged without blocking
  normal startup.

No claim is made yet about real Zorin icon ordering, panel ordering, Show Desktop,
focus, monitor changes, logout, or compositor behavior. All require the manual
Desktop Mode checklist requested for this development task.

Manual testing on the user's Zorin Wayland session confirmed that requesting
Desktop Mode selects the safe normal/windowed fallback. The informational message
is shown when the user first enables the option in Settings, but subsequent
startups fall back quietly and record the unsupported path in the log. The saved
Desktop Mode preference remains enabled for possible future integration.

Real Zorin X11 testing reported session type `x11`, Qt platform `xcb`, and desktop
environment `zorin:GNOME`; the application and Desktop Website loaded. The first
attempt used `WindowType.Desktop`, which Qt 6 deprecated and ignored. The second
attempt correctly used `WA_X11NetWmWindowTypeDesktop`, but the process remained
running while its window was invisible beneath Zorin/GNOME's existing desktop
surface. Applying a standards-correct hint is therefore not treated as success.
The new `below-normal-window` strategy remains pending manual confirmation for
visibility, stacking, panels, icons, focus, Show Desktop, and recovery.

A subsequent real X11 test improved visibility but did not meet the product goal:
the application and Desktop Website were visible, remained visible with the
desktop exposed, and shortcuts were clickable, but the surface was a smaller,
offset application-like page with wallpaper around it. Bottom controls were hard
to reach, `Ctrl+Shift+D` did not recover windowed mode, and stacking and panel
behavior were not proven. That implementation applied full screen geometry only
before the window manager mapped the recreated normal window and did not reserve
the shell panel. Saved normal geometry is retained only for later recovery and is
explicitly overridden while Desktop Mode is active.

The first post-map geometry refinement crashed on real Zorin X11 immediately
after its final geometry log. It combined a zero-delay `QTimer` resize of the
mapped top-level `QMainWindow`/QtWebEngine surface with a new application-wide
Python event filter. The precise native fault cannot be proven from a segmentation
fault without a backtrace, so both newly introduced high-risk paths were removed:
there is no post-show resize and no application-wide recovery event filter.

The stable candidate now applies work-area geometry exactly once before the first
show. It temporarily removes the normal window's 720 px minimum, which exceeded
the tested 716 px Zorin work area and explained the logged 720 px applied height.
Normal mode restores that minimum, the original flags, and saved geometry.
`Ctrl+Shift+D` returns to the earlier application-local `QShortcut` implementation;
its real X11 reliability remains unverified. The lower-left controls button is the
mouse-based route to Settings and Exit. Wayland's safe windowed fallback remains
the only verified mode path.

Commit `e35294e0` was then tested on real Zorin GNOME X11. It passed stability,
usable work-area sizing, Desktop Website interaction, shortcuts, and gear access.
It failed desktop-icon preservation: the full-size normal stays-below window sat
above the user's real Zorin desktop icons, hiding them. Show Desktop therefore
exposed GrayHaired Desktop but not the user's files/program icons. X11 Desktop
Mode is not accepted.

The confirmed Zorin OS 18.1 target implements desktop icons with the active
`zorin-desktop-icons@zorinos.com` extension (**Zorin Desktop Icons**), a fork of
the original Desktop Icons extension. Installed source headers also confirm
substantial DING-derived code under Zorin's provider identity. The exact Zorin
source confirms that it manages separate icon client windows through
`Meta.Window`, including explicit Wayland desktop-window emulation and lowering.
EWMH offers a desktop type and a below state, but pure Qt exposes no standard ordering level
between GNOME's background and the icon provider. Testing demonstrated both sides
of that Qt limit: the desktop-type attempt was hidden below GNOME's desktop
surface, while the normal stays-below attempt was above and hid the icons. A
development-only GNOME 46 prototype now tests whether a controlled sequence of
real `lower()` calls can cooperate safely with the actual Zorin extension. Its
result is verified with Mutter's sorted full window list; installation remains
blocked until the target API probe is reviewed.

The application now treats Zorin/GNOME sessions—including X11/`xcb`—as
unsupported and uses the safe normal/windowed fallback. This preserves the user's
real icons and existing application behavior while keeping the saved Desktop Mode
preference enabled. Non-GNOME X11 retains the unverified below-normal-window
candidate, but no X11 environment is declared accepted. Achieving the required
wallpaper → live application → real icons order on GNOME ultimately requires a
small GNOME Shell integration component coordinated with the actual icons
extension for both X11 and Wayland. Designing that component is a remaining
pre-1.0 item and is intentionally not attempted as another Qt flag change.

### Manual Desktop Mode decision checklist

Before judging desktop-layer behavior on Zorin, record from the application log:

1. detected `XDG_SESSION_TYPE`;
2. detected Qt platform name; and
3. selected Desktop Mode implementation/fallback path.

If the desktop environment includes GNOME, expect and verify the safe usable
windowed fallback on both X11 and Wayland; this preserves the real desktop icons
and is not a test failure. Only a non-GNOME X11/Xorg session with Qt `xcb` selects
the below-normal-window candidate; test its ordinary-window ordering, native
desktop facilities, panels, focus, Show Desktop, geometry, external links,
controls, and recovery. Contradictory or unknown results must also fall back
safely and be logged truthfully.

For autostart, first check whether Settings enables the sign-in option. With the
current source/`.venv` installation it should be disabled and the login test is
pending. Test creation, single-entry idempotence, login launch, and removal only
after a stable installed application launcher is available.

## Audit results

### Product, version, and wording

- The product is a desktop application that displays a saved Desktop Website and
  provides native controls and shortcuts. It is not described as a browser.
- `pyproject.toml` is the packaging version source of truth. The runtime mirror in
  `grayhaired_desktop.__version__` is guarded by an automated consistency test.
  This repository uses three-part semantic versions, so the eventual release
  should be `1.0.0`, not `1.0`.
- The implementation-review version is `0.9.0`. The former prerelease spellings
  (`0.9.0a0` and `0.9.0-alpha.0`) and normal user-interface `Alpha 0.9` labels
  were stale and have been removed. Historical Alpha milestone headings remain.
- The About dialog uses the current display wording and runtime version, gives a
  short factual description, describes external browser behavior, and attributes
  the project without prerelease wording, a final-name claim, or marketing claims.
- The repository, Python package, QSettings identity, and application data paths
  are unchanged. No settings migration is proposed or needed by this review.

### Installation, update, and run

**What exists now:** the public artifact is the Git source repository (or an
equivalent source ZIP), `scripts/setup-zorin.sh`, a project-local `.venv`, and
`scripts/run.sh`. A ZIP does not support `scripts/update.sh`; Git is therefore the
practical current distribution method.

**Clean-install path:** install Git, clone the repository, enter it, run
`./scripts/setup-zorin.sh`, then `./scripts/run.sh`. The exact commands are in the
README. Setup validates Python 3.12+, finds the matching `pythonX.Y-venv` package,
installs missing `python3-pip` and `libxcb-cursor0`, creates or reuses `.venv`, and
runs `pip install -e .`. It is rerunnable and deletes no user data. It does require
terminal use, Git knowledge sufficient to clone, network access, and `sudo` when
OS dependencies are absent.

There is no `scripts/install.sh`; `scripts/setup-zorin.sh` is the existing install
entry point. Renaming it or adding a second alias would not remove the larger
source-distribution usability gap, so this review documents rather than masks it.

**Update path:** from a clean checkout on `main`, close the app, run
`git switch main`, then `./scripts/update.sh`. It refuses any dirty worktree,
performs only a fast-forward pull, requires the existing `.venv`, and reinstalls
the project so dependency metadata is reapplied. It does not delete files.
Settings and logs are outside the checkout, so updates do not wipe them. The
script does not automatically switch branches or update in the background.

**Run path:** `./scripts/run.sh` resolves the repository from its own location,
requires and activates `.venv`, and `exec`s the installed console entry point.
Failures remain visible in the terminal and persistent application diagnostics
remain enabled.

### Behavior and persistence

- First-run defaults provide the GrayHaired Tech Desktop Website and starter
  shortcuts; no saved setting is required for a useful initial page.
- Stable `QSettings` keys retain the Desktop Website address, shortcut appearance,
  ordered shortcut list (including duplicates or an intentionally empty list),
  window geometry, and window state. No key or organization/application identity
  changes are made by this review.
- Code and focused tests cover URL validation, non-saving preview/cancel behavior,
  settings save behavior, external link policy, shortcut editing and persistence,
  two-row overflow, label eliding, minimum targets, keyboard focus, and shortcut
  appearance. Real web services and full desktop integration remain manual checks.
- Zorin appearance detection runs once at startup. Match Computer follows the
  native application palette; Light and Dark affect only shortcut buttons. System
  fonts and DPI behavior are inherited, visible focus is retained, and no
  permanent UI area was enlarged in this review.

### Diagnostics, safety, and dependencies

- A rotating log is created under
  `~/.local/state/GrayHairedDesktop/grayhaired-desktop.log`, with a 1 MB rotation
  threshold and three backups. The Help action opens that folder. Timing is
  limited to useful startup, load, and OS handoff events. URLs are sanitized to
  scheme/host/path and omit query strings, fragments, user names, and passwords.
  There is no telemetry or analytics.
- External destinations accept complete HTTP/HTTPS URLs. Runtime code constructs
  no shell command from user input. The only subprocess call invokes `gsettings`
  as a fixed argument list with `shell=False` behavior. The application requests
  no elevation; setup uses `sudo` only for missing OS packages. Update uses
  fast-forward Git and neither script removes unrelated files.
- Runtime dependencies are declared in `pyproject.toml`: Python 3.12+ and
  `PySide6>=6.7,<7`. PySide6 includes QtWebEngine. `requirements.txt` matches the
  runtime range. Ruff and pytest are test tools, not runtime requirements. No
  broad dependency upgrade was made.
- No user-specific runtime or developer checkout path was found. Test temporary
  paths are isolated fixtures. Historical references to alpha releases and older
  architecture terminology remain only where they describe project history.

## Linux portability assessment

Code inspection separates the likely portability of the **application runtime**
from the much narrower portability of **`scripts/setup-zorin.sh`**. Inspection is
not a substitute for running the application on each distribution and desktop.

### Tested / supported now

- Zorin OS is the only manually tested and currently supported environment. The
  Version 1.0 decision in this report is explicitly Zorin-focused.
- The supported installation route is the repository's Bash/apt-based Zorin setup
  script followed by its run script. No other distribution setup is supported.

### Likely compatible but unverified

- The core runtime is mostly distribution-neutral Python and PySide6. Once Python
  3.12+, PySide6/QtWebEngine, a working Qt Linux platform plugin, its system
  libraries, and a desktop default-URL handler are present, it is reasonable to
  expect the application to start on another modern graphical Linux distribution.
  This is an audit conclusion, not a support or test claim.
- Runtime paths use the current user's home directory for logs. `QSettings` uses
  Qt's per-user INI behavior, and external links/log folders use
  `QDesktopServices.openUrl`; none requires a Zorin-specific filesystem path.
- The runtime contains no explicit X11 or Wayland API. Qt chooses its available
  platform plugin. Actual windowing, focus, scaling, QtWebEngine sandbox/GPU
  behavior, and default-browser handoff still require testing under both display
  systems.
- Ubuntu LTS with GNOME is the closest likely runtime/setup candidate because
  Zorin is Ubuntu-based and the appearance fallback reads a GNOME setting.
  Linux Mint/Cinnamon is also a plausible runtime candidate because Cinnamon
  commonly provides `gsettings`, but its schema/value behavior must be verified.
  Debian/GNOME and Fedora Workstation/GNOME look like plausible **runtime**
  candidates after their dependencies are installed. None is currently supported.

### Distribution-specific installation work needed

- `setup-zorin.sh` is Debian/Ubuntu-family specific: it queries packages with
  `dpkg-query`, installs with `apt-get`, and assumes Debian/Ubuntu package names
  `pythonX.Y-venv`, `python3-pip`, and `libxcb-cursor0`. It invokes `sudo` only
  when one or more of those OS packages is missing.
- Ubuntu may be able to use the same script and Mint may be able to use a related
  path, but both are untested. Debian may need repository/version and package-name
  adjustments, particularly to provide Python 3.12 and the matching venv package.
- Fedora, Arch, and other non-Debian distributions need separate package-manager
  prerequisites/instructions; the current setup script will not work unchanged.
- `run.sh` is otherwise a Bash/virtual-environment launcher, and `update.sh` is a
  Bash/Git workflow. They are likely portable after a suitable environment and
  checkout exist, but that has not been verified outside Zorin.

### Known desktop-environment limitations

- The optional appearance correction calls `gsettings get
  org.gnome.desktop.interface color-scheme` once at startup. On GNOME, this should
  represent the intended preference. Cinnamon may expose the schema but needs
  verification. KDE Plasma, XFCE, and MATE do not reliably use this GNOME setting,
  so **Match Computer** may not receive the extra correction on those desktops.
- If `gsettings` is absent, the schema/key is absent, the command fails, or it
  times out, detection returns `UNKNOWN` and applies no fallback palette. The
  application continues with Qt's existing palette; functionality is unaffected,
  but automatic appearance matching may be imperfect. Explicit Light and Dark
  shortcut appearances remain independent of this native-palette correction.
- There is no live theme monitoring. A theme change during a session requires an
  application restart, including on Zorin.

### Unknown / requires real testing

- QtWebEngine system-library completeness, multimedia/GPU behavior, sandboxing,
  native Qt appearance, high DPI, keyboard focus, browser handoff, and per-user
  settings locations cannot be proven across distributions by code inspection.
- KDE Plasma is a useful additional desktop-environment check because it exercises
  a non-GNOME settings and appearance stack. XFCE and MATE remain unknown as well.

Recommended future matrix, in order: Ubuntu LTS/GNOME, Linux Mint/Cinnamon,
Debian stable/GNOME, Fedora Workstation/GNOME, then KDE Plasma on one maintained
distribution. Record runtime and clean-install results separately. This broader
testing is **future compatibility/distribution work, not a blocker** for a
truthfully labeled, tested-and-supported-on-Zorin Version 1.0 decision. A defect
found during the required Zorin checklist would still be a release blocker.

## Public documentation preparation

The future public instruction sheet must cover:

- download and integrity verification;
- installation prerequisites and installation;
- first launch;
- choosing the Desktop Website;
- adding, editing, removing, ordering, and opening shortcuts;
- Settings and Shortcut Appearance;
- the gear/Open controls button and Done;
- external browser behavior;
- updating;
- logs and Help;
- uninstall/removal for the distribution method provided.

The future release website must state:

- supported OS and tested Zorin versions;
- exact application version;
- download/artifact type and package size (not yet known);
- Python/system/install requirements, if still source-based;
- screenshots of the Desktop Website, controls, Settings, shortcut editing, and
  light/dark behavior;
- available checksums and signing status;
- known limitations, including the startup-only appearance check;
- a support/contact destination;
- update instructions.

It must not claim Windows or macOS support.

## Manual Zorin release checklist

Every item remains pending until recorded during final manual verification.

### INSTALL / START

1. Application starts normally from updated main.
2. No Alpha/Beta wording appears in normal user-facing UI.
3. Version shown in About is correct.
4. No developer/debug UI appears.
5. Desktop Website loads successfully.

### DESKTOP WEBSITE

6. Home works.
7. Reload works.
8. Another Website... works.
9. Website Address validation works.
10. Preview in Browser works.
11. Save works.
12. Cancel works.
13. Desktop Website links open externally.
14. Desktop Website stays in place.

### SHORTCUTS

15. Starter shortcuts appear correctly.
16. Add Shortcut works.
17. Edit Shortcut works.
18. Remove Shortcut works.
19. More... works.
20. Shortcuts persist after restart.
21. Shortcut order persists.
22. Light appearance works.
23. Dark appearance works.
24. Match Computer works.
25. Light/Dark buttons look same visible height.
26. No third row appears.

### SYSTEM APPEARANCE

27. Zorin Light produces light native UI.
28. Zorin Dark produces dark native UI.
29. Settings follows native appearance.
30. Shortcut Appearance remains independent.

### KEYBOARD / ACCESSIBILITY

31. Alt+H works.
32. Ctrl+R works.
33. Escape behavior works.
34. Tab / Shift+Tab work in dialogs.
35. Focus remains visible.
36. Tooltips/help bubbles work.
37. Larger system text does not clip.
38. Desktop Website area is unchanged.

### PERSISTENCE / UPDATE

39. Existing shortcuts remain after update.
40. Existing Desktop Website setting remains after update.
41. Shortcut Appearance remains after update.
42. Window state remains sensible.

### DIAGNOSTICS

43. Log file is created.
44. Help → Open Log Folder works.
45. No obvious sensitive information is exposed unnecessarily.

### FINAL IMPRESSION

46. Application feels complete rather than experimental.
47. No obvious release blocker remains.
48. Nothing requires developer knowledge during normal daily use.
49. Current public installation path is accurately documented.
50. Version 1.0 could be released without misrepresenting platform support.
