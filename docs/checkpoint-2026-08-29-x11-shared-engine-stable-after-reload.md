# Checkpoint: X11 shared GrayHaired engine stable after reload

Date: 2026-08-29
Branch: `codex/research-live-desktop-mode`

## Physical result

On the Dell Inspiron 3502 in an X11 session, the same user-local GrayHaired DING/WebKit extension used for Wayland remained ACTIVE and supplied the live My Desktop surface plus normal desktop icons.

The user confirmed:

- My Desktop visible as the desktop background.
- Normal desktop icons visible in the left two-column area.
- My Desktop links/buttons clickable.
- Desktop icons support left click, right click, and drag.
- A small My Desktop width wiggle was initially observed when moving an icon into the right column.
- After installing the diagnostic allocation logger and safely reloading only the GrayHaired child, the wiggle could no longer be reproduced.

## Allocation evidence

The current X11 GNOME Shell process logged a stable initial allocation:

- icon strip: 204 px
- WebKit: 1162 px
- layout: 1366 px

No additional allocation change was logged while moving the icon between columns after the child reload.

Older allocation events in the same journal output came from the preceding Wayland GNOME Shell process and are not evidence of current X11 movement.

## Architectural implication

X11 is successfully running the same GrayHaired DING/WebKit split-surface architecture as Wayland. The older Qt/X11 mask prototype may therefore be unnecessary for the product path if further X11 stress tests continue to pass.

## Next test

Exercise Tiny / Small / Standard / Large icon-size changes under X11 without child reloads, including repeated left/right-column drags, and confirm:

- automatic two-column width changes,
- full icon visibility,
- stable My Desktop boundary,
- normal click/context-menu/drag behavior.
