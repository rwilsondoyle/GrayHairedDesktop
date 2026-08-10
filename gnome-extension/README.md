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

## Current mode — read-only actor hierarchy diagnostic

`ACTOR_DIAGNOSTIC_ONLY` defaults to `true`. The extension obtains the proven
`Meta.Window` objects through `list_all_windows()` and calls the read-only
`get_compositor_private()` relationship to discover their compositor actors.
It logs:

- actor and parent types plus the parent name;
- whether GrayHaired and each Zorin actor have exactly the same parent;
- each actor's sibling index and sanitized previous/next sibling categories;
- runtime availability of actor parent/previous/next getters; and
- runtime availability of the parent's below/above/at-index ordering methods.

It does not call any window mutation or actor sibling-ordering method. Normal
application and Desktop Website titles are not logged. The old Phase 2 code
remains unreachable for historical comparison only.

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

## Possible later experiment — not active

Only if the physical report proves that both actors share one parent and the
parent exposes the required method may a later reviewed commit test:

```javascript
parent.set_child_below_sibling(grayActor, zorinActor);
```

That future test would immediately verify actor sibling order, Mutter window
order, and visible behavior. It is not active here. Mutter may reassert its own
window stack later, so even a one-time visual success would not yet prove a final
architecture.
