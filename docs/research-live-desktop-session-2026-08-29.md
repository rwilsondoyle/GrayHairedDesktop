# GrayHaired Live Desktop — finalized research checkpoint

## Official status

Branch: `codex/research-live-desktop-mode`

Physical testing on Zorin OS 18.1 / GNOME 46 has reached the point where the live-desktop implementation is considered ready for promotion out of research. The normal installer and verifier now reproduce the working Stage 11 + Stage 15 + Stage 16 configuration.

### Confirmed working

- Same GrayHaired user-local DING/WebKit extension works on GNOME X11 and Wayland.
- Exactly one GrayHaired DING/WebKit child runs while GrayHaired is active; stock Zorin DING remains disabled.
- Real desktop icons/files/folders remain usable in the left icon pane.
- The live webpage remains clickable and interactive on the right.
- Normal applications can appear above the desktop surface.
- Compressed icon-pane widths are physically accepted: Tiny/Small 240 px, Standard 264 px, Large 284 px.
- Stage 15 adaptive vertical scrolling is physically verified on Tiny, Small, Standard, and Large.
- Stage 15 counts regular desktop items plus special Home/Trash items and grows only the internal DING canvas when overflow exists.
- The normal GTK vertical scrollbar appears only when needed.
- Right-click `Arrange Icons` continues to work and is the preferred native fix for occasional preserved-coordinate gaps; no custom icon-packing code is needed.
- Automatic Blend solid-page sampling works.
- Stage 9 synchronizes the GNOME backing color for no-photo pages so translucent taskbar areas do not reveal stale photographic wallpaper.
- `msn.com` visually passes with sampled `rgb(36, 36, 36)` / `#242424`; MSN link behavior remains inconsistent and is not considered fully solved.
- DuckDuckGo visually and functionally passes: searches/navigation stay embedded and external search results open in the default browser.
- Photographic continuation works on `desktop-c`, including rotating photos.
- Stage 7 keeps the visible photo aligned through live icon-size changes without reload.
- Stage 16 extends the photographic background through the taller Stage 15 scroll canvas; physical testing judged the repeated vertical continuation acceptable.
- Switching from a photo page to a solid page correctly returns to solid-color behavior; Stage 16 does not interfere with no-photo pages.
- Safe WebKit keyboard handling remains in place; forced EventBox focus/grab_focus experiments remain absent.

## Promoted Automatic Blend chain

The supported installation chain is:

1. edge sampler
2. sampled-color solid blend
3. page photo discovery/continuation
4. local photo cache support
5. curl cache path
5C. URL cleanup
6. GNOME wallpaper photo sync
7. live photo geometry reflow
9. solid/no-photo GNOME backing-color sync
11. compressed live icon-pane widths
15. adaptive vertical DING scroll canvas
16. photographic continuation through the Stage 15 scroll canvas

`patch-live-desktop-automatic-blend-promoted.sh` installs this chain. `verify-live-desktop-known-good.sh` requires the Stage 11, Stage 15, and Stage 16 markers and the corresponding implementation details.

## Failed / retired experiments

The following experiments are intentionally excluded from known-good and should not be reintroduced without a new design and physical testing:

- Stage 8 broad arbitrary-link handoff: worsened modern-site link behavior.
- Stage 10 fixed scroll pane: broke layout and could kill the child process.
- Stage 12 Large row-density change: gained too little and was superseded.
- Stage 13 custom overflow drawer/helper approaches: functional in parts, but intrusive or unstable; native scrolling is preferred.
- Stage 13E DING overlay: hard failure/blank desktop.
- Stage 14 scrollbar-only change: no usable overflow because the DING canvas did not grow.
- Forced EventBox focus / `grab_focus()`: caused a hard lock and must remain absent.

## Remaining known issue

### Arbitrary modern-site link handling

`msn.com` still exposes unreliable JavaScript/card navigation: some links open the default browser while others appear to click without a useful result. Stage 8 is not the answer and remains retired.

Future work should examine WebKit new-window/create-policy and JavaScript-driven navigation paths without disturbing the proven GrayHaired pages or DuckDuckGo behavior.

## Future user-facing feature

Add manual background-color customization:

- friendly color dropdown
- optional custom hex entry such as `#41464C`
- immediate preview
- clear precedence between Manual Background and Automatic Blend, with manual mode overriding Automatic Blend when selected

## Operational notes

- Never edit `/usr/share/gnome-shell/extensions/...`; GrayHaired uses the user-local extension tree.
- Site HTML/CSS/JS changes: use page Reload.
- GrayHaired child app-code changes: `bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh`.
- `extension.js` changes: logout/login is the normal safe reload path.
- No reboot is required for the known workflows.
- Original GNOME wallpaper backup remains at `~/.config/grayhaired-live-desktop-wallpaper-backup.txt` and should not be overwritten by GrayHaired-generated state.

## Promotion decision

Stage 15 adaptive icon scrolling and Stage 16 photographic scroll-canvas continuation have both passed physical testing and are promoted into the regular installer/verifier. This checkpoint is suitable for merge to `main` as the official live-desktop implementation, while arbitrary MSN-style link handling remains documented as follow-up work rather than a release blocker.
