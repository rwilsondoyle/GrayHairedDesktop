# Changelog

All notable project changes should be summarized here. This project is currently in alpha, so entries focus on practical milestones rather than formal release packaging.

## Alpha 0.5 — Launch Page Personalization

Status: Implementation complete; manual Zorin verification pending.

### Added

- Added **Open Home Page** for opening the currently entered address in the default browser without saving it or closing Preferences.
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

- Preferences dialog for the home page URL.
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
