# Wayland Live Geometry Promoted — 2026-08-28

The physically verified Wayland icon geometry has been promoted from research-only patch stacking into the normal `install-wayland-separate-ding-prototype.sh` install path.

Promoted sequence:

1. adaptive DING-derived two-column width
2. fixed two-column GTK boundary
3. live Zorin `icon-size` tracking
4. manager-synchronized DING reflow using DING's native remove/resize/update/re-place sequence
5. existing WebKit link, keyboard-focus, and lifecycle safety patches

Physical validation before promotion on Dell Inspiron 3502 / Zorin OS 18.1 / GNOME 46 / Wayland:

- Tiny: PASS
- Small: PASS
- Standard: PASS
- Large: PASS
- automatic width changes require no child reload between size changes
- Large icons remain fully inside the reserved two-column area
- My Desktop boundary remains fixed and does not wiggle when icons are moved

The verifier has also been promoted to require the fixed boundary, live tracking, preserved base Zorin margin, manager-side width synchronization, and DING's native re-placement sequence.

Next step: clean reinstall from the promoted installer, enable GrayHaired, run the full verifier, then physically spot-check live size changes again. No reboot is required for this reinstall test.
