# Wayland Tiny-Icon Drag Allocation Checkpoint — 2026-08-28

## Result

The previously observed slight My Desktop resize when moving tiny desktop icons farther right has been physically measured and explained.

## Test machine

- Dell Inspiron 3502
- Zorin OS 18.1
- GNOME Shell 46
- Wayland
- GrayHaired adaptive icon strip active
- DING icon size: tiny

## Baseline

Adaptive layout selected:

- DING desired cell width: 78 px
- configured columns: 2
- requested strip width: 164 px

Allocation logger baseline:

- icon pane: 164 px
- WebKit pane: 1202 px
- total layout: 1366 px

## Drag observation

After dragging a tiny icon farther to the right, GTK temporarily allocated more width to the DING icon pane:

- icon pane: 189 px
- WebKit pane: 1177 px

It then returned to:

- icon pane: 164 px
- WebKit pane: 1202 px

A later drag/allocation event produced:

- icon pane: 169 px
- WebKit pane: 1197 px

The total layout remained 1366 px.

## Conclusion

The adaptive width calculation itself is not changing during the drag. The calculated/requested strip remains 164 px for tiny icons.

The visible My Desktop resize is caused by GTK allocation behavior: `Gtk.Widget.set_size_request(164, -1)` establishes a minimum/requested width, not a strict maximum. DING's child/container can temporarily request additional natural width, and the horizontal Gtk.Box grants it, reducing the WebKit allocation by the same number of pixels.

This confirms the user's visual observation and isolates the behavior to GTK layout negotiation rather than the adaptive-width formula.

## Next decision

Evaluate whether the DING pane should be hard-capped at the calculated adaptive width or allowed limited natural growth.

A hard cap would keep My Desktop visually stable while icons are moved, but must be tested carefully to ensure it does not clip labels, drag targets, selection backgrounds, or DING context behavior.

Do not change the adaptive formula itself based on this result; the formula is working as intended.
