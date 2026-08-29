# Fixed two-column boundary: Tiny physical pass — 2026-08-28

The reversible Wayland fixed-boundary experiment was physically tested on the Dell Inspiron 3502 in Tiny icon mode.

Result reported by the user: **works as described**.

The intended behavior tested was:

- The live desktop reserves exactly two full DING icon columns.
- Tiny geometry remains a fixed icon-area boundary rather than a GTK minimum that can expand.
- Desktop icons remain clickable.
- Desktop icon context menus remain usable.
- Icons remain draggable/rearrangeable across both reserved columns.
- Dragging an icon toward the right edge no longer causes the My Desktop/WebKit surface to visibly resize or wiggle.
- The WebKit surface stays fixed beside the reserved icon area.

This is the first physical confirmation that the fixed two-column boundary approach resolves the previously measured GTK allocation growth (`164 -> 189 -> 164`, etc.) without breaking normal icon interaction.

## Next physical validation

Repeat the same interaction test at the other Zorin/DING icon sizes:

- Small — expected reserved width about 204 px
- Standard — expected reserved width about 264 px
- Large — expected reserved width about 284 px

For each size, verify icon click, right-click, drag/reposition, two-column usability, and stable My Desktop width.

If all practical sizes pass, promote the fixed boundary from reversible experiment into the permanent Wayland installer and verifier, while preserving the existing adaptive width calculation.
