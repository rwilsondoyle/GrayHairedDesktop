# GrayHaired Live Desktop — arbitrary-site MSN visual PASS

Date: 2026-08-29
Session: GNOME X11

Physical test target: `https://www.msn.com/`

Observed results:

- WebKit successfully rendered MSN as the live desktop page.
- Automatic Blend sampled MSN's left edge as `rgb(36, 36, 36)` with confidence `1.000` (35/35 samples).
- The photographic path correctly reported no BODY background photo and did not activate.
- Stage 9 synchronized the real GNOME background to `#242424`, eliminating stale photographic wallpaper beneath the translucent Zorin taskbar.
- Real DING desktop icons remained functional in the fixed adaptive left strip.

Navigation finding:

- The existing proven browser handoff works inconsistently on complex JavaScript-heavy sites such as MSN.
- Experimental Stage 8 broader navigation handoff made physical behavior feel worse and was rolled back.
- Stage 8 is intentionally excluded from the promoted installer/verifier until a better arbitrary-site navigation design is developed.

This checkpoint establishes the visual fallback behavior for complex arbitrary sites: sampled solid-color icon pane plus matching GNOME background beneath translucent shell surfaces, with photographic continuation reserved for genuine BODY background images.
