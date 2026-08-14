# GNOME Shell 46 background-content layer research

## Scope and decision

This note answers one question for GNOME Shell 46 / Mutter 46: can an extension
use a supported or reasonably stable mechanism to render interactive content
above the wallpaper while remaining below **every** client window?

**Conclusion:** no maintainable GNOME Shell extension architecture currently
satisfies that requirement while the live Desktop Website stays in its external
PySide6/QtWebEngine process and Zorin's real desktop-icon client windows remain
in use. GNOME Shell has internal background containers, but it exposes no
documented extension hook for third-party background content. Directly adopting
those containers would depend on Shell/Mutter implementation details and would
still not embed or forward input to the external Wayland surface through a
supported API.

This is research only. It adds no actor or window experiment, changes no runtime
code, and requires no physical test. The application remains version `0.9.0` and
its normal-window Desktop Launch Page remains the safe fallback.

## Evidence labels

Every material statement below is marked with one of these labels:

* **PUBLIC/DOCUMENTED** — published GNOME/GJS extension or introspection API.
* **GNOME-SHELL-PRIVATE** — GNOME Shell implementation, not an extension API.
* **MUTTER-PRIVATE** — Mutter compositor implementation, not a supported
  extension contract.
* **OBSERVED-RUNTIME** — result already collected on the target computer.
* **INFERENCE** — conclusion derived from the identified evidence.

An introspectable Clutter or Meta method is not automatically a supported GNOME
Shell extension integration point. Conversely, an underscore is not the only
reason an object can be private: globals and implementation-owned actor trees
also lack an extension compatibility contract.

## Primary sources and version boundary

Research is pinned to the `46.0` source tag rather than current `main`:

* GNOME Shell [`js/ui/background.js`](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/46.0/js/ui/background.js)
  and [`js/ui/layout.js`](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/46.0/js/ui/layout.js)
  define the normal desktop backgrounds and their layout-owned container.
* GNOME Shell [`js/ui/workspace.js`](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/46.0/js/ui/workspace.js)
  defines workspace/Overview background presentation; it is not the persistent
  desktop-under-windows layer.
* Mutter [`src/compositor/meta-background-group.c`](https://gitlab.gnome.org/GNOME/mutter/-/blob/46.0/src/compositor/meta-background-group.c),
  [`meta-background-actor.c`](https://gitlab.gnome.org/GNOME/mutter/-/blob/46.0/src/compositor/meta-background-actor.c),
  and [`meta-window-group.c`](https://gitlab.gnome.org/GNOME/mutter/-/blob/46.0/src/compositor/meta-window-group.c)
  implement compositor-owned painting/culling.
* Mutter [`src/compositor/meta-window-actor.c`](https://gitlab.gnome.org/GNOME/mutter/-/blob/46.0/src/compositor/meta-window-actor.c)
  and [`meta-compositor.c`](https://gitlab.gnome.org/GNOME/mutter/-/blob/46.0/src/compositor/meta-compositor.c)
  establish that client windows are compositor actors whose stacking is managed
  by Mutter, not an ordinary extension-owned content list.
* The [GJS extension API overview](https://gjs.guide/extensions/overview/anatomy.html),
  [GNOME 45+ module guidance](https://gjs.guide/extensions/upgrading/gnome-shell-45.html),
  and [GNOME Shell JavaScript API index](https://gnome.pages.gitlab.gnome.org/gnome-shell/)
  describe the supported extension surface. None documents background-content
  registration or adoption of an external Wayland surface.

These are architecture findings, not claims that every private implementation
detail remains identical across later 46.x distribution patches.

## Normal desktop background architecture

1. **GNOME-SHELL-PRIVATE:** `LayoutManager` constructs
   `Main.layoutManager._backgroundGroup` as a `Meta.BackgroundGroup` and places
   it in the compositor's `global.window_group`. The underscore and ownership by
   `LayoutManager` make it private implementation state; it is not returned by a
   documented extension registration function.
2. **GNOME-SHELL-PRIVATE:** Shell creates a `BackgroundManager` per monitor. Each
   manager creates/manages the monitor's background actor in the supplied
   container and reacts to background/monitor changes. Extensions are not given
   an ownership callback or a reserved child slot among those actors.
3. **MUTTER-PRIVATE:** `MetaBackgroundActor` is the compositor background actor,
   with monitor-specific background state and paint-volume/culling behavior.
   `MetaBackgroundGroup` coordinates culling for its background children. This
   is specialized compositor rendering, not a general public “desktop widget”
   service.
4. **INFERENCE:** A generic Clutter child operation may be callable on a
   `MetaBackgroundGroup`, but callability proves neither ownership nor lifecycle,
   ordering, input, or compatibility. Adding an unmanaged child would be direct
   mutation of Shell's private actor tree.
5. **OBSERVED-RUNTIME:** The target reported the layout background group as child
   index 0 of `global.window_group`. This establishes the particular live tree,
   not a public order contract.

The normal per-monitor actors are therefore real candidates only for explaining
how Shell paints wallpaper. They are not extension-facing content hosts.

## Workspace backgrounds are not the requested layer

1. **GNOME-SHELL-PRIVATE:** workspace/Overview code creates background managers
   and actors for workspace previews and transitions.
2. **INFERENCE:** Those actors belong to Overview/workspace presentation and
   transform with that UI. They do not provide a persistent, interactive actor
   below all normal client windows in the desktop view.
3. **PUBLIC/DOCUMENTED:** the extension documentation publishes no API that
   converts a workspace background actor into persistent desktop content.

Using an Overview background would consequently solve a different paint path
and would not satisfy the required normal-session order.

## Window, UI, and paint ordering

1. **MUTTER-PRIVATE:** `global.window_group` is a `MetaWindowGroup`. Mutter owns
   the compositor window actors and performs region culling/painting for the
   group. Ordinary client surfaces appear as `MetaWindowActor` subclasses.
2. **MUTTER-PRIVATE:** `MetaWindowGroup` participates in compositor culling; its
   children cannot safely be treated as a plain application-controlled z-list.
   No public contract says a non-window sibling index establishes a visual
   relationship with every `MetaWindowActor`.
3. **OBSERVED-RUNTIME:** PR #39 changed reported sibling placement without
   obtaining the corresponding visible stack. It also inserted a Shell-owned
   actor immediately above `_backgroundGroup`; that actor painted over desktop
   icons and ordinary applications. These results directly disprove index-based
   inference on the target.
4. **GNOME-SHELL-PRIVATE:** `global.top_window_group` and Shell's stage/UI groups
   are implementation-owned layers for compositor/Shell presentation. Layout
   chrome APIs place Shell UI relative to other Shell UI; they do not promise an
   under-all-client content layer.
5. **INFERENCE:** placement in `uiGroup`, `top_window_group`, or chrome moves in
   the wrong direction for this requirement. Placement beside the background in
   `window_group` has already failed physically. No alternate sibling index is
   justified.

Wallpaper does use specialized background actors and compositor culling, while
client windows use `MetaWindowActor` and compositor stacking. That distinction
explains why inspecting a common actor-parent index is insufficient; it does not
create a third-party layering API.

## Candidate assessment

| Candidate | Evidence | Assessment |
| --- | --- | --- |
| Documented extension background-content hook | **PUBLIC/DOCUMENTED:** absent from the extension/API documentation reviewed above. | **No candidate.** |
| `Main.layoutManager._backgroundGroup` | **GNOME-SHELL-PRIVATE:** private object and lifecycle. **MUTTER-PRIVATE:** specialized group/culling. | A source-level possibility for Shell's own actors, not supported or reasonably stable third-party architecture. |
| Per-monitor `BackgroundManager` / `MetaBackgroundActor` | **GNOME-SHELL-PRIVATE** and **MUTTER-PRIVATE:** Shell-created wallpaper machinery. | No content registration, ownership, or input bridge. |
| Workspace background actors | **GNOME-SHELL-PRIVATE:** Overview/workspace presentation. | Wrong lifecycle and scene. |
| `global.window_group` sibling | **OBSERVED-RUNTIME:** visible ordering contradicted actor index. | Physically rejected; no index variants. |
| `global.top_window_group`, UI group, or chrome | **GNOME-SHELL-PRIVATE:** Shell UI layers. | Above, rather than below, client content; wrong slot. |
| External Qt Wayland surface inside a background actor | **PUBLIC/DOCUMENTED:** no Shell extension API adopts/embeds a foreign Wayland surface. | No candidate. Mirroring plus input forwarding would be a new, unsupported subsystem. |

### Interactivity and the external process boundary

* **PUBLIC/DOCUMENTED:** Clutter actors can be reactive and participate in Shell
  input handling. That documents actor capability, not permission to use Shell's
  private background container.
* **INFERENCE:** a newly written Shell-native reactive actor could potentially
  receive events, but it would not be the QtWebEngine page. Rendering arbitrary
  web/network content in Shell is prohibited by the product boundary and would
  increase Shell's security/failure exposure.
* **PUBLIC/DOCUMENTED:** no reviewed extension API imports the external
  PySide6/QtWebEngine Wayland surface as a `ClutterActor`, forwards its complete
  keyboard/pointer/touch/accessibility semantics, or gives it Shell focus.
* **INFERENCE:** a custom frame transport and input protocol would not turn the
  background-container access into a supported hook. It would also cease to be
  a focused, maintainable integration.

### Relationship to Zorin Desktop Icons

* **OBSERVED-RUNTIME:** Zorin Desktop Icons renders real icons in external client
  windows, not in Shell's wallpaper group.
* **INFERENCE:** content genuinely confined to Shell's compositor background
  group should remain below client windows, including Zorin's icon windows.
  However, that expectation is derived from private architecture and is not a
  supported contract offered to extensions.
* **OBSERVED-RUNTIME:** the superficially similar placement immediately above
  the background group did *not* remain below those clients. Actor indexes alone
  must not be used to strengthen the inference.

## Answer and stopping point

**PUBLIC/DOCUMENTED:** GNOME Shell 46 exposes no extension-facing background
content hook and no supported external-surface embedding mechanism.

**GNOME-SHELL-PRIVATE / MUTTER-PRIVATE:** Shell and Mutter do have internal
background groups, managers, and per-monitor actors that implement the wallpaper
layer. Mutating those implementation-owned objects is not a reasonably stable
extension architecture, and their presence supplies no external WebEngine/input
bridge.

**OBSERVED-RUNTIME:** the one nearby actor placement already tested cannot be
trusted to sit below client windows. No actor-index variation should follow.

**INFERENCE:** no maintainable GNOME Shell extension architecture currently
satisfies the live interactive Desktop Website requirement while preserving
Zorin's real desktop icons. No candidate supported background-content mechanism
remains. A future documented GNOME background-content API or a provider-supported
surface protocol could change this conclusion; neither exists in the reviewed
GNOME 46 interfaces.

No future physical test is justified by this research: the remaining uncertainty
is whether private actor-tree mutation happens to work in one runtime, not a
specific fact capable of establishing support or reasonable stability. Testing
that would be another prohibited visual actor experiment. Desktop Mode remains
unresolved and continues to block Version 1.0.
