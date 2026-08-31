#!/usr/bin/env bash
set -euo pipefail

BIN="$HOME/.local/bin/grayhaired-desktop-items"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
[[ -n "$DESKTOP_DIR" ]] || DESKTOP_DIR="$HOME/Desktop"
TRIGGER="$DESKTOP_DIR/More Desktop Items.desktop"
BACKUP="$TRIGGER.pre-grayhaired-stage13c"

fail() {
    printf '[GRAYHAIRED-DRAWER13C] FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf '[GRAYHAIRED-DRAWER13C] PASS: %s\n' "$*"
}

[[ -x "$BIN" ]] || fail "Stage 13 drawer is not installed: $BIN"
mkdir -p "$DESKTOP_DIR"

if [[ -e "$TRIGGER" && ! -e "$BACKUP" ]]; then
    cp -a "$TRIGGER" "$BACKUP"
    pass "saved existing desktop shortcut: $BACKUP"
fi

cat > "$TRIGGER" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=More Desktop Items
Comment=Show all items in the Desktop folder
Exec=$BIN
Icon=user-desktop
Terminal=false
StartupNotify=true
Categories=Utility;
X-GrayHaired-Stage=13C
EOF

chmod 0755 "$TRIGGER"

# DING honors executable launchers. Mark trusted as well when GIO metadata is
# available; failure here is non-fatal because executable launchers still work.
if command -v gio >/dev/null 2>&1; then
    gio set "$TRIGGER" metadata::trusted true >/dev/null 2>&1 || true
fi

[[ -x "$TRIGGER" ]] || fail "desktop trigger was not created as executable"
grep -Fq 'Name=More Desktop Items' "$TRIGGER" || fail "desktop trigger Name is missing"
grep -Fq "Exec=$BIN" "$TRIGGER" || fail "desktop trigger Exec is incorrect"
grep -Fq 'X-GrayHaired-Stage=13C' "$TRIGGER" || fail "Stage 13C marker missing"

pass "Stage 13C native desktop trigger installed"
printf '[GRAYHAIRED-DRAWER13C] INFO: %s\n' "shortcut: $TRIGGER"
printf '[GRAYHAIRED-DRAWER13C] INFO: %s\n' "No GrayHaired reload is required; DING should notice the new Desktop item automatically."
printf '[GRAYHAIRED-DRAWER13C] INFO: %s\n' "For the first test, use Tiny or Small icons and drag More Desktop Items near the top of the left pane, then switch to Large."
