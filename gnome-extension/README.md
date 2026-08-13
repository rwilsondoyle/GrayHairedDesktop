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
the wrapper delegates ownership to raw `owns_window(window)`, which the next test
uses directly. Constructor order now matches Zorin: `new(launcher)` first, then
`new(global.context, launcher)` only if the first signature throws.

The corrected physical run passed on the Inspiron-3147: the one-argument form was
rejected, `new(global.context, launcher)+spawnv` launched GrayHaired,
`owns_window()` returned true, and both WM identity fields remained exact. A
manual window close was reported as `process exited; no relaunch`, not a crash.
Managed ownership is proven; Desktop Mode and relative icon stacking are not.

## Current phase — one managed desktop-semantic operation

`MANAGED_CLIENT_EXPERIMENT` and `SAFE_INVESTIGATION_ONLY` are both `true`. The
extension launches one configured GrayHaired process through a fresh
`Meta.WaylandClient`, then requires both raw `owns_window()` ownership and the
exact WM class or instance `tech.grayhaired.GrayHairedDesktop` before reporting
success.

After ownership passes, `MANAGED_DESKTOP_SEMANTICS_EXPERIMENT = true` calls only
`managedClient.hide_from_window_list(grayWindow)`. This managed-client operation
is distinct from the already-failed Meta.Window lowering and actor sibling
reordering. It is attempted once and only on the owned exact-identity GrayHaired
window. It may or may not affect visible stacking; only physical visual testing
can answer that question. Disablement restores the same window with
`show_in_window_list()` before terminating the owned subprocess.

The process remains a normal application window. There is no lower, raise,
resize, workspace, focus, type, monitor, actor-order, or Zorin mutation. There is
no polling or automatic relaunch. Disabling the extension terminates only the
subprocess returned by this extension's own `Meta.WaylandClient`.

The development config launches the virtual environment's Python interpreter
directly. It deliberately does not use `scripts/run.sh` or a shell wrapper, so
the ownership test is not ambiguous about an intermediate process.

## Manual native-Wayland ownership test

Do not run these steps until this source has been reviewed. From the repository,
first create the development config and replace every `/absolute/path/...`
placeholder with the repository's actual absolute path:

```bash
cp gnome-extension/grayhaired-desktop-layer@grayhaired.tech/managed-client-config.json.example \
  gnome-extension/grayhaired-desktop-layer@grayhaired.tech/managed-client-config.json
${EDITOR:-nano} \
  gnome-extension/grayhaired-desktop-layer@grayhaired.tech/managed-client-config.json
```

Close separately launched GrayHaired instances. Replace the per-user development
copy, without root access:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech 2>/dev/null || true
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a gnome-extension/grayhaired-desktop-layer@grayhaired.tech \
  ~/.local/share/gnome-shell/extensions/
gnome-extensions enable grayhaired-desktop-layer@grayhaired.tech
```

If GNOME does not discover the new source, log out and back into the normal
Wayland session and rerun only the enable command. Do not run `scripts/run.sh`;
the extension launches the configured process. After its normal window maps,
collect the Shell-context report:

```bash
./scripts/collect-mutter-window-api.sh | tee mutter-window-api.txt
```

Expected ownership evidence is the already proven
`API path=new(global.context, launcher)+spawnv`, `owns_window=function`, exact
GrayHaired WM identity, and `OWNERSHIP PASS`. The new report then includes
`ManagedDesktop BEFORE`, the single `hide_from_window_list` operation,
`ManagedDesktop AFTER`, and `RESULT REQUIRES VISUAL CONFIRMATION`.

Visually check whether the live Desktop Website remains interactive, the real
Zorin icons become visible and interactive above it, ordinary applications stay
above both, and the panel/dock remains normal. Also enter Overview once. Do not
infer success merely from actor indexes or log ordering. If icons remain hidden,
record failure and disable the extension.
Then disable the prototype, which terminates only its own managed subprocess:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech
```

Then close the application and remove only the development extension source:

```bash
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
```

No root access, reboot, automatic installation, stacking mutation, or system
Zorin extension change is required. Failure is logged once and is not retried.
