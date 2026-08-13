# Development Log

This log records project-level development milestones and verification notes. It is intentionally concise so future contributors can quickly understand what changed and what still needs confirmation.

## GNOME Shell Desktop Integration Feasibility

Status: Development-only managed-client ownership test awaiting physical verification.

- Confirmed the target as Zorin OS 18.1 and GNOME Shell 46.0; Phase 1 completed
  successfully in the intended native Wayland session.
- Confirmed `zorin-desktop-icons@zorinos.com` (**Zorin Desktop Icons**) as the
  active provider. Its metadata names the original Desktop Icons extension, while
  installed headers confirm substantial DING-derived implementation code.
- Targeted inspection established that a separate application renders the icons
  in client windows. Zorin manages their `Meta.Window` objects event-by-event,
  including Wayland desktop semantics, lowering, workspace behavior, Activities
  filtering, and per-monitor positioning.
- Retained the proven conclusion that pure Qt window hints cannot preserve the
  required layer. Physical Wayland tests also proved that one `lower()` call and
  direct compositor-actor sibling ordering are insufficient.
- Confirmed `list_all_windows()`, stack sorting, and `window-created` at runtime;
  recorded both client identities and their starting stack. Lowering only
  GrayHaired did not change the order; verification failed and fallback worked.
- Confirmed both Wayland window actors share one `MetaWindowGroup`; changing
  their reported sibling order did not change the visible icon relationship, and
  the experiment restored the previous order.
- Installed-source inspection identified Mutter's
  `Meta.WaylandClient.new_subprocess(global.context, launcher, argv)` as Zorin's
  trusted-client primitive. Added an independently written ownership-only test
  that directly launches the configured Python interpreter, validates managed
  ownership plus exact GrayHaired WM identity, performs no stacking operation,
  and never relaunches automatically.
- The first physical ownership test found `new_subprocess` undefined on GNOME
  Shell 46 and failed safely without launching. The prototype now tests only the
  installed-source-demonstrated older forms—`new(global.context, launcher)` or
  `new(launcher)` followed by managed `spawnv(global.display, argv)`—with no
  ordinary subprocess fallback.
- A subsequent GNOME 46 run exposed `new`, `spawnv`, and window-list methods but
  no raw `query_window_belongs_to`; the managed process was terminated safely.
  Installed source shows Zorin's wrapper implements that method by calling raw
  `Meta.WaylandClient.owns_window(window)`. The ownership test now uses
  `owns_window()` directly and matches Zorin's constructor order:
  `new(launcher)` first, then `new(global.context, launcher)` on failure.
- Added a stable Qt Wayland application ID and X11 `WM_CLASS` without changing
  QSettings identity. Nothing is installed or enabled automatically. Version
  remains 0.9.0, and Desktop Mode remains a pre-1.0 investigation item.

## Alpha 0.8 — Stability, Performance and Diagnostics

Status: Implementation complete; manual verification performed on the Inspiron-3147 test system.

- Added a persistent rotating log alongside existing terminal output at `~/.local/state/GrayHairedDesktop/grayhaired-desktop.log`.
- Timed `QApplication` creation, main-window creation, and main-window display from a shared startup timestamp.
- Added numbered Desktop Website measurements that distinguish initial startup, Home, Reload, and Settings-triggered loads.
- Timed only the `QDesktopServices.openUrl()` handoff for clicked links and desktop shortcuts; this is not a measurement of the external browser's page load.
- Added **Help → Open Log Folder** and documented combined terminal capture for Python, Qt, Chromium, Mesa, and graphics-stack output.
- Added diagnostics to investigate startup and loading performance. No performance improvement or graphics configuration change is claimed.

### Inspiron-3147 Zorin diagnostic run

Manual testing verified persistent log creation, **Help → Open Log Folder**, a successful initial Desktop Website load, a successful Settings-triggered load, Home, Reload, and external shortcut handoff.

| Measurement | Observed time |
| --- | ---: |
| QApplication created | 0.331 seconds |
| Main window created | 1.644 seconds |
| Main window shown | 1.725 seconds |
| Initial Desktop Website load | 3.072 seconds |
| Settings-triggered load | 2.282 seconds |
| Home load | 0.554 seconds |
| Reload | 0.495 seconds |

These measurements are from one diagnostic run on the Inspiron-3147 test system. They are not universal performance benchmarks and do not establish that performance has improved.

## Alpha 0.7 — Customizable Desktop Shortcuts

Status: Implementation complete; manual verification pending.

- Implemented a compact launcher below the Desktop Website with no visible Favorites heading.
- Implemented **+ Add Shortcut**, hover help, and a right-click menu for **Edit Shortcut** and confirmation-protected **Remove Shortcut**, with friendly validation and a built-in symbol chooser.
- Preserved shortcut order in `QSettings`, allowed multiple shortcuts of the same type, and retained an intentionally empty list.
- Routed shortcut clicks through the existing external-opening mechanism so the Desktop Website remains unchanged.

## Milestone history

### Initial foundation

- Created the repository and early Python project files.
- Added the application entry point and requirements needed for a PySide6 desktop shell.

### Alpha 0.1

- Added the initial package skeleton under `src/grayhaired_desktop`.
- Established the QtWebEngine direction for rendering a configurable web experience inside a native desktop window.

### Alpha 0.2

- Implemented the first functional browser shell.
- Added a native `QMainWindow` hosting an embedded browser view.
- Confirmed the application could launch through the Python entry point.

### Alpha 0.3

- Added user-facing navigation for Home and Reload.
- Added Preferences for editing the Home Page address.
- Added persistent preferences and persistent window geometry through `QSettings`.
- Added application, browser, preferences, load-success, and load-failure logging.

### Alpha 0.3.1 documentation foundation

- Added dedicated documentation for architecture, roadmap, changelog, development history, and project principles.
- Updated the README to direct users and contributors to the new documentation set.
- Completed manual verification on two physical Zorin systems.
- No application source code was changed for this documentation milestone.

### Task 009 UI refactor

- Separated action creation, menu construction, and toolbar construction into focused UI modules.
- Kept the main window responsible for browser coordination, preferences, status updates, dialogs, and persistent window state.
- Preserved the existing user-visible wording, layout, and behavior; this milestone adds no visible features.

### Alpha 0.4 desktop launch page

- Changed the embedded mini-browser into a desktop launch page.
- Kept the configured home page displayed inside the application while ordinary links open in the operating system's default browser.
- Covered ordinary clicks, `target="_blank"`, `window.open()`, and new-tab/new-window requests while preserving same-page fragment links.
- Removed Back and Forward actions, shortcuts, toolbar/menu entries, and browser-history coordination.
- Preserved Home, Reload, Preferences, About, Exit, window persistence, logging, and status-message behavior.
- The public product name is still undecided.
- Completed manual verification on both supported physical Zorin systems: Primary Development System and Secondary Test System.
- On both systems, successfully verified Application startup, Home page, Home, Reload, Preferences, About, Exit, external link launching, and that the Home page remains displayed after launching links.
- Alpha 0.4 is complete.

### Alpha 0.5 — Launch Page Personalization

Status: Implementation complete; manual Zorin verification pending.

- Improved Preferences with plain-English help and readable spacing.
- Added **Preview Home Page in Browser** to preview the entered address in the default browser without saving or closing Preferences.
- Added a confirmation-protected **Restore Default Home Page** action that only changes the field until **OK** is selected.
- Added reusable validation for complete HTTP and HTTPS addresses, with a friendly correction message.
- Preserved **Cancel** so edited and restored values do not replace the saved Home Page.
- Preserved the launch page, external links, Home, Reload, About, Exit, window state, status messages, and logging.
- No widget system has been added yet.


### Alpha 0.6 — Desktop Website Selection

Status: Implementation complete; manual Zorin verification pending.

- Replaced user-visible **Preferences** wording with **Settings**.
- Added **Another Website...** first and a separated, alphabetical built-in list: Bing, DuckDuckGo, Google, MSN, and Yahoo.
- Populated built-in choices from one reusable immutable display-name/address configuration structure.
- Enabled **Website Address** only for **Another Website...** and retained custom values when appropriate.
- Made **Preview in Browser** non-saving and non-destructive to the embedded page.
- Made **Save** validate custom choices and immediately apply them; **Cancel** preserves the previous selection and page.
- Preserved Alpha 0.5 navigation, external-link, persistence, status, logging, and script behavior.
- No widget system has been added.

## Zorin verification notes

### GNOME Shell 46 desktop-layer feasibility

- Native-Wayland testing confirmed that `Meta.Window.lower()` did not change the
  relevant visible order and safely fell back.
- A second physical test changed the reported `MetaWindowGroup` sibling order,
  but GrayHaired Desktop still obscured Zorin's real desktop icons; restoration
  succeeded.
- The stacking path remains observation-only. The ownership-only experiment uses
  `Meta.WaylandClient` to launch one configured GrayHaired process as a normal
  window, verifies ownership at map time, and terminates only its retained
  subprocess on disable. It never modifies Zorin Desktop Icons.
- Desktop Mode remains unresolved and Version 1.0 is not declared ready.

The project targets Zorin OS, so manual verification on real Zorin computers is part of the alpha process.

| Physical Zorin system | Status | Verified workflow and behavior |
| --- | --- | --- |
| Primary Development System | Successful | `git pull`; `scripts/setup-zorin.sh`; `scripts/update.sh`; `scripts/run.sh`; Application startup; Home page; Home; Reload; Preferences; About; Exit; external link launching; Home page remaining displayed after launching links. |
| Secondary Test System | Successful | `git pull`; `scripts/setup-zorin.sh`; `scripts/update.sh`; `scripts/run.sh`; Application startup; Home page; Home; Reload; Preferences; About; Exit; external link launching; Home page remaining displayed after launching links. |

These results record manual verification on exactly two physical Zorin systems. They do not represent automated GUI testing, completed Windows testing, or completed virtual-machine testing.

## Contributor workflow notes

- Keep source changes and documentation-only changes separated when practical.
- Do not alter application source code for documentation-only tasks.
- Prefer small milestones with clear manual verification steps.
- Record Zorin-specific findings in this log so future setup scripts and docs can improve from real installation feedback.
