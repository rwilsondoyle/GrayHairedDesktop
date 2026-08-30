# GrayHaired Live Desktop research checkpoint — 2026-08-29

## Status at end of session

Branch: `codex/research-live-desktop-mode`

The live desktop implementation is in a strong research checkpoint on both GNOME X11 and Wayland.

### Confirmed working

- Clean Wayland install completes from both extensions stopped/INITIALIZED.
- Exactly one GrayHaired DING/WebKit child runs after enabling GrayHaired.
- Stock Zorin DING child is absent while GrayHaired is active.
- Default live page remains `https://grayhaired.tech/desktop-d`.
- Real DING desktop icons remain usable on the left side.
- WebKit live page remains clickable on the right side.
- Adaptive icon strip preserves two DING columns.
- Live icon-size reflow works without reload for:
  - Tiny: 164 px
  - Small: 204 px
  - Standard: 264 px
  - Large: 284 px
- Automatic Blend solid-page sampling works.
- Stage 9 synchronizes the GNOME backing color for no-photo pages so translucent taskbar areas do not reveal stale photographic wallpaper.
- `msn.com` visual fallback test sampled `rgb(36, 36, 36)` / `#242424` with confidence 1.0 and looked visually correct after Stage 9.
- Photographic continuation works on `desktop-c`.
- Cached active photo is painted behind the DING icon area.
- GNOME wallpaper synchronization keeps translucent shell/taskbar areas aligned with the page photo.
- Rotating `desktop-c` photos are followed.
- Stage 7 live photographic reflow keeps the photo aligned while changing Tiny/Small/Standard/Large icon sizes without reload.
- Wayland visual test of `desktop-c` showed no visible seam or right-edge black strip.
- Safe WebKit keyboard guard remains in place; forced EventBox focus/grab_focus experiments remain absent.

## Promoted Automatic Blend chain

Supported promoted chain currently includes:

1. edge sampler
2. sampled-color solid blend
3. page-level photo discovery/continuation
4. local photo cache support
5. curl cache path
5C. URL cleanup
6. GNOME wallpaper photo sync
7. live photo geometry reflow
9. solid/no-photo GNOME backing-color sync

The verifier explicitly requires these promoted markers and explicitly requires failed Stage 8 to be absent.

## Failed / unresolved experiment

### Arbitrary modern-site link handling

`msn.com` exposed unreliable link behavior. Some cards/links open the normal browser while others appear clicked but do nothing useful.

Stage 8 attempted a broader arbitrary-site WebKit navigation handoff. Physical testing felt worse, with fewer links working, so Stage 8 was rolled back and must remain excluded from the supported chain.

Future requirement: arbitrary modern websites should preserve the embedded live desktop document while reliably opening intended clicked destinations in the user's normal browser. Investigate WebKit navigation/new-window/JavaScript-driven click paths without destabilizing the proven GrayHaired pages.

## Future user-facing feature requested

Add background-color customization so users are not forced to use the current gray choice. Desired UI concept:

- friendly dropdown of common background colors
- optional custom color-code entry, especially hex values such as `#41464C`
- immediate preview before saving
- Automatic Blend/manual-background behavior should be clearly defined so a user's manual choice is respected when manual mode is selected

This is a future step, not part of the current stabilization work.

## Operational notes

- Do not edit `/usr/share/gnome-shell/extensions/...`; GrayHaired uses the user-local copy.
- Do not use forced `Gtk.EventBox.grab_focus()` or forced EventBox focus; that earlier experiment caused a hard lock.
- Site HTML/CSS/JS changes: use page Reload.
- Child app-code changes: `bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh`.
- `extension.js` changes: prefer logout/login.
- Clean reinstall requires both stock and GrayHaired DING child processes truly stopped first. On Wayland, disabling the stock Zorin extension can leave its DING child alive; logout/login successfully clears it.
- No reboot is required for the known workflows.
- Original GNOME wallpaper backup remains at `~/.config/grayhaired-live-desktop-wallpaper-backup.txt` and should not be overwritten by GrayHaired-generated photo state.

## Suggested next session order

1. Return temporary test URL from `desktop-c` to `desktop-d` if desired before continuing.
2. Confirm Stage 9 solid backing-color return on Wayland after switching from photo mode to `desktop-d`.
3. Optionally repeat the MSN visual fallback on Wayland.
4. Research a better arbitrary-site link strategy; keep Stage 8 out unless a replacement is physically proven.
5. Once both-session behavior is considered stable enough, prepare the research branch for a logical PR/merge checkpoint.
6. Later add the user-selectable background color feature.
