# GNOME Shell Desktop Integration Feasibility

## Decision

A thin GNOME Shell extension **cannot reliably provide** the required ordering

```text
wallpaper / shell background
GrayHaired Desktop live Desktop Website
user's real Zorin/GNOME desktop icons
ordinary application windows
Zorin panel, dock, and menus
```

while retaining the existing PySide6 window as the content surface on Wayland.
This is an architectural limitation, not an unimplemented Qt flag. A prototype
extension that merely lowers a window would demonstrate an arrangement that is
known to be incomplete and version-sensitive, so this phase intentionally does
not ship one or claim Desktop Mode support on GNOME.

The safe Version 1.0 position is therefore:

- keep GNOME Wayland in normal/windowed mode;
- keep the existing pure-Qt X11 Desktop Mode candidate only for non-GNOME X11
  environments;
- do not hide or replace the user's desktop icons; and
- revisit native shell content only as a separately scoped product architecture,
  not as a packaging detail.

Version 1.0 remains incomplete. This finding does not change version `0.9.0`.

## Evidence boundary and runtime discovery

The development container used for this investigation is not a graphical Zorin
session: `gnome-shell` and `gnome-extensions` are absent, and
`XDG_CURRENT_DESKTOP` and `XDG_SESSION_TYPE` are empty. It therefore cannot
truthfully report the target computer's exact Shell or extension versions.
Run the read-only collector from a terminal **inside the target graphical
session**:

```bash
./scripts/collect-gnome-info.sh
```

It reports Shell/session facts and enabled extensions, then checks common DING
identifiers. It neither installs nor enables anything. Preserve its output with
`./scripts/collect-gnome-info.sh | tee gnome-info.txt`.

Do not infer the GNOME API solely from the Zorin release name. The exact
`gnome-shell --version` output and the installed extension's `metadata.json` are
the compatibility inputs. GNOME's public extension guide also requires declaring
compatible Shell versions in `metadata.json`; the JavaScript module format changed
at GNOME 45, making the installed major version especially important.

Authoritative references:

- [GNOME Shell extension anatomy and `metadata.json`](https://gjs.guide/extensions/development/creating.html)
- [GNOME 45 extension porting guide](https://gjs.guide/extensions/upgrading/gnome-shell-45.html)
- [Mutter `Meta.Window` API](https://gnome.pages.gitlab.gnome.org/mutter/meta/class.Window.html)
- [GNOME Shell `Shell.WindowTracker` API](https://gnome.pages.gitlab.gnome.org/gnome-shell/shell/class.WindowTracker.html)
- [Desktop Icons NG upstream project](https://gitlab.com/rastersoft/desktop-icons-ng)

These URLs identify upstream interfaces; they are not a claim that every API is
stable extension API on every Zorin release.

## Zorin desktop icons

Modern GNOME Shell does not put file icons into its wallpaper actor. On the Zorin
systems relevant to the earlier physical tests, desktop icons are expected to be
provided by a Shell extension derived from **Desktop Icons NG (DING)**. Zorin may
package or rename its build, so this must be confirmed from the target session,
not guessed from appearance. The collector searches enabled extension UUIDs and
their metadata for `ding`, `desktop-icons`, and `Desktop Icons NG`.

DING is both a Shell integration and a separate desktop-icons process. Its
windows are compositor-managed client surfaces; its extension coordinates such
things as monitor geometry, work areas, visibility, and shell behavior. Those
surfaces are not children of the wallpaper actor and do not expose a supported
third-party insertion point beneath their icon widgets.

Another icon extension would require a fresh compatibility investigation. This
project must not depend on a provider merely being enabled before or after a
GrayHaired extension: GNOME extension enable order is not a supported stacking
contract, and there is no safe `metadata.json` dependency mechanism that grants
ownership of another extension's private actors or windows.

## How GNOME Shell represents the desktop

GNOME Shell/Mutter composes several different kinds of objects:

1. Shell-owned background actors represent wallpaper for each monitor.
2. Wayland/X11 application surfaces are represented by `Meta.Window` and a
   corresponding window actor in Shell's window group.
3. Shell chrome—panel, overview, menus, and extension actors—uses Shell-owned
   actor groups with layout/chrome policy.
4. DING supplies separate desktop-icon client surfaces coordinated by its own
   extension.

The important boundary is that a Qt top-level is a compositor client surface,
not a child that can be reparented into the background actor hierarchy. Moving a
window actor in Clutter does not turn the underlying Wayland surface into a Shell
background actor or establish a durable layer between arbitrary DING surfaces.

## Existing-window identification

The Python application can expose several hints, but none creates a security or
stacking capability:

| Identifier | Usefulness | Limitation |
| --- | --- | --- |
| Wayland application ID | Best candidate when explicitly set before the first window | Must be verified in Looking Glass; toolkit/backend and packaging can affect it. |
| X11 `WM_CLASS` | Useful on native X11 | Not a Wayland identity contract; XWayland differs from native Wayland. |
| `_GTK_APPLICATION_ID` / `Meta.Window.get_gtk_application_id()` | Strong for GTK applications | A PySide6 application should not assume that GTK-specific property is populated. |
| title | Available on both backends | User-visible, mutable, localizable, and collision-prone; never sufficient alone. |
| PID | Useful for diagnostics | Changes each launch and is unsafe as persistent identity. |

If a future experiment is approved, use an explicitly configured reverse-DNS Qt
application/desktop-file ID as the primary match, verify it through
`Meta.Window`, and require a second project-specific property where the backend
supports one. Never manage a window based only on its title or broad `WM_CLASS`.
The current source sets Qt application and organization metadata but does not yet
promise a compositor-visible Wayland application ID, so changing identification
belongs in an experiment with target-system observation.

## Why lowering a PySide6 window is not sufficient

A Shell extension can observe `global.display` window creation and can inspect a
`Meta.Window`. Mutter also exposes operations related to workspace placement and
stacking. This makes a short demonstration plausible, but not the required
product behavior:

- Wayland deliberately gives an ordinary client no global stacking authority.
  Code running in Shell is privileged, but calling a Mutter operation from an
  extension does not create a new supported layer role for that client.
- "Below normal windows" is not the same as "above every background and below
  every DING surface." Restacking is affected by focus, map/unmap, workspace,
  overview, Show Desktop, DING remapping, monitor changes, and Shell restart.
- Shell window actors are Shell-owned representations. Reparenting or manually
  ordering one through private actor internals is fragile and can disagree with
  Mutter's authoritative window stack.
- DING has no public API promising that a third-party client can be inserted
  immediately below all icon surfaces. Tracking its private windows or actors
  would couple releases and extension lifecycle ordering.
- Making the Qt window sticky or setting skip-taskbar/focus hints may improve
  individual behaviors but cannot satisfy all overview, workspace, focus, and
  Show Desktop invariants.

Accordingly, `window-created` plus `Meta.Window.lower()` (or a private actor
reorder) is rejected as the proposed layering mechanism. It can flicker, lose
ordering, lower beneath the Shell background, or cover icons after either client
remaps. It is not made safe by polling and repeatedly restacking.

## The only structurally correct layering mechanism

A surface guaranteed between Shell wallpaper and desktop icons would need to be
**Shell-owned content** inserted into a Shell-controlled actor group, with an
explicit ordering agreement with the installed icon provider. This is the exact
proposed mechanism if the project later accepts a larger architecture:

1. A version-specific GNOME Shell extension creates one non-reactive/reactive-as-
   needed actor per monitor above the background actors.
2. The desktop-icon provider cooperates through a documented ordering/API so its
   icons remain above those actors.
3. The Python process keeps preferences, shortcuts, Settings, external handoff,
   and logging, communicating through a narrow, authenticated per-user IPC API.
4. Shell renders the live Desktop Website content and sends interaction actions
   to Python, or a supported compositor embedding protocol is introduced.

Step 4 is the blocker. GNOME Shell cannot embed or reparent the existing native
Wayland Qt surface into an actor. Screenshot or screen-capture proxying is not an
interactive content surface and would add portal permission, latency, damage,
input, accessibility, focus, and security problems. GNOME Shell does not provide
a supported general web-content actor equivalent to the current QtWebEngine
widget. Rendering the Desktop Website in Shell would therefore require a
substantial JavaScript/native redesign and would put network content in or near
the privileged Shell process. That is not a thin integration and is not
recommended for this application.

## Behavior checklist

| Requirement | Lowered Qt client | Shell-owned actor with provider cooperation |
| --- | --- | --- |
| Below normal applications | Sometimes; compositor operation is possible | Yes, by actor-group design |
| Below real DING icons | No stable public contract | Only with explicit provider cooperation |
| Below panel/dock/menus | Usually, but not a complete guarantee | Yes, through Shell chrome ordering |
| Interactive Desktop Website | Yes | Not without reimplementing/embedding content |
| Overview | Window may appear, animate, or be hidden unexpectedly | Must be explicitly integrated and version-tested |
| Show Desktop | Client may be hidden with ordinary windows | Can remain, if Shell policy is implemented |
| Workspaces | Stickiness is possible, semantics remain version-sensitive | Extension must define per-workspace behavior |
| No focus stealing | Hints and extension handling can reduce it | Actor input/focus must be designed carefully |
| Login/logout safety | Extension failure can affect Shell session | Must be fail-closed and thoroughly tested |
| Wayland security intact | Yes only because privileged Shell code acts | Yes, but extension itself becomes trusted code |

## Lifecycle and prototype shape (if investigation resumes)

The smallest responsible experiment would be a **manual, development-only**
extension, never installed by application startup:

```text
~/.local/share/gnome-shell/extensions/
  grayhaired-desktop-layer@grayhaired.tech/
    metadata.json
    extension.js
```

Its `metadata.json` must use the exact target UUID and explicitly tested Shell
major versions; versions before 45 need the legacy extension format, while 45+
uses ES modules. `enable()` would connect a `window-created` signal, inspect
existing windows, and attach only project-owned signal handlers. `disable()`
must disconnect everything and undo all changes it made without killing the
application. Logging must use a narrow prefix and contain no Desktop Website
content.

The experiment would test identification and document observed stack behavior;
it must not claim a supported Desktop Mode. It would need a matrix covering:

- native Wayland and native X11 sessions;
- every supported Zorin/Shell/DING combination;
- enable/disable while the application is running and while it is stopped;
- application and icon-provider restarts/remaps;
- overview enter/exit, Show Desktop, lock/unlock, workspace switching, and
  login/logout;
- focus, pointer, keyboard, drag-and-drop, accessibility, and external handoff;
- one and multiple monitors, hot-plug, scale factors, rotations, and primary
  monitor changes.

No prototype is included now because upstream interfaces do not prove the needed
DING-relative invariant. Shipping code that only calls a lowering API would fake
success rather than prove the architecture.

## Installation, update, removal, and security

A future extension must remain a separate, explicit per-user install. Normal
application startup must never write into the extension directory, enable an
extension, restart Shell, or change DING. Installation would copy a reviewed
version into the user's extension directory and require the user to enable it.
Updates must be pinned to tested Shell majors. Removal must disable it first and
remove only its own UUID directory.

GNOME Shell extensions execute inside the desktop shell and have substantially
more authority than an ordinary Wayland client. A bug can destabilize the
session; an extension handling network-rendered content would enlarge the impact.
The design must keep untrusted Desktop Website content out of Shell, use minimal
IPC, validate every message, avoid secrets in logs, and fail back to an ordinary
window. It must not patch Mutter, bypass portals, disable Wayland protections,
run as root, or modify another extension.

## X11 implications

The same Shell-side logic could observe X11 windows, so a proven cooperative
Shell actor architecture might span both backends. The rejected lowering design
is not made reliable by X11: the earlier Qt desktop-type window is obscured by
GNOME's desktop surface, while a visible stays-below normal window covers the
icons. EWMH has no standard layer between the Shell background and DING.

For non-GNOME X11 environments, retain the existing conservative Qt candidate as
a fallback subject to environment-specific testing. Do not use it on GNOME and
do not require Zorin users to change permanently from Wayland.

## Maintenance and Version 1.0 conclusion

A window-lowering extension would be small but unreliable. A correct Shell-owned
implementation would require per-Shell-major maintenance, coordination with the
icon provider, multi-monitor and Shell-state testing, privileged-code security
review, and replacement or proxying of the current content surface. That is a
high and continuing maintenance burden.

The desired GNOME Wayland layering is therefore **not feasible for Version 1.0
with the constraint that the existing PySide6 window remains the live content
surface**. The application can remain a safe normal desktop application on GNOME,
and Version 1.0 planning can continue without claiming Desktop Mode there. Any
future native Shell renderer is a new architecture decision and must pass a
separate feasibility and security review.
