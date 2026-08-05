# Development Log

This log records project-level development milestones and verification notes. It is intentionally concise so future contributors can quickly understand what changed and what still needs confirmation.

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
- Added Preferences for editing the home page URL.
- Added persistent preferences and persistent window geometry through `QSettings`.
- Added application, browser, preferences, load-success, and load-failure logging.

### Alpha 0.3.1 documentation foundation

- Added dedicated documentation for architecture, roadmap, changelog, development history, and project principles.
- Updated the README to direct users and contributors to the new documentation set.
- No application source code was changed for this documentation milestone.

### Task 009 UI refactor

- Separated action creation, menu construction, and toolbar construction into focused UI modules.
- Kept the main window responsible for browser coordination, preferences, status updates, dialogs, and persistent window state.
- Preserved the existing user-visible wording, layout, and behavior; this milestone adds no visible features.

## Zorin verification notes

The project targets Zorin OS, so manual verification on real Zorin computers is part of the alpha process.

| Computer | Status | Notes |
| --- | --- | --- |
| Zorin computer 1 | Successful | Setup and run verification has been reported successful on one Zorin computer. |
| Zorin computer 2 | Pending | Second-computer verification should be recorded here after setup and run are completed successfully. |

When the second Zorin verification is complete, update this table with the exact date, hardware notes if useful, and any setup issues encountered.

## Contributor workflow notes

- Keep source changes and documentation-only changes separated when practical.
- Do not alter application source code for documentation-only tasks.
- Prefer small milestones with clear manual verification steps.
- Record Zorin-specific findings in this log so future setup scripts and docs can improve from real installation feedback.
