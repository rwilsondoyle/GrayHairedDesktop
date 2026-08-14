# GNOME Shell 46 development prototype

This directory contains manually installed development source. GrayHaired Desktop
does not install or enable it, and it never modifies Zorin Desktop Icons.

## Confirmed evidence

On Zorin OS 18.1, GNOME Shell 46.0, native Wayland:

- GrayHaired Desktop is identified by WM class or instance
  `tech.grayhaired.GrayHairedDesktop`.
- Zorin Desktop Icons is identified only when GTK application ID
  `com.rastersoft.ding` and the `Desktop Icons ` title prefix both match.
- `global.display.list_all_windows()` discovers both windows.
- The starting client order was Zorin icons, ordinary windows, then GrayHaired.
- Calling only `grayWindow.lower()` did not change that order. Verification failed
  and the saved ordinary GrayHaired state was restored successfully.

The Meta.Window-level lower-only mechanism is therefore insufficient on this
physical compositor state. No loop, delay, retry, or Zorin mutation is added.

## Confirmed actor experiment result

Both windows are `MetaWindowActorWayland` children of one `MetaWindowGroup`.
The physical experiment changed their reported sibling order from
`ZorinIcons<GrayHaired` to `GrayHaired<ZorinIcons`, but GrayHaired remained
visually above the icons. Mutter's Meta.Window order also remained unchanged.
Restoration succeeded. Actor sibling ordering is therefore not a viable control
for the visible Wayland relationship on this target.

## Confirmed managed-client mechanism

Installed Zorin source uses Mutter's `Meta.WaylandClient` through its own
`LaunchSubprocess` lifecycle helper. The wrapper's
`query_window_belongs_to(window)` delegates to the raw client's
`owns_window(window)`. This project uses that observed interface independently
and does not copy Zorin's GPLv3 wrapper implementation.

Physical testing established `new_subprocess=undefined`, `new=function`, and—on
the old raw client—`spawnv=function`, `get_subprocess=undefined`, and
`query_window_belongs_to=undefined`. The process launched but was terminated
safely when the obsolete query requirement failed. Installed source shows that
the wrapper delegates ownership to raw `owns_window(window)`, which the prototype
uses directly. Constructor order matches Zorin: `new(launcher)` first, then
`new(global.context, launcher)` only if the first signature throws.

The corrected physical run passed on the Inspiron-3147: the one-argument form was
rejected, `new(global.context, launcher)+spawnv` launched GrayHaired,
`owns_window()` returned true, and both WM identity fields remained exact. A
manual window close was reported as `process exited; no relaunch`, not a crash.
Managed ownership is proven; Desktop Mode and relative icon stacking are not.

## Confirmed window-list experiment failure

During the completed ownership test, the extension launched one configured
GrayHaired process through a fresh `Meta.WaylandClient`, then required both raw
`owns_window()` ownership and the exact WM class or instance
`tech.grayhaired.GrayHairedDesktop` before reporting success. That evidence is
retained, but `MANAGED_CLIENT_EXPERIMENT` now defaults to `false`.

The one-shot `hide_from_window_list()` test physically changed `skipTaskbar` from
false to true but left window type 0, layer 2, and the functionally incorrect
Meta.Window order unchanged. Real Zorin icons remained underneath GrayHaired;
ordinary windows and the panel/dock remained above it. This operation is rejected
as desktop layering and its mutation code has been removed.

The prototype retains the proven ownership implementation and observation
logging, but managed launch is disabled by default. There is no active
window-list, lower, raise, resize, workspace, focus, type, monitor, actor-order,
or Zorin mutation. There is no polling or automatic relaunch. If the historical
ownership experiment is explicitly reviewed and enabled, disabling the extension
terminates only the subprocess returned by its own `Meta.WaylandClient`.

The development config launches the virtual environment's Python interpreter
directly. It deliberately does not use `scripts/run.sh` or a shell wrapper, so
the ownership test is not ambiguous about an intermediate process.

## Next read-only architecture test

No extension installation is needed. Inspect only the installed Zorin source:

```bash
./scripts/collect-zorin-desktop-layer-cooperation-info.sh \
  | tee zorin-desktop-layer-cooperation-info.txt
```

The bounded report looks for a Zorin-owned actor/container, explicit ordering
abstraction, exported D-Bus or extension-cooperation API, and stable registration
mechanism. It also informs the alternative investigation of a Shell-owned visual
background surface with WebEngine remaining outside Shell. It performs no write,
process operation, installation, enablement, or Zorin modification.

The physical report found external GTK icon windows and no supported
third-party registration or relative-layer interface. Option A is unsupported by
the installed provider. The remaining Shell-owned visual-layer idea currently
requires private placement and an unproven frame/input bridge; no such bridge is
implemented here.

To collect the live Shell hierarchy without mutation, manually enable only the
reviewed ownership-diagnostic prototype, then run:

```bash
./scripts/collect-gnome-shell-layer-hierarchy.sh \
  | tee gnome-shell-layer-hierarchy.txt
```

This command only reads the prototype's journal diagnostics; the collector
itself creates, inserts, removes, or reorders no actor.

## Shell-owned layer visual test

Physical diagnostics found `Main.layoutManager._backgroundGroup` at index 0 of
`global.window_group`. The completed experiment inserted one non-reactive
`St.BoxLayout` at `backgroundIndex + 1`.

The rectangle appeared above wallpaper but also above real Zorin icons and normal
applications. Panel/dock remained above; icons were clickable underneath; no
obvious flicker occurred. Cleanup did not behave safely enough during the session,
the enabled extension recreated the rectangle after reboot, and explicit terminal
disable was required. This was not established as a Shell crash, but the exact
placement is a physical visual failure and recovery/usability risk.

Both `SHELL_OWNED_LAYER_EXPERIMENT` and `MANAGED_CLIENT_EXPERIMENT` now default to
false. Do not enable the mutation experiment for normal development. After
refreshing the branch, replace the per-user source only if observation-only
diagnostics are needed:

```bash
git pull
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech 2>/dev/null || true
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a gnome-extension/grayhaired-desktop-layer@grayhaired.tech \
  ~/.local/share/gnome-shell/extensions/
```

Log out completely, log back into Wayland so Shell reloads the JavaScript, then
enable the now observation-only extension:

```bash
gnome-extensions enable grayhaired-desktop-layer@grayhaired.tech
```

No rectangle or GrayHaired process should appear automatically. Disable the
extension after collecting diagnostics:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech
```

Collect the journal evidence:

```bash
journalctl --user -b --no-pager \
  | grep -E "GrayHaired Desktop Layer|ShellOwnedLayer" \
  | tail -n 100 \
  | tee shell-owned-layer-test.txt
```
