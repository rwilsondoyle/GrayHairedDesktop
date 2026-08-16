# Version 1.0 release-readiness review

Status: **NO-GO.** The automated readiness audit completed with **54 passed,
10 skipped**, but final physical verification of the release candidate is still
pending on both Wayland and X11. The version remains `0.9.0`.

## Release finding

The release decision at the time of this audit is **NO-GO**. Although the
automated suite reports **54 passed, 10 skipped**, final physical Wayland and
X11 verification are both pending. Settings also still exposes a misleading
**Desktop Mode** control. That control is a release blocker because true Desktop
Mode is now Future Research and normal Version 1.0 users must not be promised
unsupported background placement. The public product name had not yet been
finalized at the time of this audit.

This audit makes no runtime, naming, Settings, launcher/autostart, source, or
test changes. Version `0.9.0` must remain unchanged. A later implementation
change must resolve the misleading Settings control without rewriting this
audit record.

### Version 1.0 status table

Completed work is recorded as such and is not an active blocker.

| Item | Current status |
| --- | --- |
| Native PySide6/Qt application | **COMPLETE** |
| Desktop Website display and external browser links | **COMPLETE** |
| Customizable shortcuts | **COMPLETE** |
| Settings and persistent preferences | **COMPLETE** |
| Accessibility and keyboard navigation | **COMPLETE** |
| Logging and diagnostics | **COMPLETE** |
| Light/dark appearance compatibility | **COMPLETE** |
| Stable installed launcher | **COMPLETE** |
| Application-menu launcher | **COMPLETE** |
| Update lifecycle | **COMPLETE** |
| Uninstall lifecycle | **COMPLETE** |
| Canonical XDG autostart | **COMPLETE** |
| X11 login/autostart physical verification | **PASSED** |
| Wayland login/autostart physical verification | **PASSED** |
| Single-instance guard | **COMPLETE** |
| X11 single-instance physical verification | **PASSED** |
| Wayland single-instance physical verification | **PASSED** |
| Desktop Website link follow-up | **NO CURRENT PROBLEM OBSERVED** |
| Installed runtime independence from checkout | **COMPLETE** |
| Designed preference preservation through update/uninstall | **COMPLETE** |
| Version 1.0 product scope | **APPROVED — SAFE WINDOWED LAUNCH PAGE** |
| True Desktop Mode | **FUTURE RESEARCH — NOT A VERSION 1.0 BLOCKER** |
| PR #45 new-architecture investigation | **RESULT 3 — NO PRACTICAL SUPPORTED PATH FOUND** |
| PR #45 physical read-only collector | **PASSED — WAYLAND / GNOME SHELL 46.0** |
| Final Version 1.0 manual checklist | **PENDING** |
| Final public product name | **PENDING if still required before release** |

### Current blockers

- Complete the final Version 1.0 manual checklist.
- Decide the final public product name if that decision is still required before
  release.
- Only after all applicable checks pass, make an explicit release decision and
  change both version locations together. Version `0.9.0` remains current.
- Resolve any genuinely incomplete checklist item discovered during final
  testing; none is invented in advance by this review.

PR #45 found that private access to the running Zorin extension is technically
plausible but supplies neither a supported cooperation contract nor a shared
icon/content surface. Icon pixels live in external GTK client windows. GNOME 46
exposes no supported background/external-surface layer for this use, and a
PipeWire, DMA-BUF, Wayland-buffer, or shared-memory mirror would require an
impractical custom frame, input, focus, clipboard, and accessibility bridge.
Under the former Path A, Result 3 would have left Version 1.0 blocked. In PR #46,
the owner selected PR #44 Path B: the safe windowed application is now the
supported Version 1.0 scope, and true Desktop Mode has moved to future research.
The physical Inspiron-3147 collector confirmed the Zorin provider active, its
external `app/ding.js` icon client running, and Zorin source use of live
extension-manager lookup. It performed no mutation and found no supported
surface-registration or composition hook, so the classification is unchanged.

### Non-blocking polish

- Refresh older architecture and development-history prose as the implementation
  evolves. Historical milestone names and test records are intentionally retained.
- Decide the final public product name before producing signed, branded artifacts.
  GrayHairedDesktop remains the repository/package identity, while GrayHaired
  Desktop is only current working/display wording. This review selects no name.

### Future distribution polish

- Consider a native distro package and signed artifacts beyond the completed
  user-local installer and application-menu launcher.
- Add release checksums and, if practical, signed artifacts.
- Publish a concise public instruction sheet and technical release page using the
  checklists below.

These are distribution improvements rather than blockers for a clearly described
source-based 1.0 release.

## Desktop Mode product decision

PR #44 recorded two possible paths. PR #46 is the explicit owner decision:
**Path B is selected.** GrayHaired Desktop Version 1.0 will use the current safe
windowed launch-page architecture as its supported product scope. True Desktop
Mode remains a future research goal and is no longer a Version 1.0 release
blocker. This is an evidence-based scope decision, not abandonment of the
original concept and not a Version 1.0 release declaration.

### Path A — historical alternative, not selected

Version 1.0 remains blocked until a new architecture safely provides the exact
required Zorin/GNOME layer. The version remains `0.9.0`; the project must not
weaken the definition of Desktop Mode, call an ordinary maximized or borderless
window Desktop Mode, hide real desktop icons, or resurrect rejected PR #39
mechanisms. The next engineering investigation must be materially different.

### Path B — selected Version 1.0 scope

The existing safe windowed application will proceed toward Version 1.0 after the
final readiness pass. The supported product is a stable, senior-friendly desktop
launch-page application for Zorin OS that displays the configured Desktop
Website and provides customizable shortcuts, Settings, diagnostics, safe startup
behavior, and reliable local installation. The normal windowed application is
not described as Desktop Mode. The release and `1.0.0` version bump remain a
separate later decision.

### Future-research trigger

Resume true Desktop Mode research only if Zorin Desktop Icons introduces a
supported background/provider API; GNOME/Mutter introduces a supported external
surface/background layer; Zorin provides an explicit third-party integration
point; Mutter supports a relevant new upstream protocol; or a substantially
different architecture avoids the rejected mechanisms. Do not restart the
experiments merely because GNOME or Zorin receives a routine update.

## Required Desktop Mode and rejected approaches

The required interactive order remains:

```text
GNOME wallpaper
↓
GrayHaired Desktop live Desktop Website
↓
real Zorin Desktop Icons
↓
ordinary application windows
↓
Zorin panel, taskbar, menus and shell chrome
```

GrayHaired Desktop must not replace or hide the icon manager, modify Zorin
system extension files, require compositor patches, poll/restack against the
compositor, impersonate another application, or leave unsafe persistent Shell
experiments enabled.

PR #39 physically rejected these mechanisms for that requirement:

| Approach | Result |
| --- | --- |
| Pure Qt desktop-type window | Hidden below Zorin/GNOME's desktop surface. |
| Normal Qt stays-below window | Visible, but above and hiding the real Zorin icons. |
| `Meta.Window.lower()` | Did not produce the required visible order. |
| Direct `MetaWindowActorWayland` sibling reordering | Reported order changed without the required visible icon relationship. |
| Managed `Meta.WaylandClient.hide_from_window_list()` | Changed window-list/taskbar semantics, not the desktop layer. |
| Shell-owned actor immediately above `backgroundGroup` | Appeared above wallpaper but also above icons and normal windows; the persistent development extension also caused a reboot/recovery hazard until disabled. |
| Supported Zorin cooperation API | Read-only inspection found no supported third-party surface-registration or relative-layer API in the installed provider. |

Managed `Meta.WaylandClient` ownership itself **PASSED**, but ownership did not
solve relative desktop layering and is not a successful Desktop Mode result.

## Evidence-based recommendation

Another small Qt flag adjustment or variation on the rejected GNOME stacking
experiments is unlikely to satisfy the requirement. If Path A remains mandatory,
the next investigation should evaluate a materially different architecture,
without assuming feasibility: a separately maintained integration participating
in the icon provider's rendering architecture without modifying system files; a
supported background/plugin mechanism with interaction handled separately; an
upstream-supported GNOME protocol or extension architecture absent from the
tested Zorin implementation; or evidence that no safe supported relative layer
exists and the product requirement must change. PR #44 implements none of these.

## Historical Desktop Mode evidence

Detailed experiment chronology remains in
[`GNOME_SHELL_FEASIBILITY.md`](GNOME_SHELL_FEASIBILITY.md) and the development
log. Those records explain why each approach was attempted; they are historical
evidence, not current proposals. The product decision and rejection table above
are the current release finding.

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

**What exists now:** `scripts/install-user.sh` creates a dedicated, non-editable
user-local runtime, stable `~/.local/bin/grayhaired-desktop` command, and
application-menu launcher without runtime dependence on the checkout. The
matching update and ownership-safe uninstall scripts preserve preferences. This
lifecycle passed physical testing. The Git checkout's `scripts/setup-zorin.sh`,
project `.venv`, and `scripts/run.sh` remain the separate contributor path.

**Clean-install path:** from a downloaded release or source checkout, run
`./scripts/install-user.sh`, then launch from the application menu or stable
command. The exact commands and prerequisites are in the README. No repository
file or development `.venv` is used at installed runtime.

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

## User-local launcher status

Version 0.9.0 now has a no-`sudo` user-local install/update/uninstall lifecycle.
It uses a dedicated installed venv, stable `~/.local/bin/grayhaired-desktop`
entry point, application-menu launcher, and the existing opt-in canonical XDG
autostart design. It does not alter GNOME Shell, Zorin files, Desktop Mode, or
normal application runtime behavior. Development continues to use `scripts/run.sh`
and the checkout `.venv`; installed updates use `scripts/update-user-install.sh`
from a newer release checkout and preserve Qt settings.

The corrected lifecycle passed physical testing on the Inspiron-3147 under
Wayland: its final-path shebang, stable command, repository independence,
application-menu launch, opt-in canonical autostart, single login launch, and
ownership-safe uninstall all worked. The earlier failed physical install is
retained in the launcher audit because it exposed the relocated-venv shebang bug.

X11 and Wayland installed login/autostart testing subsequently passed. PR #43's
single-instance guard also passed both sessions: a second invocation returned
normally without another window and exactly one real process remained. GNOME's
attention indication instead of forced focus is acceptable. Desktop Website
links opened normally during follow-up, with no current performance problem
observed. Desktop Mode is now future research rather than a Version 1.0 blocker.
The applicable final manual checklist, any still-required public-name decision,
and the explicit release/version bump remain, not these completed items.
