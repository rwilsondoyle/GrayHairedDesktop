# Live icon-size tracking + manager reflow — all sizes PASS

Date: 2026-08-28
Branch: `codex/research-live-desktop-mode`
Machine: Dell Inspiron 3502, Zorin OS 18.1, GNOME 46 Wayland

## Physical result

The live icon-size tracking experiment with manager-level DING reflow has now been physically tested at every Zorin desktop icon size:

- Tiny
- Small
- Standard
- Large

After installing the live manager reflow experiment and performing one GrayHaired child-only reload to activate it, the user changed icon sizes repeatedly with **no further reloads, logout, or reboot**.

Observed result: **all four sizes worked perfectly**.

## What is now proven

- The GrayHaired fixed icon boundary follows Zorin's `icon-size` setting live.
- The reserved width adapts automatically to the selected size.
- The fixed two-column boundary remains stable and does not grow from DING natural-width requests.
- DING's own internal geometry is updated before its normal reflow sequence.
- The manager-controlled sequence remains authoritative:
  - remove items from grid
  - resize grid
  - update icons
  - place all files on grids
- Large icons no longer leave an icon underneath the My Desktop/WebKit surface.
- No user-visible reload is required between size changes.

Known target widths remain:

- Tiny: 164 px
- Small: 204 px
- Standard: 264 px
- Large: 284 px

## Promotion status

The combined behavior is now physically proven on the primary Wayland development machine and is ready to be promoted into the permanent Wayland installer and verifier.

Promotion should preserve:

- adaptive two-column calculation
- fixed boundary wrapper
- live icon-size tracking
- manager-level geometry/reflow integration
- existing focus safety rules
- child-only reload policy for installed app code during development

No forced focus/grab behavior should be introduced.
