# Checkpoint — Generic GNOME X11 install PASS — 2026-08-30

Physical test on Inspiron-3502, GNOME X11:

- `scripts/install-gnome-live-desktop.sh` completed successfully after removing the stale Wayland-only WebKit link guard.
- File-only verification passed during installation.
- `scripts/verify-live-desktop-known-good.sh` passed at runtime on `x11`.
- GrayHaired extension ACTIVE.
- Exactly one GrayHaired DING/WebKit child running.
- Stock Zorin DING child not running.
- External-link browser handoff present.
- Fixed adaptive two-column live reflow present.
- Metadata now names the extension `GrayHaired Live Desktop`.
- GNOME Shell may continue displaying the previous cached extension name until logout/login; this is cosmetic.

This confirms the shared GNOME DING/WebKit implementation and the new generic installer/verifier entry points work on X11.
