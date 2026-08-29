# Checkpoint: live icon-size change with fixed two-column boundary

Date: 2026-08-28
Branch: `codex/research-live-desktop-mode`

## Physical finding

The fixed two-column boundary experiment passes when started in Tiny mode, but changing the Zorin/DING icon-size setting live does not currently resize the reserved strip.

Reason: the adaptive strip width is calculated once when the GrayHaired DING/WebKit child starts. The fixed boundary then holds that startup width as intended. Changing the DING icon size at runtime changes the icons, but does not recalculate the GrayHaired strip width.

Observed consequence: when the child was started in Tiny mode (164px strip) and the user switched to Large without restarting the child, the strip remained 164px and some large icons were clipped/not visible.

## Current test procedure

For the present experiment only, after changing Zorin icon size, run:

```bash
bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
```

This restarts only the GrayHaired DING/WebKit child. No reboot or GNOME logout is required.

Expected startup widths remain:

- Tiny: 164px
- Small: 204px
- Standard: 264px
- Large: 284px

Then test click, right-click, drag in both columns, and confirm My Desktop does not change width.

## Final product requirement

The finished implementation should react automatically to the Zorin/DING icon-size setting changing. The user should not need to know about or run `reload-grayhaired.sh`.

Preferred design:

1. Listen for the `icon-size` GSettings change in the GrayHaired child.
2. Recompute width using the same DING formula already proven:
   `Prefs.get_desired_width() + 4 * elementSpacing`, two columns plus configured padding/clamps.
3. Apply the new fixed boundary atomically so the icon pane and WebKit divide the monitor at the new width.
4. Preserve existing DING EventBox, focus, click, context-menu, and drag behavior.
5. Do not restart GNOME Shell, toggle the extension, or reboot for a normal icon-size preference change.
6. Verify no transient expansion beyond the computed two-column boundary after the resize.

This live-update behavior must be included in the final installer/verifier/help design.
