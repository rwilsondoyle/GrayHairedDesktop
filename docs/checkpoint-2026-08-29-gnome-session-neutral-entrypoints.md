# Checkpoint: GNOME session-neutral Live Desktop entry points

Date: 2026-08-29

GrayHaired Live Desktop has now been physically proven on both GNOME Wayland and GNOME X11 using the same DING/WebKit split-surface implementation.

This checkpoint records the cleanup that follows that proof:

- Existing Wayland-named installer and verifier remain available for backward compatibility.
- The installer now accepts `wayland`, `x11`, and `xorg` session types.
- The verifier now accepts and reports all three supported session labels.
- The installed extension display name is now `GrayHaired Live Desktop` rather than `GrayHaired Live Desktop Wayland Prototype`.
- New generic entry points are available:
  - `scripts/install-gnome-live-desktop.sh`
  - `scripts/verify-live-desktop-known-good.sh`
- Existing `GRAYHAIRED_WAYLAND_*` layout variable names remain unchanged for compatibility with the physically tested patch chain; their values now apply to both supported GNOME session types.
- No geometry, input, focus, or WebKit behavior was intentionally changed by this cleanup.

Next planned work: Automatic Blend appearance research, starting with non-destructive sampling/diagnostics before changing the icon-panel appearance.
