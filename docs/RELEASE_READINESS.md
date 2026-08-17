# Version 1.0 release-readiness checkpoints

## Version 1.0.0 release status

**My Desktop 1.0.0 is released.** PR #53 completed the final readiness **GO**
checkpoint after the release candidate passed physical verification on X11/Xorg
and Wayland. The supported Version 1.0 product is the normal windowed launch
page. True Desktop Mode remains Future Research, and configured-website CPU
optimization remains a separate, non-blocking future follow-up.

The sections below preserve the chronology and evidence from PR #51's historical
**NO-GO** audit through PR #53's final **GO** decision.

## Final post-PR #52 release-readiness decision — GO

**GO.** The `0.9.0` release candidate is approved to proceed to a separate,
controlled Version `1.0.0` release/version-bump PR after this documentation
checkpoint is reviewed and merged. This checkpoint does not perform that bump
or create the release.

The chronology is intentionally preserved: PR #51 recorded the then-current
**NO-GO** audit below; PR #52 introduced the public **My Desktop** identity,
removed the unsupported Desktop Mode UI, preserved internal compatibility, and
passed focused physical checks; and the post-PR #52 pass installed current
`main` at merge commit `94d1929` and completed final end-to-end physical
verification.

| Final readiness item | Result |
| --- | --- |
| Installed candidate | **0.9.0 at main commit `94d1929`** |
| Final X11/Xorg physical verification | **PASS** |
| Final Wayland physical verification | **PASS** |
| Public/display identity | **My Desktop — PASS** |
| Internal compatibility identity | **GrayHairedDesktop / grayhaired-desktop — PRESERVED** |
| Unsupported Desktop Mode control | **ABSENT** |
| Final Version 1.0 release-readiness decision | **GO** |

### Clean-main installation

Testing used a Dell Inspiron-3147 running Zorin OS 18.1 and GNOME Shell 46.
After PR #52 merged, current `main` at `94d1929` was installed with
`./scripts/update-user-install.sh`; the installer completed successfully and
reported `My Desktop installed.` The version remained `0.9.0`. The stable
launcher was `/home/ron/.local/bin/grayhaired-desktop`, and the menu file was
`/home/ron/.local/share/applications/grayhaired-desktop.desktop`.

`git status --short` was clean before physical application testing. A previously
generated, untracked runtime-cooperation report was moved outside the repository
before that check.

### Final X11/Xorg physical verification — PASS

In a verified `x11` session, My Desktop autostarted; displayed the correct title
and configured Desktop Website; opened Settings without a Desktop Mode control;
opened a normal website link externally while retaining the Desktop Website;
and opened a configured shortcut. Settings Save persisted a harmless change
across close/reopen, while Settings Cancel did not persist a harmless canceled
change.

Launching from the Zorin application menu while already running created no
second window, and process inspection showed one real application process plus
expected QtWebEngine helpers. **Help → Open Log Folder** worked, and the log
existed at
`/home/ron/.local/state/GrayHairedDesktop/grayhaired-desktop.log`.

### Final Wayland physical verification — PASS

After logout from X11 and login to a verified `wayland` session, My Desktop
autostarted without manual launch. Settings opened normally and still had no
Desktop Mode control. A duplicate application-menu launch created no second
window; the expected brief GNOME attention notification appeared and
disappeared normally. Process inspection showed one real application process,
using the installed `venv/bin/python` and `venv/bin/grayhaired-desktop`, plus
expected QtWebEngine helpers. The same compatibility log existed and was
actively updated.

For both sessions, the canonical autostart entry was:

```ini
[Desktop Entry]
Type=Application
Name=My Desktop
Exec=/home/ron/.local/bin/grayhaired-desktop
Terminal=false
X-GNOME-Autostart-enabled=true
```

### Final identity and supported-mode boundary

**My Desktop** is the public/user-visible product name. The established
**GrayHairedDesktop / grayhaired-desktop** project and compatibility identity
remains in settings, paths, application identifiers, logging, packaging, and
the stable `~/.local/bin/grayhaired-desktop` launcher.

Unsupported Desktop Mode is not exposed as a normal Settings option. Legacy
`desktopMode=true` state cannot activate it. This release-readiness checkpoint
does not restore that mode or rename compatibility identifiers.

### Non-blocking Desktop Website performance follow-up

Higher CPU use observed on the Inspiron-3147 was isolated through controlled
comparison: plain QtWebEngine showing `about:blank` was essentially idle at 0%
in repeated live measurements, while plain QtWebEngine loading the configured
Desktop Website reproduced the load. My Desktop loading the same site showed
similar use, and minimizing it did not eliminate the website-related activity.
`QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"` made CPU use worse and must not be
added.

The evidence points to the configured website content rather than My Desktop's
architecture, QtWebEngine by itself, or PR #52's naming/Desktop Mode changes.
Website performance optimization remains a separate future follow-up and is not
a Version 1.0 application release blocker.

## Historical PR #51 final audit — NO-GO

### Audit scope and chronology

This document records the final Version 1.0 readiness state **before the My
Desktop implementation**. It is a documentation-only audit of the existing
product; it does not implement My Desktop or revise the product.

The audited version remains `0.9.0`. No version bump is authorized by this
audit.

### Release decision

**NO-GO.** Version 1.0 must not be released from the audited state.

The automated readiness audit completed with **54 passed, 10 skipped**. That
result is necessary evidence, but it does not clear the outstanding physical
verification or product-presentation blockers.

| Release-readiness item | Audit result |
| --- | --- |
| Current version | **0.9.0** |
| Automated readiness audit | **PASSED — 54 passed, 10 skipped** |
| Final Wayland physical verification | **PENDING** |
| Final X11 physical verification | **PENDING** |
| Desktop Mode Settings control | **BLOCKER — MISLEADING** |
| Final public product name | **PENDING** |
| Release decision | **NO-GO** |

### Release blockers

#### Final physical verification is incomplete

The final release-candidate workflow still requires physical verification on
both supported session types:

- final Wayland physical verification is pending; and
- final X11 physical verification is pending.

Earlier physical results for specific installation, autostart, and
single-instance milestones remain useful historical evidence, but they do not
substitute for the pending final, end-to-end Version 1.0 verification.

#### The Desktop Mode Settings control is misleading

The existing Settings UI presents a Desktop Mode control even though the
audited product cannot deliver the expected Desktop Mode experience on its
target Zorin/GNOME environment. A release-facing control that suggests this
capability is available misrepresents the product's supported behavior.

The misleading control is a **release blocker**. This audit records the problem
only; it does not change Settings or prescribe an implementation.

#### The final public product name is pending

At the time of this audit, the final public product name had not been selected.
No name is selected, introduced, or changed here. Public naming must be resolved
in later, separately scoped work before release.

### Change boundary

This audit changes documentation only. In particular:

- no runtime changes are included;
- no naming changes are included;
- no Settings changes are included;
- no launcher or autostart changes are included; and
- no tests are changed.

Application identity, installer behavior, source code, scripts, launcher
resources, defaults, and version metadata remain untouched.

### Exit criteria

The **NO-GO** decision remains in force until later work, outside this audit:

1. resolves the misleading Desktop Mode Settings control;
2. resolves the final public product name;
3. completes final physical verification on Wayland;
4. completes final physical verification on X11; and
5. performs a new explicit release-readiness decision based on that completed
   state.

This audit is a chronological checkpoint, not permission to implement My
Desktop, rename the application, change Settings, or release Version 1.0.

### Later implementation milestone

The later **Rename Public Product to My Desktop and Remove Desktop Mode UI**
implementation resolves the first two presentation blockers recorded above:
the public/display name is now **My Desktop**, with the GrayHairedDesktop
technical/internal compatibility identity preserved, and normal Settings no
longer exposes the unsupported Desktop Mode control. Legacy
`preferences/desktopMode=true` is ignored and persisted as false, so startup is
always the supported normal windowed path.

This later milestone does not alter the audit's historical NO-GO result. The
version remains `0.9.0`. The focused PR #52 Wayland and X11 verification
described below passed, but the separate final release-readiness physical pass
remains pending. A `1.0.0` bump remains prohibited until that final pass becomes
GO and a new release decision authorizes it.

### PR #52 physical verification — passed

The My Desktop implementation was physically verified on a Dell Inspiron-3147
running Zorin OS 18.1 and GNOME Shell 46. These later results resolve the naming
and Desktop Mode UI blockers recorded by the earlier PR #51 audit; they do not
rewrite that audit or constitute the final Version 1.0 release-readiness pass.

| PR #52 verification item | Result |
| --- | --- |
| Public/display name **My Desktop** | **PASSED** |
| Desktop Mode control absent from normal Settings | **PASSED** |
| Existing Desktop Website and shortcut settings preserved | **PASSED** |
| Application-menu visible name **My Desktop**, under Accessories | **PASSED** |
| Canonical autostart visible name **My Desktop** | **PASSED** |
| Wayland autostart | **PASSED** |
| X11 autostart | **PASSED** |
| Wayland single-instance behavior | **PASSED — final real process count 1** |
| X11 single-instance behavior | **PASSED — final real process count 1** |

#### Wayland observations

Installation with `./scripts/update-user-install.sh` succeeded and displayed
`My Desktop installed.` The stable launcher remained
`/home/ron/.local/bin/grayhaired-desktop`; the window and Zorin application menu
displayed **My Desktop**; normal Settings had no Desktop Mode control; and the
existing saved Desktop Website and shortcut settings remained available.

The canonical login entry was:

```ini
[Desktop Entry]
Type=Application
Name=My Desktop
Exec=/home/ron/.local/bin/grayhaired-desktop
Terminal=false
X-GNOME-Autostart-enabled=true
```

After logout/login, My Desktop opened automatically and exactly one real
application instance remained. A second launch exited normally, logged
`Existing application instance notified; exiting`, and left a final real
process count of **1**, with no second window. GNOME's brief attention indicator
was acceptable.

#### X11 observations

After shutdown and restart into the verified `x11` session, My Desktop opened
automatically at login. Exactly one real application instance was present. A
second launch produced no second window, exited normally, logged
`Existing application instance notified; exiting`, and left a final real
process count of **1**. GNOME's brief notice disappeared normally. Autostart and
single-instance behavior therefore both passed on X11.

#### Separate Desktop Website CPU follow-up

The Inspiron's observed sustained CPU use was isolated to the configured
Desktop Website content, not to the PR #52 rename/Desktop Mode UI changes and
not to idle QtWebEngine itself. A plain QtWebEngine `about:blank` test was
essentially 0% CPU while idle, while a plain QtWebEngine test loading the same
saved Desktop Website reproduced the high CPU use. This is not a PR #52 blocker
and may be tracked as a separate website-performance follow-up.

Testing with `QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"` made CPU use worse.
That flag must not be added. PR #52 makes no runtime change based on this
investigation.
