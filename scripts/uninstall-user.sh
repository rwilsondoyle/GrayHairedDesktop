#!/usr/bin/env bash
set -euo pipefail
OWNER_MARKER="Managed-By=GrayHaired-Desktop-user-installer"
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
BIN_HOME=${XDG_BIN_HOME:-"$HOME/.local/bin"}
APP_ROOT="$DATA_HOME/grayhaired-desktop"
LAUNCHER="$BIN_HOME/grayhaired-desktop"
DESKTOP_FILE="$DATA_HOME/applications/grayhaired-desktop.desktop"
AUTOSTART_FILE="$CONFIG_HOME/autostart/grayhaired-desktop.desktop"
DESKTOP_DIR=""
if command -v xdg-user-dir >/dev/null 2>&1; then
  DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || true)
fi
case "$DESKTOP_DIR" in
  "$HOME"/*) ;;
  *) DESKTOP_DIR="$HOME/Desktop" ;;
esac

remove_owned_file() {
  local path=$1
  [ ! -e "$path" ] || if grep -Fq "$OWNER_MARKER" "$path" 2>/dev/null; then
    rm -f "$path"
  else
    printf 'Not removing unowned file: %s\n' "$path" >&2
  fi
}
remove_owned_file "$LAUNCHER"
remove_owned_file "$DESKTOP_FILE"
if [ -f "$AUTOSTART_FILE" ] && \
   grep -Eq '^Name=(My Desktop|GrayHaired Desktop)$' "$AUTOSTART_FILE" && \
   grep -Fxq "Exec=$LAUNCHER" "$AUTOSTART_FILE"; then
  rm -f "$AUTOSTART_FILE"
elif [ -e "$AUTOSTART_FILE" ]; then
  printf 'Not removing unrecognized autostart file: %s\n' "$AUTOSTART_FILE" >&2
fi
if [ -d "$APP_ROOT" ]; then
  if [ -f "$APP_ROOT/.grayhaired-desktop-install" ] && grep -Fq "$OWNER_MARKER" "$APP_ROOT/.grayhaired-desktop-install"; then
    rm -rf "$APP_ROOT"
  else
    printf 'Not removing unowned directory: %s\n' "$APP_ROOT" >&2
  fi
fi
if [ -d "$DESKTOP_DIR" ]; then
  for shortcut in "$DESKTOP_DIR"/my-desktop-*.desktop; do
    [ -f "$shortcut" ] || continue
    if grep -Fxq 'X-MyDesktop-Managed=true' "$shortcut" 2>/dev/null; then
      rm -f "$shortcut"
      printf 'Removed My Desktop-managed shortcut: %s\n' "$shortcut"
    fi
  done
fi
printf 'My Desktop user-local installation removed; user preferences were preserved.\n'
