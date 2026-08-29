# Adaptive Wayland installer checkpoint — 2026-08-28

Physical test machine: Dell Inspiron 3502, Zorin OS 18.1, GNOME Shell 46, Wayland, 1366x768.

## Result

The adaptive icon-strip behavior has been promoted from a separate experiment into the normal Wayland installer path and then physically verified with a clean reinstall.

Clean reinstall sequence:

- stock Zorin Desktop Icons disabled before rebuild
- no stock or GrayHaired DING child running before installer replacement step
- system Zorin/DING structural compatibility preflight: PASS
- user-local GrayHaired extension rebuilt from the untouched system Zorin extension
- adaptive icon-strip patch applied automatically by `install-wayland-separate-ding-prototype.sh`
- WebKit external-link handoff applied
- safe WebKit keyboard-focus guard applied
- WebKit lifecycle logging applied
- file-only verifier: PASS
- GrayHaired extension enabled after rebuild
- full runtime verifier: PASS

## Adaptive layout values

Current defaults:

- DING columns: 2
- strip padding: 8 px
- minimum strip width: 160 px
- maximum strip width: 320 px
- fallback strip width: 220 px

DING geometry on this Zorin build:

- tiny cell: 78 px -> strip 164 px
- standard cell: 128 px -> strip 264 px
- large cell: 138 px -> strip 284 px

All three sizes were physically tested earlier on the same 3502 and passed visual/runtime checks.

## Clean reinstall proof

The clean reinstall was performed while the user's icon-size setting was `large`.

Freshly installed GrayHaired runtime logged:

`[GRAYHAIRED-LAYOUT] icon cell=138px columns=2 strip=284px`

This proves the installer itself now creates the adaptive behavior; no separate manual `patch-wayland-adaptive-icon-strip.sh` step is required after installation.

Final extension/runtime state after the clean reinstall:

- `grayhaired-live-desktop@grayhaired.tech`: Enabled Yes, State ACTIVE
- `zorin-desktop-icons@zorinos.com`: Enabled No, State INACTIVE
- exactly one GrayHaired DING/WebKit child running
- no system Zorin DING child running
- full `verify-wayland-known-good.sh`: PASS

## Important installation lesson

A prior clean-reinstall attempt stopped safely because stock Zorin Desktop Icons had become active again and its DING child was running. The installer correctly refused to replace the GrayHaired user-local tree while a conflicting desktop-icon owner was active.

For deliberate reinstall testing, disable stock Zorin Desktop Icons first and confirm that neither stock nor GrayHaired DING is running before invoking the installer.

## Next work

1. Treat adaptive sizing as the normal Wayland behavior and remove transitional fixed-width assumptions where safe.
2. Re-check recovery/removal scripts against the adaptive installer path.
3. Perform persistence checks (logout/login and normal reboot) with the adaptive installer-generated build.
4. Once Wayland is stable, return to the already-proven X11 live-desktop/icon-zone approach and consider carrying adaptive width behavior there as well.
