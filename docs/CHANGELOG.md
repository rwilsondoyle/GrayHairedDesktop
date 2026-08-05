# Changelog

All notable project changes should be summarized here. This project is currently in alpha, so entries focus on practical milestones rather than formal release packaging.

## Unreleased

### Changed

- Refactored the main-window UI code into focused action, menu, and toolbar modules without intentionally changing appearance or behavior.

## Alpha 0.3.1 — Documentation foundation

Status: in progress.

### Added

- Added the `docs/` documentation set:
  - `ARCHITECTURE.md`
  - `ROADMAP.md`
  - `DEVELOPMENT_LOG.md`
  - `CHANGELOG.md`
  - `PROJECT_PRINCIPLES.md`
- Added contributor-facing architecture, roadmap, principles, and verification notes.
- Documented Zorin verification status for two computers: one reported successful and the second pending until confirmed.

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
