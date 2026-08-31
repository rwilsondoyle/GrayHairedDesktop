# Feature Plan: Automatic Blend for the Desktop Icon Panel

## Goal

Make the reserved two-column desktop-icon panel look visually integrated with whatever webpage the user chooses for My Desktop, including arbitrary sites such as Google, MSN, personal sites, dashboards, weather pages, or any other URL.

## Product behavior

Automatic Blend should be the preferred/default appearance mode for the icon panel.

When the My Desktop page finishes loading or is changed/reloaded:

1. Sample a narrow region along the left edge of the rendered webpage locally.
2. Estimate a dominant/background tone from that region.
3. Apply a matching visual treatment to the two-column icon panel.
4. Add a subtle blend/fade at the seam between the icon panel and WebKit surface so the split looks intentional rather than abrupt.
5. Choose readable light/dark icon-label contrast automatically.
6. Recompute only on page load/change/reload, not continuously during normal use.

## Visual strategy

Prefer a robust local effect rather than literal image reproduction:

- flat pages: match the dominant background color closely
- gradient/colorful pages: derive a soft related gradient
- photographic/complex pages: use a blurred or averaged color treatment rather than trying to recreate the full image
- chaotic/dynamic pages, ads, video, or poor samples: fall back to a neutral translucent charcoal/light-gray panel rather than producing an ugly or unstable result

The visual result should feel like the icon area belongs to the chosen webpage, while the webpage itself remains untouched.

## Privacy / implementation principles

- No cloud AI service is required.
- Sampling and color analysis should happen locally on the user's computer.
- Do not send screenshots or webpage imagery to external services.
- Avoid continuous capture or polling.

## User-facing appearance options

Potential settings:

- **Automatic Blend** — recommended/default; locally matches the loaded webpage
- **Dark Panel** — always use a neutral dark icon panel
- **Wallpaper** — preserve the normal desktop wallpaper behind the icon area

A future Light Panel/manual color option may be considered if useful, but keep the initial settings simple.

## Interaction with adaptive icon columns

This feature must preserve the two full adaptive DING icon columns and their fixed reserved boundary at the active icon size. Automatic Blend changes only the appearance of the reserved panel, not its geometry.

Current tested two-column target widths:

- Tiny: 164 px
- Small: 204 px
- Standard: 264 px
- Large: 284 px

The panel must remain stable while icons are rearranged. My Desktop should not horizontally wiggle when an icon is moved inside the reserved two-column area.

## Final help / instructions requirement

The final user help should explain:

- that users may choose virtually any webpage as My Desktop
- Automatic Blend makes the icon panel visually follow that webpage
- matching is performed locally and does not upload screenshots
- Dark Panel and Wallpaper are fallback/manual appearance choices
- Automatic Blend affects appearance only; the two reserved desktop-icon columns remain available for apps, files, folders, and shortcuts

## Priority

Add after the two-column hard-boundary behavior is finalized and verified. It should be treated as a real product feature, not an experimental note.
