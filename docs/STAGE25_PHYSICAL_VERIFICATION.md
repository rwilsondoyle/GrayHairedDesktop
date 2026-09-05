# Stage 25 Physical Verification

Date: 2026-09-04
Hardware: Dell Inspiron-3502
Desktop: Zorin OS / GNOME
Repository state tested: `main` at Stage 24 reconciliation commit `e287970`

## Goal

Stage 25 verified that the promoted GrayHaired GNOME Live Desktop can be reproduced cleanly from current `main` on Wayland and then used under an X11 session without code changes.

## Stage 25A — Wayland clean-install verification

The local repository was first synchronized to `main` and cleaned so `git status --short` was empty. The active session reported `wayland`.

The first installer attempt was intentionally stopped by the installer's safety guard because the normal Zorin Desktop Icons DING process was still running. This confirmed the guard was working as designed.

Both desktop-icon extensions were then disabled, both DING processes were confirmed stopped, and the promoted installer was run again from `main`:

```bash
bash scripts/install-gnome-live-desktop.sh
```

The installer completed with exit code 0 and reported the promoted feature chain installed, including Zorin zoom compatibility, Automatic Blend, Manual Background, Stage 15 scrolling, Issue #76 desktop-file reflow, Stage 18 compact geometry, Stage 19 local-file protection, Stage 20 browser handoff, Stage 21 persistent website selection, Stage 22 settings, and Stage 23 website reliability.

After enabling only GrayHaired Live Desktop:

- GrayHaired Live Desktop was `ACTIVE`.
- Exactly one GrayHaired DING/WebKit process was running.
- Normal Zorin Desktop Icons was `INACTIVE`.
- The expected split surface appeared: narrow icon pane on the left and live website surface on the right.

The full verifier completed with no `FAIL` lines and ended with the promoted-live-desktop PASS.

Physical Wayland checks all passed:

- `My Desktop Settings` opened normally.
- Temporary website `https://httpbin.org/status/404` produced the friendly Stage 23 error page.
- One Tab moved focus to `Try Again`.
- Enter activated retry and displayed visible `Trying Again…` feedback.
- The website was restored to `https://grayhaired.tech/desktop-c`.
- A normal website link handed off to the default browser.
- A temporary desktop launcher created at Large icon size appeared automatically.
- Deleting the temporary launcher removed it automatically, confirming the Issue #76 reflow fix after a clean install.

## Stage 25B — X11 compatibility verification

The machine was logged out and restarted in an X11 session. `XDG_SESSION_TYPE` reported `x11`.

On initial X11 login, both GrayHaired Live Desktop and normal Zorin Desktop Icons reported `ACTIVE`. The normal Zorin Desktop Icons extension was disabled so the test matched the intended production state. After that:

- GrayHaired Live Desktop was `ACTIVE`.
- Normal Zorin Desktop Icons was `INACTIVE`.
- Exactly one GrayHaired DING/WebKit child was running.
- The expected left icon pane plus right website surface appeared and remained usable.

The full verifier passed on X11, including explicit checks that:

- the current GNOME session type `x11` is supported;
- GrayHaired Live Desktop is active;
- exactly one GrayHaired DING/WebKit child is running;
- the system Zorin DING child is not running;
- runtime verification completed successfully on X11;
- the promoted feature chain through Stage 23 is present.

Physical X11 checks all passed:

- `My Desktop Settings` opened normally.
- The Stage 23 friendly 404 page, keyboard focus, retry action, and visible retry feedback worked.
- Restoring the normal website worked.
- Browser handoff worked.
- A temporary Large-size desktop launcher appeared automatically and disappeared automatically after deletion.
- Large -> Small -> Large icon-size switching kept the left pane correctly sized and the website usable.

## Wayland vs X11 browser activation observation

Browser handoff succeeded on both sessions, but the user-visible activation behavior differed.

On X11, opening a link from the live website brought the already-running browser directly to the foreground and showed the new page immediately.

On Wayland, the link still opened successfully in the browser, but GNOME displayed a top-screen activation notification instead of always raising the already-running browser window. The user then had to click the notification or browser icon to bring the browser forward.

This difference is recorded as a session-specific UX observation, not a Stage 25 failure. It is consistent with Wayland/GNOME focus and activation restrictions and is suitable for a separate follow-up investigation if desired.

## Result

Stage 25 passed.

Current `main` cleanly reproduced the promoted GrayHaired Live Desktop on physical Wayland hardware, the full verifier passed, the physical acceptance checks passed, and the same installed build then passed the dedicated X11 verifier and physical checklist without code changes.

The promoted Live Desktop is therefore physically verified on both Wayland and X11 on the Dell Inspiron-3502, with one documented browser-activation UX difference between the two session types.
