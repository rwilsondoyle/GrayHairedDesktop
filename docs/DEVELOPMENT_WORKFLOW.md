# GrayHaired Desktop Development Workflow

This document explains how the project owner, ChatGPT, Codex, and GitHub work together.

## Roles

- **Project Owner:** Ron Doyle. Chooses priorities, approves features, tests releases, and decides what is merged.
- **Technical Lead:** ChatGPT. Designs features, writes task specifications, reviews pull requests, and helps diagnose test failures.
- **Implementation Engineer:** Codex. Writes and edits code on feature branches according to an approved task specification.
- **Source of Truth:** GitHub. Stores the official code, issues, pull requests, and release history.

## Standard Work Cycle

1. Create a GitHub Issue describing one focused task.
2. Write clear acceptance criteria before coding begins.
3. Start a Codex task using the correct repository and the `main` branch.
4. Codex creates a new feature branch.
5. Codex implements only the issue's requested work.
6. Codex commits its changes and creates a Pull Request.
7. Review the Pull Request before merging.
8. Merge only after the review is satisfactory.
9. Update the local Zorin copy with `git pull`.
10. Test the feature on the actual Zorin computer.
11. Report any failure with the full error message or a screenshot.
12. Close the related GitHub Issue only after the acceptance test passes.

## Branch Naming

Use short, descriptive branch names:

- `feature/alpha-0.3-settings`
- `feature/auto-refresh`
- `fix/browser-load-error`
- `docs/development-workflow`

Never develop directly on `main`.

## Pull Request Rules

Every Pull Request should:

- Address one issue or one closely related change.
- Explain what changed.
- Include testing instructions.
- Use type hints and docstrings where appropriate.
- Follow PEP 8.
- Keep modules reasonably small and focused.
- Update the README or CHANGELOG when user-visible behavior changes.
- Avoid unrelated cleanup or redesign.
- Remain unmerged until reviewed.

## Testing Rules

Testing happens in two stages:

### Automated or Code-Level Checks

- Python syntax compiles.
- Imports are valid.
- Formatting and lint checks pass when configured.
- Tests pass when tests exist.

### Live Zorin Test

- The program launches normally.
- The new feature works as described.
- Settings survive closing and reopening the program.
- Errors are visible and logged rather than silently ignored.
- The program closes cleanly.

## Version Plan

- **Alpha:** Core functions are still being added and may change.
- **Beta:** Major features are present; focus shifts to reliability and usability.
- **Release Candidate:** Feature-complete and ready for final testing.
- **Version 1.0:** Suitable for general installation and use.

## Safety Rules

- Never merge code that has not been reviewed.
- Never delete a working release without a backup or Git tag.
- Never store passwords, private keys, or personal information in the repository.
- Do not run copied terminal commands unless their purpose is understood.
- Keep each working release available so it can be restored if a later change breaks something.

## Codex Task Template

```text
Repository: rwilsondoyle/GrayHairedDesktop
Base branch: main
Related issue: #NUMBER

Create a new branch named: feature/SHORT-NAME

Implement only the requirements in the related issue.
Do not modify main directly.
Use clean, modular Python with type hints and docstrings.
Update documentation when behavior changes.
Run available checks.
Commit all changes and create a Pull Request into main.
Include a summary and testing instructions in the Pull Request.
```
