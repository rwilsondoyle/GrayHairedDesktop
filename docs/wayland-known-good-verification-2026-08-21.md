# Wayland Known-Good Verification — 2026-08-21

Physical verification was run on the Dell Inspiron 3147 Wayland test system after the cleanup/reproducibility pass.

Command:

```bash
cd ~/GrayHairedDesktop
git pull --ff-only origin codex/research-live-desktop-mode
bash scripts/verify-wayland-known-good.sh
```

Result: **PASS**.

The verifier confirmed all of the following on the installed user-local runtime:

- GrayHaired extension files exist.
- WebKit2 4.1 integration is present.
- The 220-pixel DING icon strip is configured.
- The split-surface GTK allocation guard is present.
- The live WebKit view is created.
- The known-good My Desktop URL is configured.
- External-link browser handoff is present.
- The WebKit/DING keyboard-event guard is present.
- The WebKit focus test is present.
- WebKit lifecycle creation/destruction logging is present.
- The experimental DING focus-reclaim marker is absent.
- `Gtk.EventBox.grab_focus()` is absent.
- Forced `Gtk.EventBox` focus is absent.
- The current session is Wayland.
- `grayhaired-live-desktop@grayhaired.tech` is ACTIVE.
- Exactly one GrayHaired DING/WebKit child process is running.
- The system Zorin DING child is not running.

This verifies that the installed Wayland runtime matches the current known-good architecture after rollback of the unsafe focus-reclaim experiment.

No extension reload, logout, or reboot was required for this verification.
