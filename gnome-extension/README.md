# GNOME Shell 46 development prototype

This directory contains source for a manual feasibility test. It is not installed,
enabled, or updated by GrayHaired Desktop. It does not contain the Desktop Website
or modify Zorin Desktop Icons.

The prototype recognizes GrayHaired Desktop by the exact compositor identity
`tech.grayhaired.GrayHairedDesktop`. On native Wayland it recognizes Zorin's icon
windows only when both the GTK application ID `com.rastersoft.ding` and the
`Desktop Icons ` title prefix match the behavior observed in the installed Zorin
source. It does not impersonate that identity.

The event-driven prototype reacts to map/destroy, raised, workspace, overview, and
monitor events. When both parties exist, it asks Mutter to lower GrayHaired
Desktop and uses stack positions to place the recognized icon windows immediately
above it. If no recognized icon window exists or verification fails, it restores
the saved geometry/workspace behavior and raises GrayHaired Desktop as an ordinary
window. Disabling the extension performs the same restoration.

This initial prototype deliberately does not use private overview filters. Until
a reversible GNOME 46 mechanism is proven, the GrayHaired window may still appear
in Overview. There is no polling loop.

## Manual installation and test plan (after review only)

Do not run these steps until the prototype has been reviewed. No root access is
needed.

```bash
mkdir -p ~/.local/share/gnome-shell/extensions
cp -a gnome-extension/grayhaired-desktop-layer@grayhaired.tech \
  ~/.local/share/gnome-shell/extensions/
gnome-extensions enable grayhaired-desktop-layer@grayhaired.tech
```

Log out and back in if GNOME does not discover newly copied extension source.
Start GrayHaired Desktop normally; do not enable application autostart for this
test. Use Looking Glass and `journalctl --user` to verify identities and the
prefixed prototype messages.

Test native Wayland first: icons and Desktop Website interaction, ordinary window
stacking, focus, Overview, Show Desktop, workspaces, lock/unlock, icon-provider
restart, monitor hot-plug/scaling, and extension disable/re-enable. Repeat on X11
only after the Wayland result is recorded; X11 icon identity support is not yet
claimed by this prototype.

Disable and remove only the development extension with:

```bash
gnome-extensions disable grayhaired-desktop-layer@grayhaired.tech
rm -rf ~/.local/share/gnome-shell/extensions/grayhaired-desktop-layer@grayhaired.tech
```
