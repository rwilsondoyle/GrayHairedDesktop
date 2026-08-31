# Fixed Two-Column Boundary — All Icon Sizes Physically Passed

Date: 2026-08-28
Branch: `codex/research-live-desktop-mode`
Machine: Dell Inspiron 3502, Zorin OS 18.1, GNOME 46 Wayland

## Result

The reversible fixed two-column boundary experiment has now been physically tested at every Zorin desktop icon size:

- Tiny
- Small
- Standard
- Large

For each size, the user changed the Zorin desktop icon size and then ran:

```bash
bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh
```

After the GrayHaired child-only reload, the reserved two-column area adapted correctly to the selected icon size and remained stable while the desktop was used.

## Confirmed behavior

- The icon area provides two full columns.
- The icon area no longer grows when an icon is dragged toward the right edge.
- My Desktop no longer horizontally wiggles/shrinks due to DING natural-width requests.
- Icon interaction remains usable across tested sizes.
- Adaptive width calculation itself remains correct after the GrayHaired child restarts.

Known target widths from earlier measurements:

- Tiny: 164 px
- Small: 204 px
- Standard: 264 px
- Large: 284 px

## Remaining issue

The current implementation calculates the adaptive strip width only when the GrayHaired DING/WebKit child starts. Therefore, changing the Zorin icon-size setting live does not yet resize the fixed boundary automatically.

Final product requirement: watch the Zorin desktop-icons `icon-size` GSettings value and recalculate/apply the fixed two-column boundary automatically, without requiring a user-visible reload, logout, or reboot.

## Promotion decision

The fixed two-column geometry is now physically proven across all practical icon sizes on the primary development machine. It is ready to be promoted into the permanent Wayland implementation once automatic live icon-size tracking is added and verified.
