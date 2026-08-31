# Automatic Blend promoted — 2026-08-29

Automatic Blend has been promoted into the supported GNOME installer/verifier path after physical testing on the primary Inspiron 3502 X11 session.

Physically proven behavior before promotion:

- Solid `desktop-d` edge sampling returned one uniform color and Stage 2 removed the visible icon-pane seam.
- DING icon left-click, right-click, drag, persistence, and live Tiny/Small/Standard/Large sizing remained functional.
- Photographic `desktop-c` BODY background detection found the active rotating photograph.
- The final Stage 5C path cleaned the CSS-derived URL, cached the active photo locally, and painted it behind the real DING icon pane.
- Reloading `desktop-c` selected the alternate rotating photograph and the icon pane followed it successfully.
- Stage 6 synchronized the real GNOME wallpaper to the cached active photograph so the translucent Zorin taskbar matched the live desktop.
- Original GNOME wallpaper settings are saved and can be restored with `scripts/restore-live-desktop-wallpaper-stage6.sh`.

Promotion changes:

- `scripts/patch-live-desktop-photo-continuation-stage3.sh` is now page-neutral. Pages without a BODY image keep the solid sampled-color blend; photographic pages use the photo path.
- `scripts/patch-live-desktop-automatic-blend-promoted.sh` is the single supported Automatic Blend patch entry point.
- `scripts/install-gnome-live-desktop.sh` now installs the base GNOME live desktop and promoted Automatic Blend.
- `scripts/verify-live-desktop-known-good.sh` now verifies both the proven geometry/WebKit runtime and the promoted Automatic Blend markers.

Next acceptance gate: clean reinstall through the generic installer on X11, followed by runtime verifier and physical solid/photo spot checks; then repeat the clean acceptance on Wayland.
