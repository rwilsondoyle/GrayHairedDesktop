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

The Phase 2 experiment calls `lower()` only on GrayHaired Desktop, then uses
Mutter's sorted full window list to verify:

1. GrayHaired Desktop is below every icon window; and
2. recognized ordinary, taskbar-visible normal application windows are above the
   highest icon window.

Other desktop, utility, Shell-related, skip-taskbar, or unclassified windows do
not cause failure merely because they occupy another low stack position. A
visible compositor actor is checked, but only physical testing can prove that the
separate Shell background actor is not obscuring GrayHaired Desktop.

The Zorin icon windows remain observation-only. If the API is unavailable, an
identity is missing, or verification fails, the prototype restores GrayHaired
Desktop's saved geometry/workspace behavior and raises it as an ordinary window.

Reconciliation is event-driven for map/destroy, raised, workspace, Overview, and
monitor changes. There is no polling loop. This initial prototype does not use
private Overview filters, so the GrayHaired window may still appear in Overview.

Runtime API diagnostics execute only inside the GNOME Shell extension context.
They record `typeof` results for documented and disputed methods on the actual
GrayHaired and Zorin `Meta.Window` objects, their compositor identity fields, and
stack-related methods on the actual `global.display`. Standalone GJS is not used;
on this Zorin release it cannot import Shell's private `Meta` namespace.

The completed native-Wayland diagnostics confirmed GrayHaired Desktop as
`tech.grayhaired.GrayHairedDesktop` in both WM class fields with a null GTK
application ID. It also confirmed `lower`, `raise`, `get_layer`, `stick`,
`unstick`, and Display stack sorting, while `set_type`, window-list mutation, and
absolute stack-position methods were undefined. That run could not see Zorin's
windows through filtered actor APIs. `list_all_windows()` solved that blind spot
and found Zorin's `com.rastersoft.ding` client window.

## Phase 1 — safe diagnostic (complete)

The native-Wayland diagnostic confirmed that `list_all_windows()` and
`sort_windows_by_stacking()` are functions and that `window-created` is exposed.
It found the identities recorded above and the initial bottom-to-top order:
Zorin icons, GrayHaired Desktop, then ordinary applications.

## Phase 2 — GrayHaired-only lowering experiment

`EXPERIMENT_MODE` now defaults to `true`. The experiment retains all read-only
logging and discovery, but its only initial stacking mutation is
`grayWindow.lower()`. It never calls a mutating method on a Zorin icon window and
does not resize GrayHaired Desktop for this first stacking test.

After the source change is reviewed, use two terminals in the normal Zorin
Wayland session.

First update the per-user development extension and enable it:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech 2>/dev/null || true
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a gnome-extension/grayhaired-desktop-layer@grayhaired.tech \
  ~/.local/share/gnome-shell/extensions/
gnome-extensions enable grayhaired-desktop-layer@grayhaired.tech
```

If GNOME does not discover the new source, log out and back into Wayland, then
run the enable command. In terminal 1, start GrayHaired Desktop:

```bash
./scripts/run.sh
```

While it remains open, use terminal 2 to collect the Phase 2 evidence and then
disable the extension so restoration can be observed:

```bash
./scripts/collect-mutter-window-api.sh | tee mutter-window-api.txt
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech
```

Confirm that the journal contains the discovered identities, stack before,
`grayWindow.lower()`, stack after, and PASS or FAIL line. Confirm that disabling
returns GrayHaired Desktop to ordinary behavior. Then close the application and
remove only the development extension source:

```bash
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
```

No root access, reboot, automatic installation, or Zorin extension change is
required.
