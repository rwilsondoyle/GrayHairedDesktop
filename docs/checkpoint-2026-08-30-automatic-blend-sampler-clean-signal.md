# Checkpoint: Automatic Blend sampler clean signal

Date: 2026-08-30
Branch: `codex/research-live-desktop-mode`

Physical test on the primary Inspiron 3502 under GNOME X11 produced a completely consistent Stage 1 Automatic Blend sample from the live My Desktop WebKit surface.

Observed sample:

- URI: `https://grayhaired.tech/desktop-d/`
- WebKit viewport: 1202 x 768
- dominant color: `rgb(65, 70, 76)`
- dominant count: 35
- total sample count: 35
- all 35 edge probes returned the same color

This is a clean signal and is suitable for the first reversible visual blend experiment.

Next experiment: apply only the sampled background color to the DING icon pane. Do not alter geometry, focus, pointer handling, WebKit content, or the permanent installer until physical appearance and interaction are verified.
