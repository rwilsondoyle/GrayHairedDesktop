# Wayland persistence and tiny-icon drag checkpoint — 2026-08-28

Physical test machine: Dell Inspiron 3502, Zorin OS 18.1, GNOME 46, Wayland.

## Persistence result — PASS

After the adaptive Wayland installer was promoted and cleanly reinstalled, the user performed:

- normal logout/login
- two normal restarts
- icon-size changes between tiny and large

Observed result: My Desktop returned correctly and the adaptive left icon strip resized with the selected DING icon size across those sessions.

This materially strengthens the Wayland persistence baseline beyond the earlier single-session adaptive tests.

## New observation: tiny-icon drag can slightly resize My Desktop

With DING icon size set to `tiny`, the user observed that moving desktop icons farther to the right can cause the My Desktop/WebKit area to resize slightly to fit.

Current adaptive startup calculation remains:

- tiny desired width 70
- elementSpacing 2
- DING cell width = 70 + 4*2 = 78 px
- two columns + 8 px padding = 164 px strip

The current implementation uses:

`this._eventBox.set_size_request(liveIconStripWidth, -1);`

Important hypothesis to test: GTK `set_size_request()` establishes a minimum request rather than a hard maximum/fixed width. DING child/container natural requisition may therefore expand the icon pane slightly when an icon is dragged farther right, reducing WebKit width correspondingly.

Do not change the layout blindly. Next investigation should measure actual EventBox / container / WebKit allocations before and after rightward icon movement and determine whether the slight growth is benign/desirable or should be capped explicitly.

No regression or failure has been established by this observation. Current state remains usable and persistent.
