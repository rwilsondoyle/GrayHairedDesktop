# Shortcut Placement audit (PR #59)

## Decision: Outcome B — no safe automatic mutation confirmed

This checkpoint does **not** implement automatic shortcut positioning. The
installed Zorin OS 18.1 provider is the source of truth, and its position
storage has not yet been observed on the physical Inspiron in either session.
The development container does not include
`/usr/share/gnome-shell/extensions/zorin-desktop-icons@zorinos.com`, a running
Zorin desktop, or the physical user's GVfs metadata. Existing repository
evidence confirms that Zorin Desktop Icons is a DING-derived external icon
provider, but it does not establish a supported position-writing contract.

Names remembered from other desktop implementations are not evidence for this
installed fork. In particular, this project will not infer a metadata attribute
name, coordinate meaning, monitor model, refresh behavior, or Wayland/X11
equivalence from ancestry alone. `gio set`, direct extended-attribute writes,
extension edits, Shell evaluation, launcher recreation, and Shell restarts are
therefore outside this PR.

## Read-only evidence collection

Run the diagnostic before and after moving exactly one My Desktop launcher:

```bash
./scripts/inspect-desktop-icon-position.sh \
  | tee ~/my-desktop-icon-position-before.txt
# Drag one My Desktop launcher through Zorin's normal desktop UI.
./scripts/inspect-desktop-icon-position.sh \
  | tee ~/my-desktop-icon-position-after.txt
diff -u ~/my-desktop-icon-position-before.txt \
  ~/my-desktop-icon-position-after.txt
```

The reports include the session type, Desktop contents, complete `gio info`,
existing extended attributes when a reader is already installed, relevant
settings, display geometry when available, and position-related matches from
the installed provider source. The script has no mutation commands. The two
reports and diff can show whether a UI drag produces readable persistent state
and whether the installed code consumes it; they cannot by themselves prove
that writing it is a documented, supported API.

## Manual alignment workflow

Manual placement is the supported initial workflow:

1. Select **Set My Desktop as Wallpaper**.
2. Select **Add My Desktop Shortcuts to Desktop**.
3. If Zorin requests it, right-click a launcher and select **Allow Launching**.
4. Drag that real launcher over, beside, or near its matching wallpaper area.
5. Repeat for each launcher that should be aligned, keeping icons above the
   bottom panel.

The wallpaper remains a static PNG. The real launcher receives the click.
My Desktop does not reposition Home, Trash, drives, folders, unrelated files,
or even its own launchers programmatically.

## Pending physical test — Wayland first

1. Log in to the Inspiron's Wayland session and confirm the session type in the
   diagnostic output.
2. Set My Desktop as Wallpaper and add the seven real shortcuts.
3. Use **Allow Launching** for Gmail if required, then verify Gmail opens.
4. Save a `before` diagnostic report.
5. Drag only Gmail near its matching visible wallpaper area, above the panel.
6. Save an `after` report and diff the reports.
7. Confirm Home, Trash, every unrelated icon, and the wallpaper did not move or
   change; confirm Gmail still opens and remains trusted.
8. Log out and back in, confirm Gmail's manual position persists, and collect a
   third report.
9. Repeat the essential drag, report, persistence, and trust observations in an
   X11 session.

Record the exact installed source paths/lines involved, changed GIO attributes
or other storage, coordinate/grid and monitor semantics, persistence result,
and whether the provider notices a normal UI move without recreation. Until
both sessions are observed, Wayland and X11 physical verification remain
**PENDING**.

## Reconsidering Outcome A

Automatic placement requires evidence from the installed fork of a safe,
user-level, reversible writing interface; defined grid/coordinate, geometry,
monitor, and collision semantics; and reliable provider reload behavior on both
Wayland and X11. Any later implementation must preserve original positions,
touch only launchers marked `X-MyDesktop-Managed=true`, avoid rewriting trusted
launcher contents, and leave occupied cells and all unrelated objects alone.
