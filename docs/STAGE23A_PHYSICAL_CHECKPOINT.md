# Stage 23A Physical Checkpoint

Date: 2026-09-02
Test machine: Dell Inspiron 3502
Session: Zorin / GNOME Wayland

## Result

PASS for core friendly website-failure recovery behavior.

Verified physically:
- unreachable configured site no longer leaves only WebKit's terse DNS error;
- GrayHairedDesktop shows a friendly "Website Not Available" recovery page;
- the configured failing site address is shown;
- Retry is a real user-gesture navigation and is intercepted by GrayHairedDesktop;
- Retry reloads the saved configured URL without changing the saved website;
- when the test `.invalid` site fails again immediately, the same friendly recovery page returns;
- restoring the original saved site brings the normal live desktop website back successfully.

## Retry feedback experiment

A follow-up attempt to change the visible Retry label to "Trying…" before navigation did not produce visible feedback on the physical WebKit surface. This visual-only enhancement is not required for the core recovery behavior because journal logs confirmed the retry action itself works correctly.

Stage 23A should keep the physically proven direct HTTP(S) retry behavior and avoid depending on inline-JavaScript visual feedback.
