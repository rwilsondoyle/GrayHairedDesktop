# Project Principles

GrayHaired Desktop should remain clear, dependable, and approachable. These principles guide technical decisions and contributor behavior during the alpha phase.

## 1. Serve the user first

The app exists to make the GrayHaired Tech desktop experience easy to open and comfortable to use on Zorin OS. Native features should make that experience simpler, not distract from it.

## 2. Keep the native shell focused

The Python application should provide desktop responsibilities: windowing, navigation, preferences, persistence, diagnostics, and platform integration. The hosted GrayHaired Tech web experience remains the primary content surface.

## 3. Prefer understandable changes

Future contributors should be able to read the code and documentation without specialized project history. Favor direct names, small modules, and plain Markdown explanations.

## 4. Verify on the target platform

Zorin OS is the target environment. Changes that affect setup, launch, Qt behavior, or packaging should be verified on real Zorin hardware when possible, with results recorded in `DEVELOPMENT_LOG.md`.

## 5. Protect user settings

Preferences and window state should remain stable across updates. Migration or reset behavior should be deliberate and documented.

## 6. Keep installation repeatable

Setup and update scripts should be safe to rerun, explain failures clearly, and avoid surprising local changes.

## 7. Separate documentation and application changes

Documentation-only milestones should not change application source code. Application changes should include enough documentation updates to keep users and contributors oriented.
