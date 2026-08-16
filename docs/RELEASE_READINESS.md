# Version 1.0 release-readiness audit

Audit status: **NO-GO**

Version 1.0 must not be released from the audited revision. The application
version remains `0.9.0`.

## Audit result

The automated suite completed with **54 passed, 10 skipped**. The skipped tests
require physical desktop-session behavior that the headless automated environment
cannot establish.

The following release verification remains pending:

- final physical verification in a supported Wayland session;
- final physical verification in a supported X11 session.

Passing the automated suite is necessary evidence, but it does not replace either
physical verification pass and does not make this a Version 1.0 release candidate.

## Release blockers

### Misleading Desktop Mode interface

Normal Settings still presents a **Desktop Mode** control even though the approved
Version 1.0 product is the normal windowed launch-page application. Presenting
that control implies a supported product capability that the release cannot
honestly promise. The misleading interface is a release blocker.

A later implementation change must remove the control from normal Settings,
ignore any legacy enabled preference, and ensure normal startup remains windowed.
Those changes are deliberately outside this audit.

### Public product name pending

At the time of this audit, the final public/display product name had not been
selected. `GrayHairedDesktop` remained the internal compatibility identity, and
the working display wording did not constitute a final naming decision. A public
name decision was therefore still required before release.

This audit does not select or anticipate a public product name.

### Physical release verification pending

The complete release workflow must still pass on physical Zorin systems in both
supported display-server sessions. In particular, each pass must verify normal
windowed startup, application-menu launch, opt-in autostart, single-instance
behavior, Settings and preference persistence, external-browser handoff,
accessibility, and clean shutdown without describing the application as Desktop
Mode.

## Scope of this audit

This is a documentation-only record of the release-readiness finding. It makes:

- no runtime changes;
- no **My Desktop** implementation;
- no Desktop Mode UI removal;
- no launcher changes;
- no autostart changes;
- no application source changes;
- no test changes.

Implementation work needed to clear the blockers belongs in a separate pull
request based on this audit, so the chronological NO-GO finding remains intact.

## Release decision

**Version 1.0 is NO-GO.** Keep the version at `0.9.0` until the misleading
Desktop Mode interface and pending public-name decision are resolved in a
separate implementation, both physical session checks pass, and a new explicit
release decision is recorded.
