# Wayland Freeze Isolation Checkpoint — 2026-08-21

## Why testing is paused

A further full-machine lockup occurred while the user was simply typing in ChatGPT. No GrayHaired code reload, installer run, extension toggle, or runtime layout change had just been performed; the most recent project actions were Git pulls and read-only verification commands.

## Previous-boot crash report summary

The captured previous-boot report was from Zorin OS 18.1 on kernel `7.0.0-28-generic`.

The report did **not** show an obvious:

- kernel panic
- OOM kill / memory exhaustion event
- watchdog hard/soft lockup report
- machine-check exception
- thermal shutdown
- Intel i915 GPU hang/reset/wedged report

The journal ended abruptly after otherwise ordinary activity, consistent with a hard freeze followed by forced power-off. Existing ACPI/firmware warnings were present from boot, but they were not temporally tied to the freeze.

GNOME/Mutter/window-management warnings were present during the session, so the Wayland/GNOME graphics/window stack remains a plausible area to isolate. This is evidence for further testing, not proof that Mutter, Zorin, or GrayHaired caused the freeze.

## A/B isolation state

To isolate GrayHaired from the next stability observation, the user switched once to the stock Zorin desktop-icons extension and then logged out/in to Wayland.

Verified post-login state:

- `grayhaired-live-desktop@grayhaired.tech`
  - Enabled: No
  - State: INITIALIZED
- `zorin-desktop-icons@zorinos.com`
  - Enabled: Yes
  - State: ACTIVE
- running DING process:
  - stock Zorin child only: `/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com/app/ding.js`
- no GrayHaired DING/WebKit child is running

## Current test rule

Use the machine normally with GrayHaired disabled. Do not run GrayHaired reload/install/recovery scripts during the isolation period.

Interpretation of future observations:

- If the machine hard-freezes again while GrayHaired remains completely disabled, that is strong evidence that the full-system freeze is outside the GrayHaired runtime itself.
- If the machine remains stable for a meaningful period, investigate GrayHaired/Wayland interaction more closely before resuming feature work.

## Project status

Wayland feature development is temporarily paused at the known-good 220-pixel icon-strip milestone. Adaptive icon-strip work is only a future idea and has not been implemented or applied to the running installation.
