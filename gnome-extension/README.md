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

## Current mode — controlled actor-order experiment

The read-only actor diagnostic confirmed that both windows use
`MetaWindowActorWayland`, share one `MetaWindowGroup`, and expose the required
sibling APIs. `ACTOR_EXPERIMENT_MODE` now defaults to `true`.

On each meaningful event, the extension obtains the actors through the proven
`Meta.Window.get_compositor_private()` relationship and reads their shared
parent's child list. If GrayHaired's index is already below every Zorin actor, it
logs **Actor order already correct** and performs no mutation. Otherwise its only
initial ordering mutation is:

```javascript
parent.set_child_below_sibling(grayActor, zorinActor);
```

The Zorin actor is never the actor being moved, no `Meta.Window` is mutated, and
no geometry, workspace, focus, or other sibling is directly changed. The result
is verified from the parent child array, same-parent identity, actor visibility,
and unchanged relative ordering among ordinary application actors. Mutter's
separate Meta.Window order is logged before and after for comparison but is not a
pass criterion.

At most one actor mutation is attempted per enablement. If Mutter later changes
the order, the extension reports it without repeatedly reordering the actor.

Before mutation the extension remembers GrayHaired's previous and next siblings.
Disablement or failed verification restores GrayHaired relative to a surviving
remembered sibling. If neither recovery anchor remains, it logs that logout/login
is the development fallback rather than guessing another position.

## Safe Wayland rerun

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

