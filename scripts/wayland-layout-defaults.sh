#!/usr/bin/env bash
# Known-good Wayland layout defaults for GrayHairedDesktop.
#
# The icon strip is adaptive: it uses DING's own desired icon-cell width at
# runtime and keeps a fixed number of DING columns. These values only control
# the GrayHaired split-surface behavior; they do not modify Zorin's system
# extension or the user's desktop icon-size setting.

GRAYHAIRED_WAYLAND_ICON_COLUMNS=2
GRAYHAIRED_WAYLAND_ICON_STRIP_PADDING=8
GRAYHAIRED_WAYLAND_ICON_STRIP_MIN=160
GRAYHAIRED_WAYLAND_ICON_STRIP_MAX=320
GRAYHAIRED_WAYLAND_ICON_STRIP_FALLBACK=220
GRAYHAIRED_WAYLAND_DESKTOP_URL="https://grayhaired.tech/desktop-d"
