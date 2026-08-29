# Checkpoint: Wayland geometry promotion final physical PASS

Date: 2026-08-29
Branch: `codex/research-live-desktop-mode`

The promoted Wayland installer and verifier had already completed a clean reinstall and full runtime verification successfully.

Final post-reinstall physical test also passed:

- Tiny -> Large -> Standard icon-size changes worked without manual child reloads between changes.
- The icon strip resized automatically at each size.
- All desktop icons remained visible.
- The icon area remained a stable two-column layout.
- Moving/using icons did not cause the My Desktop/WebKit boundary to wiggle.

Conclusion: Wayland live geometry, fixed two-column boundary, automatic icon-size tracking, manager-synchronized DING reflow, clean reinstall path, and verifier are physically confirmed on the primary Inspiron-3502 test machine.

This closes the Wayland geometry/install promotion milestone. Next planned work is to bring X11 to the same adaptive fixed two-column behavior, then continue toward the unified installer and later Automatic Blend work.
