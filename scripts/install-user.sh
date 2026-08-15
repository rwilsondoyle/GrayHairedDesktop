#!/usr/bin/env bash
set -euo pipefail

PRODUCT="GrayHaired Desktop"
OWNER_MARKER="Managed-By=GrayHaired-Desktop-user-installer"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
BIN_HOME=${XDG_BIN_HOME:-"$HOME/.local/bin"}
APP_ROOT="$DATA_HOME/grayhaired-desktop"
APPLICATIONS_DIR="$DATA_HOME/applications"
LAUNCHER="$BIN_HOME/grayhaired-desktop"
DESKTOP_FILE="$APPLICATIONS_DIR/grayhaired-desktop.desktop"
PYTHON=${PYTHON:-python3}

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
owned_file() { [ ! -e "$1" ] || grep -Fq "$OWNER_MARKER" "$1" 2>/dev/null; }

"$PYTHON" -c 'import sys; raise SystemExit(sys.version_info < (3, 12))' \
  || fail "Python 3.12 or newer is required (set PYTHON to its executable)."
"$PYTHON" -m venv --help >/dev/null 2>&1 \
  || fail "Python venv support is required."
[ -f "$SOURCE_ROOT/pyproject.toml" ] || fail "Run this script from a complete GrayHaired Desktop source release."
if [ -e "$APP_ROOT" ] && [ ! -f "$APP_ROOT/.grayhaired-desktop-install" ]; then
  fail "$APP_ROOT exists and is not owned by $PRODUCT."
fi
owned_file "$LAUNCHER" || fail "$LAUNCHER exists and is not owned by $PRODUCT."
owned_file "$DESKTOP_FILE" || fail "$DESKTOP_FILE exists and is not owned by $PRODUCT."

mkdir -p "$DATA_HOME" "$BIN_HOME" "$APPLICATIONS_DIR"
BACKUP=""
if [ -d "$APP_ROOT" ]; then
  BACKUP="$DATA_HOME/.grayhaired-desktop-previous.$$"
  mv "$APP_ROOT" "$BACKUP"
fi

restore_previous_install() {
  local status=$?
  trap - EXIT
  rm -rf "$APP_ROOT"
  if [ -n "$BACKUP" ] && [ -d "$BACKUP" ]; then
    mv "$BACKUP" "$APP_ROOT"
    printf 'Previous GrayHaired Desktop runtime restored after install failure.\n' >&2
  fi
  exit "$status"
}
trap restore_previous_install EXIT

# A venv embeds absolute interpreter paths in generated console-script shebangs.
# It must be created and populated at its permanent path; never relocate it.
mkdir -p "$APP_ROOT"
printf '%s\n' "$OWNER_MARKER" > "$APP_ROOT/.grayhaired-desktop-install"
"$PYTHON" -m venv "$APP_ROOT/venv"
# GRAYHAIRED_INSTALL_PIP_ARGS is intended for isolated automated tests only.
# shellcheck disable=SC2086
"$APP_ROOT/venv/bin/python" -m pip install ${GRAYHAIRED_INSTALL_PIP_ARGS:-} "$SOURCE_ROOT"
"$APP_ROOT/venv/bin/python" -c 'import grayhaired_desktop'

cat > "$LAUNCHER" <<EOF_LAUNCHER
#!/usr/bin/env bash
# $OWNER_MARKER
export GRAYHAIRED_DESKTOP_LAUNCHER="$LAUNCHER"
exec "$APP_ROOT/venv/bin/grayhaired-desktop" "\$@"
EOF_LAUNCHER
chmod 0755 "$LAUNCHER"

sed "s|@EXEC@|$LAUNCHER|g" "$SOURCE_ROOT/resources/grayhaired-desktop.desktop.in" > "$DESKTOP_FILE"
chmod 0644 "$DESKTOP_FILE"

trap - EXIT
rm -rf "$BACKUP"
printf '%s installed.\nLauncher: %s\nApplication menu: %s\n' "$PRODUCT" "$LAUNCHER" "$DESKTOP_FILE"
