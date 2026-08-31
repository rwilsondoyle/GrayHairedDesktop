# GrayHaired Live Desktop — finalized research checkpoint

## Official status

The original live-desktop research branch was promoted to `main` in PR #60. Follow-up work on `codex/manual-background-color` has now physically verified three additional production features for promotion: Stage 17 Manual Background, Stage 18 compact 204 px icon-pane geometry, and Stage 19 local-file drop protection.

### Confirmed working

- Same GrayHaired user-local DING/WebKit extension works on GNOME X11 and Wayland.
- Exactly one GrayHaired DING/WebKit child runs while GrayHaired is active; stock Zorin DING remains disabled.
- Real desktop icons/files/folders remain usable in the left icon pane.
- The live webpage remains clickable and interactive on the right.
- Normal applications can appear above the desktop surface.
- Stage 15 adaptive vertical scrolling is physically verified on Tiny, Small, Standard, and Large.
- Stage 15 counts regular desktop items plus special Home/Trash items and grows only the internal DING canvas when overflow exists.
- The normal GTK vertical scrollbar appears only when needed.
- Right-click `Arrange Icons` continues to work and is the preferred native fix for occasional preserved-coordinate gaps; no custom icon-packing code is needed.
- Automatic Blend solid-page sampling works.
- Stage 9 synchronizes the GNOME backing color for no-photo pages so translucent taskbar areas do not reveal stale photographic wallpaper.
- Photographic continuation works on `desktop-c`, including rotating photos.
- Stage 7 keeps the visible photo aligned through live icon-size changes without reload.
- Stage 16 extends the photographic background through the taller Stage 15 scroll canvas.
- Stage 17 Manual Background is physically verified. Manual color overrides Automatic Blend, including photographic pages, and switching back to Automatic restores the normal behavior.
- The GTK 4 `My Desktop Background` settings window is physically verified with five simple presets, a direct `Choose Color…` picker, live preview, Apply, and Automatic mode.
- A normal Zorin application-menu entry named `My Desktop Background` provides user access without terminal commands.
- Stage 18 changes the Stage-11 minimum icon-pane width from 240 px to 204 px. Physical testing confirmed Tiny, Small, Standard, and Large all look correct; Tiny no longer expands to an unintended three-column grid.
- Stage 19 rejects `file://` WebKit navigation. Physical testing confirmed that repeatedly dropping a local `.txt` file onto the webpage side no longer replaces the configured desktop website.
- Safe WebKit keyboard handling remains in place; forced EventBox focus/grab_focus experiments remain absent.

## Promoted installation chain

The supported installation path now consists of:

1. base GrayHaired DING/WebKit live desktop
2. Automatic Blend appearance chain
3. Stage 15 adaptive vertical DING scroll canvas
4. Stage 16 photographic continuation through the scroll canvas (installed by the promoted appearance chain)
5. Stage 17 Manual Background override and GTK 4 settings UI
6. Stage 18 compact 204 px minimum icon-pane width
7. Stage 19 local-file WebKit navigation/drop protection
8. Zorin application-menu launcher for `My Desktop Background`

`install-gnome-live-desktop.sh` installs the supported combination. `verify-live-desktop-known-good.sh` requires the corresponding Stage 15, 16, 17, 18, and 19 markers and implementation details.

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

DuckDuckGo remains a strong compatibility example: searches/navigation stay embedded and external results open in the default browser.

## Operational notes

- Never edit `/usr/share/gnome-shell/extensions/...`; GrayHaired uses the user-local extension tree.
- Site HTML/CSS/JS changes: use page Reload.
- GrayHaired child app-code changes: `bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh`.
- `extension.js` changes: logout/login is the normal safe reload path.
- No reboot is required for the known workflows.
- Original GNOME wallpaper backup remains at `~/.config/grayhaired-live-desktop-wallpaper-backup.txt` and should not be overwritten by GrayHaired-generated state.

## Promotion decision

Stage 17 Manual Background, Stage 18 compact 204 px icon geometry, and Stage 19 local-file drop protection have all passed physical testing on the Dell Inspiron 3502 running Zorin OS 18.1 / GNOME Shell 46 Wayland. They are approved for the regular installer/verifier and for promotion to `main` while the unrelated MSN-style modern-site navigation limitation remains documented as follow-up work rather than a release blocker.
