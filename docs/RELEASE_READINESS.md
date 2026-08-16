# Final Version 1.0 release-readiness audit — NO-GO

## Audit scope and chronology

This document records the final Version 1.0 readiness state **before the My
Desktop implementation**. It is a documentation-only audit of the existing
product; it does not implement My Desktop or revise the product.

The audited version remains `0.9.0`. No version bump is authorized by this
audit.

## Release decision

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

## Release blockers

### Final physical verification is incomplete

The final release-candidate workflow still requires physical verification on
both supported session types:

- final Wayland physical verification is pending; and
- final X11 physical verification is pending.

Earlier physical results for specific installation, autostart, and
single-instance milestones remain useful historical evidence, but they do not
substitute for the pending final, end-to-end Version 1.0 verification.

### The Desktop Mode Settings control is misleading

The existing Settings UI presents a Desktop Mode control even though the
audited product cannot deliver the expected Desktop Mode experience on its
target Zorin/GNOME environment. A release-facing control that suggests this
capability is available misrepresents the product's supported behavior.

The misleading control is a **release blocker**. This audit records the problem
only; it does not change Settings or prescribe an implementation.

### The final public product name is pending

At the time of this audit, the final public product name had not been selected.
No name is selected, introduced, or changed here. Public naming must be resolved
in later, separately scoped work before release.

## Change boundary

This audit changes documentation only. In particular:

- no runtime changes are included;
- no naming changes are included;
- no Settings changes are included;
- no launcher or autostart changes are included; and
- no tests are changed.

Application identity, installer behavior, source code, scripts, launcher
resources, defaults, and version metadata remain untouched.

## Exit criteria

The **NO-GO** decision remains in force until later work, outside this audit:

1. resolves the misleading Desktop Mode Settings control;
2. resolves the final public product name;
3. completes final physical verification on Wayland;
4. completes final physical verification on X11; and
5. performs a new explicit release-readiness decision based on that completed
   state.

This audit is a chronological checkpoint, not permission to implement My
Desktop, rename the application, change Settings, or release Version 1.0.

## Later implementation milestone

The later **Rename Public Product to My Desktop and Remove Desktop Mode UI**
implementation resolves the first two presentation blockers recorded above:
the public/display name is now **My Desktop**, with the GrayHairedDesktop
technical/internal compatibility identity preserved, and normal Settings no
longer exposes the unsupported Desktop Mode control. Legacy
`preferences/desktopMode=true` is ignored and persisted as false, so startup is
always the supported normal windowed path.

This later milestone does not alter the audit's historical NO-GO result. The
version remains `0.9.0`; focused Wayland and X11 physical verification and the
final release-readiness physical pass remain pending. A `1.0.0` bump remains
prohibited until those checks pass and a new release decision authorizes it.
