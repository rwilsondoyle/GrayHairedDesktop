# GNOME Shell 46 development prototype

This directory contains source for an API and relative-ordering feasibility test.
It is not installed, enabled, or updated by GrayHaired Desktop. It contains no
Desktop Website content and does not modify Zorin Desktop Icons.

The prototype recognizes GrayHaired Desktop by the exact compositor identity
`tech.grayhaired.GrayHairedDesktop`. On native Wayland it recognizes Zorin's icon
windows only when both the GTK application ID `com.rastersoft.ding` and the
`Desktop Icons ` title prefix match the behavior observed in the installed Zorin
source. It does not impersonate that identity.

GNOME 46's documented `Meta.Window` surface includes `lower()` and `raise()`, and
`Meta.Display` provides `sort_windows_by_stacking()`. The initial prototype
incorrectly assumed absolute `get_stack_position()` and `set_stack_position()`
methods; those calls have been removed.

The corrected experiment lowers every recognized Zorin icon window first and
GrayHaired Desktop last, then uses Mutter's sorted full window list to verify:

1. GrayHaired Desktop is below every icon window; and
2. recognized ordinary, taskbar-visible normal application windows are above the
   highest icon window.

Other desktop, utility, Shell-related, skip-taskbar, or unclassified windows do
not cause failure merely because they occupy another low stack position. A
visible compositor actor is checked, but only physical testing can prove that the
separate Shell background actor is not obscuring GrayHaired Desktop.

This sequence relies on the experimental premise that the most recently lowered
window becomes bottom-most. The verification—not that premise—is authoritative.
If the API is unavailable, an identity is missing, or verification fails, the
prototype restores GrayHaired Desktop's saved geometry/workspace behavior and
raises it as an ordinary window.

Reconciliation is event-driven for map/destroy, raised, workspace, Overview, and
monitor changes. There is no polling loop. This initial prototype does not use
private Overview filters, so the GrayHaired window may still appear in Overview.

Runtime API diagnostics execute only inside the GNOME Shell extension context.
They record `typeof` results for documented and disputed methods on the actual
GrayHaired and Zorin `Meta.Window` objects, their compositor identity fields, and
stack-related methods on the actual `global.display`. Standalone GJS is not used;
on this Zorin release it cannot import Shell's private `Meta` namespace.

## Installation is blocked pending API verification

Do **not** install or enable this extension yet. The runtime report necessarily
depends on later, separately approved manual enablement because the relevant
objects exist only inside GNOME Shell. No installation command is intentionally
provided at this stage.

After the API report is reviewed, a separate approval can add exact manual
installation, Wayland-first testing, disable, and removal steps. No reboot,
root access, automatic startup, or system-extension modification will be part of
that procedure.
