# Changelog

All notable project changes should be summarized here. Historical entries retain their milestone names; release packaging begins only after its own review and verification.

## Alpha 0.8 — Stability, Performance and Diagnostics

Status: Implementation complete; manual verification performed on the Inspiron-3147 test system.

### Added

- Added persistent rotating logs in the user's Linux state directory while preserving terminal logging.
- Added elapsed timing for application startup milestones and sequential Desktop Website loads.
- Added timing and success reporting for external-link handoff calls, without representing them as external browser page-load measurements.
- Added **Open Log Folder** to the Help menu.

### Notes

- These diagnostics are intended to investigate startup and loading performance; no performance improvement is claimed yet.
- GPU, Vulkan, VA-API, hardware-acceleration, and GPU-rendering settings are unchanged.
- One Zorin diagnostic run on the Inspiron-3147 verified persistent log creation, **Open Log Folder**, initial and Settings-triggered loads, Home, Reload, and external shortcut handoff. Its timings are machine-specific observations, not universal performance benchmarks.

## Alpha 0.7 — Customizable Desktop Shortcuts

Status: Implementation complete; manual verification pending.

### Added

- Added a compact, wrapping shortcut launcher below the Desktop Website with no visible Favorites heading.
- Added **+ Add Shortcut** plus a right-click menu for **Edit Shortcut** and confirmation-protected **Remove Shortcut**; normal Qt hover help explains how to edit without a permanent edit control.
- Added persistent ordered shortcuts using `QSettings`, including support for multiple shortcuts of the same type.

### Changed

- Shortcut destinations open externally and leave the dominant Desktop Website unchanged.
- Starter shortcuts are examples provided on first use only; every shortcut can be edited or removed.

## Alpha 0.6 — Desktop Website Selection

Status: Implementation complete; manual Zorin verification pending.

### Added

- Added **Another Website...** first, followed after a separator by Bing, DuckDuckGo, Google, MSN, and Yahoo in alphabetical order.
- Added one reusable immutable configuration structure containing each built-in display name and website address.
- Added short **Website Address** help and an example; the field is enabled only for **Another Website...**.

### Changed

- **Settings** replaces **Preferences** in user-visible wording.
- **Preview in Browser** opens either a built-in or valid custom selection externally without saving, closing Settings, or changing the page in the application.
- **Save** validates custom addresses, persists the selection, closes Settings, and loads it immediately. **Cancel** preserves the previous selection and current page.
- No widget system has been added.

## Alpha 0.5 — Launch Page Personalization

Status: Implementation complete; manual Zorin verification pending.

### Added

- Added **Preview Home Page in Browser** for opening the currently entered address in the default browser without saving it or closing Preferences.
- Added a confirmation-protected **Restore Default Home Page** action.
- Added reusable validation for complete HTTP and HTTPS Home Page addresses and friendly error messages.

### Changed

- Improved the Preferences dialog with plain-English help, clearer labels, readable spacing, and keyboard-friendly ordering.
- Selecting **OK** loads and saves a valid changed Home Page; selecting **Cancel** leaves the saved preference unchanged.
- No widget system has been added yet.

## Alpha 0.4 — Desktop launch page

Status: complete.

### Added

- Added desktop launch-page handling that sends clicked links and new-window/new-tab requests to the operating system's default browser.
- Added privacy-conscious destination logging and a clear status message when the default browser cannot open a link.

### Changed

- The configured home page now remains inside the application when a link opens externally.
- Removed Back and Forward actions, shortcuts, history state, menu entries, and toolbar controls.
- The View menu now contains Home and Reload; the toolbar contains Home, Reload, and Preferences.

### Verified

- Completed manual verification on both supported physical Zorin systems: Primary Development System and Secondary Test System.
- On both systems, successfully verified Application startup, Home page, Home, Reload, Preferences, About, Exit, external link launching, and that the Home page remains displayed after launching links.

The public product name is still undecided.

## Alpha 0.3.1 — Documentation foundation

Status: complete.

### Added

- Added the `docs/` documentation set:
  - `ARCHITECTURE.md`
  - `ROADMAP.md`
  - `DEVELOPMENT_LOG.md`
  - `CHANGELOG.md`
  - `PROJECT_PRINCIPLES.md`
- Added contributor-facing architecture, roadmap, principles, and verification notes.
- Documented successful manual verification on the physical Zorin systems named Primary Development System and Secondary Test System.
- Recorded that both systems successfully completed `git pull`, `scripts/setup-zorin.sh`, `scripts/update.sh`, and `scripts/run.sh`, then verified Application startup, Home, Reload, Preferences, About, and Exit.

### Changed

- Updated the README to reference the new documentation foundation.

## Alpha 0.3 — Preferences and persistence

Status: complete.

### Added

- Preferences dialog for the Home Page address.
- Persistent user preferences with `QSettings`.
- Home and Reload actions in the menu and toolbar.
- Persistent window geometry and state.
- Structured logging for startup, shutdown, preferences, page loads, successful loads, and load failures.

## Alpha 0.2 — Native browser shell

Status: complete.

### Added

- Native Qt main window.
- Embedded a QtWebEngine browser surface for the configured desktop web experience.

## Alpha 0.1 — Project skeleton

Status: complete.

### Added

- Initial Python package structure.
- Project metadata and dependency declarations.
- Application entry point foundation.
