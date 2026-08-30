# Checkpoint: X11 physical parity PASS — 2026-08-29

On Dell Inspiron 3502 under Zorin OS X11/Xorg, the promoted GrayHaired DING/WebKit live desktop architecture was physically tested and matched the previously verified Wayland behavior.

## Physical test

Without reloading between icon-size changes, tested:

- Tiny
- Small
- Standard
- Large
- back to Tiny

At each size, desktop icons were dragged repeatedly between the left and right columns.

## PASS criteria confirmed

- icon-strip width changed automatically with the Zorin/DING icon-size setting
- all desktop icons remained visible
- the desktop remained a fixed two-column icon area
- My Desktop did not wiggle while icons were moved between columns
- left-click worked
- right-click/context menu worked
- drag/drop worked
- My Desktop remained interactive

## Architecture conclusion

The same GrayHaired user-local DING/WebKit split-surface architecture works on both Wayland and X11 on this test system. A separate Qt/X11 mask implementation is therefore not required for the current product path.

The older `live-desktop-x11-icon-hole.py` prototype remains useful as research history but is not needed as the preferred X11 implementation.
