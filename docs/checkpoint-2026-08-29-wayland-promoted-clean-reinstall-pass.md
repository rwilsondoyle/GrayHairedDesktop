# Wayland promoted clean reinstall — PASS

Date: 2026-08-29
Branch: `codex/research-live-desktop-mode`
Machine: Dell Inspiron 3502, Zorin OS 18.1, GNOME 46 Wayland

## Result

The promoted permanent Wayland installer path was cleanly reinstalled after disabling both the GrayHaired extension and stock Zorin Desktop Icons extension.

The installer completed successfully and its file-only verifier passed all promoted geometry and WebKit checks, including:

- adaptive DING-derived two-column sizing
- fixed two-column GTK boundary
- live icon-size tracking
- manager-synchronized live-size reflow
- preservation of DING's native remove / resizeGrid / updateIcon / re-place sequence
- WebKit external-link handoff
- WebKit keyboard-focus guard
- WebKit lifecycle logging
- absence of unsafe EventBox focus-reclaim code

After enabling `grayhaired-live-desktop@grayhaired.tech`, the full runtime verifier also passed:

- current session is Wayland
- GrayHaired extension is ACTIVE
- exactly one GrayHaired DING/WebKit child is running
- stock Zorin DING child is not running
- known-good Wayland runtime verification complete

This confirms the previously tested research patch stack is now reproducible through the promoted installer and verifier rather than depending on manual patch accumulation.

## Next physical check

Perform one final post-reinstall live geometry check without reloads:

1. Tiny
2. Large
3. Standard

Confirm the reserved icon area resizes automatically, stays at two columns, keeps all icons visible, and does not make My Desktop wiggle during icon movement.
