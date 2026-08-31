# Stage 22B Screen Color Picker — Physical Verification Pass

Date: 2026-08-31
Test machine: Dell Inspiron 3502
Desktop/session: Zorin OS, GNOME Wayland
Branch: `codex/stage22b-screen-color-picker`

## Result

Stage 22B passed physical testing on the Inspiron 3502.

The user opened **My Desktop Settings**, opened **Desktop Background**, selected **Manual Background**, and used **Pick Color From Screen...** to sample a tan area from the live beach wallpaper.

The picker returned `#BA9973` and the preview changed to the same sampled color before application.

After **Apply Background**:

- the live desktop icon area changed from the prior dark gray to `#BA9973`;
- the webpage/wallpaper area remained unchanged;
- desktop icons and labels remained correctly positioned and readable;
- the bottom panel remained intact;
- the selected manual background survived a warm reboot and subsequent login.

This verifies the complete Stage 22B path: screen sampling, preview, apply, persistence, and restoration after login.

## Application-menu consolidation

During the same physical review, the application menu showed three related entries:

- My Desktop Website
- My Desktop Background
- My Desktop Settings

The settings hub already provides access to both Website and Background controls. To keep the interface simpler, Stage 22 is consolidated so only **My Desktop Settings** is installed as the normal application-menu entry. The official installer also removes the two older stand-alone `.desktop` launchers if they are already present.

The underlying Website and Background settings tools remain available to the settings hub; only their duplicate application-menu entries are removed.

## Status

**PHYSICAL PASS — ready for promotion.**
