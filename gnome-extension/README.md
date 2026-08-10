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

Installed Zorin source uses Mutter's
`Meta.WaylandClient.new_subprocess(global.context, launcher, argv)`, followed by
`get_subprocess()` and `query_window_belongs_to(window)`. Zorin wraps that API in
its own `LaunchSubprocess` lifecycle helper; this project does not copy that
implementation.

## Current phase — ownership only

`MANAGED_CLIENT_EXPERIMENT` and `SAFE_INVESTIGATION_ONLY` are both `true`. The
extension launches one configured GrayHaired process through a fresh
`Meta.WaylandClient`, then requires both Mutter ownership and the exact WM class
or instance `tech.grayhaired.GrayHairedDesktop` before reporting success.

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

Expected evidence includes `Meta.WaylandClient available=true`, process launch,
an owned mapped window with the exact GrayHaired WM identity, and `OWNERSHIP
PASS`. The appearance is intentionally that of a normal application window.
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
