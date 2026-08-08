# Version 1.0 release-readiness review

Status: **Version 1.0 implementation review complete; final manual Zorin
verification pending.** This report does not declare Version 1.0 complete.

## Release finding

The reviewed source is a credible Version 1.0 candidate, but it must not be
released as 1.0 until the manual checklist below passes on a clean, supported
Zorin installation and the release-readiness pull request is approved.

### Blockers

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
- Decide final branding before producing signed, branded artifacts. The repository
  and current product consistently use GrayHaired Desktop for this review.

### Future distribution

- Provide a native package or installer and an application-menu `.desktop`
  launcher/icon so a public user need not manage a source checkout or terminal.
- Add a documented uninstaller/removal workflow; today removal is manual.
- Add release checksums and, if practical, signed artifacts.
- Publish a concise public instruction sheet and technical release page using the
  checklists below.

These are distribution improvements rather than blockers for a clearly described
source-based 1.0 release.

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
- The About dialog now uses the product name and runtime version, gives a short
  factual description, describes external browser behavior, and attributes the
  project without prerelease wording or marketing claims.

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
