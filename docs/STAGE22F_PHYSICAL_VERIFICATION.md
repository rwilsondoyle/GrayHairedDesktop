# Stage 22F Physical Verification

Date: 2026-08-31
System: Dell Inspiron 3502
Desktop: Zorin OS / GNOME Wayland

Result: PASS

Stage 22F verified installer cleanup of the two obsolete stand-alone application-menu launchers:

- `grayhaired-live-desktop-website.desktop`
- `grayhaired-live-desktop-background.desktop`

The test deliberately recreated both old launchers under `~/.local/share/applications`, then ran `scripts/install-gnome-live-desktop.sh` while the GrayHaired Live Desktop DING process was already running.

The initial implementation failed because the installer exited at the running-process reinstall guard before reaching the menu-cleanup section. The fix moves the obsolete-launcher removal before that guard.

Physical retest result:

- AFTER INSTALL showed only `My Desktop Settings`.
- Old Website launcher: removed.
- Old Background launcher: removed.
- Both explicit file checks reported PASS.

This confirms the consolidated Stage 22 application-menu cleanup now occurs even when a full reinstall cannot continue because the live DING process is running.
