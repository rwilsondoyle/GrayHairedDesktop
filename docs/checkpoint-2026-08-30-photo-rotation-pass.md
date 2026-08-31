# Checkpoint — rotating photographic background PASS

Date: 2026-08-30

Physical test on the primary Inspiron-3502 X11 session confirmed the Stage 5C photographic continuation path is working.

Observed results:

- `desktop-c` selected a photographic BODY background.
- Stage 5C normalized the discovered CSS URL correctly.
- `curl` cached the active image successfully.
- GTK painted the cached image behind the real DING desktop icons.
- Reloading `desktop-c` allowed its alternate rotating photograph to appear.
- The left DING icon pane followed the newly selected photograph after reload.
- Existing icon interaction and adaptive geometry remained intact.

Representative successful log:

```text
[GRAYHAIRED-PHOTO5C] raw=("https://grayhaired.tech/desktop-c/images/FL-VA.png") cleaned=https://grayhaired.tech/desktop-c/images/FL-VA.png
[GRAYHAIRED-PHOTO5] cached/applied url=https://grayhaired.tech/desktop-c/images/FL-VA.png bytes=2952046 ... full=1366x768 icon=284
```

Remaining visual mismatch observed during this test: the translucent Zorin taskbar can reveal the underlying GNOME wallpaper rather than the GrayHaired live desktop image. The next experiment should synchronize the real GNOME wallpaper with the active cached photo while preserving a reversible backup of the user's original wallpaper settings.
