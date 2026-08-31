# Final Help / Instructions Requirements

This file captures user-facing guidance that must be included when GrayHairedDesktop reaches a final install/help-document stage.

## Desktop icon strip behavior

The Wayland design reserves **two complete DING icon columns** to the left of My Desktop. The reserved width adapts to the user's Zorin/DING desktop icon-size setting, but the boundary itself should remain fixed while the child process is running so My Desktop does not wiggle when icons are dragged.

Measured Zorin 18.1 / DING geometry on the Inspiron 3502:

- Tiny: desired width 70 + 8 spacing = 78 px per column -> two columns + 8 px padding = **164 px**
- Small: desired width 90 + 8 spacing = 98 px per column -> two columns + 8 px padding = **204 px**
- Standard: desired width 120 + 8 spacing = 128 px per column -> two columns + 8 px padding = **264 px**
- Large: desired width 130 + 8 spacing = 138 px per column -> two columns + 8 px padding = **284 px**

The final user help should explain this in plain language: users always get room for two vertical columns of desktop icons, and My Desktop starts immediately to the right of that reserved area.

## Why the width must be a real boundary

A diagnostic test showed that Gtk `set_size_request()` acts as a minimum rather than a strict width. In Tiny mode the pane started at 164 px but temporarily expanded to 189 px and later 169 px when icons were dragged toward the right edge; WebKit/My Desktop shrank by the same amount. The final implementation should therefore enforce the reserved two-column width rather than merely requesting it.

## Icon-size changes

The adaptive sizing was physically verified on the Inspiron 3502 for Tiny, Standard, and Large icon settings:

- Tiny -> 164 px
- Standard -> 264 px
- Large -> 284 px

Changing the Zorin desktop icon size and restarting the GrayHaired child caused the strip to resize correctly. Logout/login and two normal reboots also preserved the working layout.

## User-facing help topics to include later

The eventual help/instructions should explain, in simple language:

- what the left desktop-icon area is and why it is there;
- that it always reserves two icon columns;
- how the strip automatically follows the user's Zorin icon size;
- how to change Tiny / Small / Standard / Large desktop icon size;
- that My Desktop occupies the rest of the screen and should not move when icons are rearranged;
- how to drag icons within the two-column area;
- what happens after logout/login and reboot;
- how to reload My Desktop safely for normal page/app updates;
- recovery/uninstall steps and how to restore normal Zorin Desktop Icons;
- that the stock Zorin extension must not run at the same time as the GrayHaired DING/WebKit child;
- basic troubleshooting checks for missing My Desktop, missing icons, or two competing `ding.js` processes.

Keep the final help non-technical first, with an optional troubleshooting section for command-line diagnostics.
