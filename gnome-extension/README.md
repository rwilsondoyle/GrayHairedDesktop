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

## Current mode — safe investigation only

`SAFE_INVESTIGATION_ONLY` is `true`. The extension now only discovers windows,
reads identities and API availability, reads current Meta.Window ordering, and
reads actor hierarchy. It contains no call that lowers, raises, moves, resizes,
sticks, changes type, focuses, or reorders a window or actor.

## Read-only source investigation

The next step does not require enabling this extension. On the Zorin target run:

```bash
./scripts/collect-zorin-wayland-client-info.sh | tee zorin-wayland-client-info.txt
```

This reads only the installed Zorin Desktop Icons source and reports the precise
Wayland-client helper, launch, ownership-query, map, and lifecycle call sites.

## Optional safe diagnostic rerun

After review, replace the per-user development copy and enable it:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech 2>/dev/null || true
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a gnome-extension/grayhaired-desktop-layer@grayhaired.tech \
  ~/.local/share/gnome-shell/extensions/
gnome-extensions enable grayhaired-desktop-layer@grayhaired.tech
```

If GNOME does not discover the new source, log out and back into the normal
Wayland session and rerun the enable command. In terminal 1:

```bash
./scripts/run.sh
```

While GrayHaired Desktop remains open, collect the actor report in terminal 2:

```bash
./scripts/collect-mutter-window-api.sh | tee mutter-window-api.txt
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech
```

Then close the application and remove only the development extension source:

```bash
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
```

No root access, reboot, automatic installation, window mutation, or system Zorin
extension change is required.
