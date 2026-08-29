# Adaptive Icon Strip Checkpoint — 2026-08-28

Physical test system: Dell Inspiron 3502, Zorin OS 18.1, GNOME Shell 46.0, Wayland, 1366x768.

## Result

Adaptive Wayland icon-strip sizing is physically verified across three DING icon-size settings.

DING geometry on this Zorin build:

- `elementSpacing = 2`
- `tiny`: desired width 70 -> cell 78 -> GrayHaired strip 164 px
- `standard`: desired width 120 -> cell 128 -> GrayHaired strip 264 px
- `large`: desired width 130 -> cell 138 -> GrayHaired strip 284 px

GrayHaired formula under test:

`strip width = clamp(2 * (Prefs.get_desired_width() + 4 * elementSpacing) + 8, 160, 320)`

Fallback remains 220 px if DING geometry cannot be determined safely.

## Physical observations

For tiny, standard, and large icon sizes:

- icon strip resized to the expected width: PASS
- desktop icons and labels remained usable: PASS
- My Desktop remained visible and usable beside the strip: PASS
- layout looked proportionate at each tested icon size: PASS

## Runtime verification after large-size test

`verify-wayland-known-good.sh` passed all checks:

- shared adaptive defaults present and valid
- WebKit2 4.1 integration present
- adaptive strip uses DING cell geometry
- adaptive EventBox width configured
- adaptive startup logging present
- split-surface allocation guard present
- live WebKit view present
- known-good My Desktop URL present
- external-link handoff present
- keyboard-event guard and WebKit focus test present
- WebKit lifecycle logging present
- experimental forced-focus code absent
- current session Wayland
- GrayHaired extension ACTIVE
- exactly one GrayHaired DING/WebKit child running
- no system Zorin DING child running

Large-size runtime log:

`[GRAYHAIRED-LAYOUT] icon cell=138px columns=2 strip=284px`

## Conclusion

Adaptive strip sizing is now considered physically proven on the Inspiron 3502 for tiny, standard, and large desktop-icon sizes. The implementation is suitable to move from experiment toward permanent installer behavior, while retaining the current rollback copy and 220 px fallback until installer integration is completed and re-verified.
