# Project Principles

The desktop application should remain clear, dependable, and approachable. These principles guide technical decisions and contributor behavior.

## 1. Serve the user first

The application exists to make a configurable desktop web experience easy to open and comfortable to use on Zorin OS. Native features should make that experience simpler, not distract from it.

## 2. Keep the native shell focused

The Python application should provide desktop responsibilities: windowing, navigation, preferences, persistence, diagnostics, and platform integration. Documentation and architecture should leave room for the configured web destination and public branding to evolve before Version 1.0.

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

## 8. Keep branding flexible

My Desktop is the public/display product name. GrayHairedDesktop remains the
technical/internal compatibility identity. GrayHaired Tech and Ron Doyle are
appropriate project attribution. Branding work must not rename the repository,
package, legacy QSettings application identity, application IDs, or data paths.
