# GrayHairedDesktop design consolidation — 2026-08-28

This note consolidates the current product and engineering direction after the latest physical Wayland testing on the Dell Inspiron 3502.

## Product goal

My Desktop should feel like the desktop itself rather than a normal application window. The user may choose an arbitrary web page (GrayHaired pages, Google, MSN, weather sites, personal sites, etc.) as the live desktop surface. Real desktop icons must remain usable beside it.

## Wayland split-surface architecture

- Keep a dedicated DING icon area on the left.
- Keep the live WebKit page on the remainder of the monitor.
- Preserve a single GrayHaired user-local DING/WebKit child.
- Keep stock Zorin Desktop Icons disabled while GrayHaired is active.
- Never modify the system Zorin extension under `/usr/share`.
- Keep My Desktop links, Folders menus, text inputs, external-link handoff, and WebKit lifecycle behavior intact.

## Two-column rule

The icon area should reserve exactly two complete DING columns at every supported icon size. The boundary between the icon area and My Desktop should remain fixed while icons are moved around inside the icon area.

Current DING geometry on Zorin 18.1:

- `elementSpacing = 2`
- tiny desired width = 70 px
- small desired width = 90 px
- standard desired width = 120 px
- large desired width = 130 px
- DING column footprint = desired width + `4 * elementSpacing`

Current two-column widths with 8 px strip padding:

- Tiny: 164 px
- Small: 204 px
- Standard: 264 px
- Large: 284 px

These widths were derived from DING's own geometry rather than guessed values.

## Adaptive sizing status

Adaptive sizing is now part of the normal Wayland installer.

Physical testing on the Inspiron 3502 confirmed:

- Tiny -> 164 px
- Standard -> 264 px
- Large -> 284 px
- logout/login persistence: PASS
- two normal restarts: PASS
- changing icon sizes after restart: PASS
- full runtime verifier: PASS

## Confirmed GTK width-growth behavior

A diagnostic logger measured actual split allocations when moving Tiny icons farther right.

Baseline:

- icon area = 164 px
- WebKit = 1202 px
- layout = 1366 px

Observed during/right after drag:

- icon area grew to 189 px while WebKit shrank to 1177 px
- icon area later returned to 164 px / WebKit 1202 px
- another movement produced icon 169 px / WebKit 1197 px

Conclusion: `set_size_request()` is acting as a requested/minimum size, and GTK can allow the DING side to grow when child/container natural-size demands increase. The adaptive formula itself is not changing during the drag.

### Desired product behavior

Do not let icon placement resize My Desktop. The two-column area should be a real reserved region with a stable boundary. Users should be free to populate both columns without causing WebKit to move.

### Next layout experiment

Test a hard/fixed two-column boundary while preserving:

- icon left click
- icon right-click context menu
- drag/drop within both columns
- saved icon positions
- text labels without unacceptable clipping
- My Desktop input and links
- full verifier PASS

Do not promote a hard-cap implementation until the physical icon interaction test passes.

## Automatic Blend feature

A fixed wallpaper behind the icon area can look visually disconnected from an arbitrary chosen My Desktop page. The product should offer an **Automatic Blend** appearance mode.

### Automatic Blend concept

When the chosen WebKit page finishes loading or is deliberately reloaded/changed:

1. Inspect/sample a narrow region along the left edge of the rendered page locally.
2. Derive a dominant/background color or small palette.
3. Style the two-column icon panel using a matching color, subtle gradient, or blurred/soft approximation.
4. Add a gentle transition/fade at the seam between the icon panel and WebKit so they read as one desktop surface.
5. Choose readable light/dark icon-label contrast based on the generated panel background.
6. Update only at controlled events (page load, page change, explicit reload), not continuously.

This should be local and deterministic; no external AI service is required. It may look "AI matched" to the user, but local sampling is preferable for speed, privacy, predictability, and offline robustness.

### Automatic Blend fallback

Some pages may be visually chaotic, animated, video-heavy, ad-heavy, transparent, or otherwise unsuitable for a stable sampled palette. In those cases, use a neutral fallback panel rather than producing a distracting result.

Suggested user appearance modes:

- Automatic Blend (recommended/default)
- Dark Panel
- Wallpaper

Automatic Blend changes appearance only. It must not change icon-zone geometry.

## Arbitrary-page requirement

Do not assume the selected desktop is a GrayHaired page. The user may choose Google, MSN, a weather site, a personal dashboard, or almost any other URL. Any appearance solution must therefore be page-agnostic.

## Safe reload hierarchy

- Website HTML/CSS/JS only -> use page Reload inside My Desktop.
- GrayHaired child-side `app/` code -> `bash ~/GrayHairedDesktop/scripts/reload-grayhaired.sh`.
- `extension.js` changes -> normal logout/login.
- Whole extension disable/enable -> installation, deliberate recovery, or controlled testing only.
- Reboot is not a routine development reload mechanism.

## Installer/recovery invariants

- Run the Zorin base-compatibility preflight before installation/reinstallation.
- Installer builds from the untouched system Zorin source into the user-local UUID.
- Adaptive sizing is installed automatically.
- Stock Zorin DING and GrayHaired DING must never run simultaneously.
- Verifier must confirm exactly one GrayHaired child and no stock Zorin child.
- Recovery remains explicit and guarded; do not modify `/usr/share`.

## Final help/instructions requirements

The eventual end-user help should explain in plain language:

- My Desktop reserves two desktop-icon columns.
- The width automatically follows the user's desktop icon size.
- Moving icons inside the two columns should not resize My Desktop.
- Icon size choices tested: Tiny, Small, Standard, Large.
- Automatic Blend can visually match the icon panel to almost any chosen page.
- Dark Panel and Wallpaper should be available as simpler alternatives.
- Normal logout/login and reboot should preserve the setup.
- How to change the chosen My Desktop URL.
- How to recover the stock Zorin desktop safely.
- Basic troubleshooting for missing My Desktop, missing icons, or conflicting desktop-icon processes.

## X11 follow-up

Wayland is currently the active finishing track. Once the two-column fixed-boundary behavior and Automatic Blend direction are stable, return to the already-proven X11 icon-zone approach and make its geometry/appearance consistent with the Wayland product behavior where practical.

## Current next steps

1. Implement and physically test the fixed two-column boundary on Wayland.
2. Preserve the allocation logger long enough to prove WebKit no longer moves during icon drags.
3. Add verifier coverage for the fixed-boundary implementation.
4. Prototype Automatic Blend without changing geometry.
5. Test Automatic Blend against at least:
   - a dark GrayHaired page
   - a light page such as Google
   - a busy portal-style page such as MSN
   - a page where fallback is necessary
6. Only after the above, continue packaging/unified installer and X11 parity work.
