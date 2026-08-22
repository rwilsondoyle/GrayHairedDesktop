#!/usr/bin/env bash
set -euo pipefail

SYSTEM_UUID="zorin-desktop-icons@zorinos.com"
TEST_UUID="grayhaired-live-desktop@grayhaired.tech"
TEST_EXT="$HOME/.local/share/gnome-shell/extensions/$TEST_UUID"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" != "--apply" ]]; then
    cat <<EOF
=== GRAYHAIRED WAYLAND REMOVAL PREVIEW ===

No changes have been made.

First run the read-only recovery preflight:
  bash $SCRIPT_DIR/check-wayland-recovery.sh

Actual removal is intentionally explicit because GNOME extension teardown on
this test environment has shown unrelated Zorin lifecycle problems.

To remove the GrayHaired Wayland prototype after the preflight passes, run:
  bash $SCRIPT_DIR/remove-wayland-separate-ding-prototype.sh --apply

That operation will:
  1. disable $TEST_UUID
  2. wait briefly for its DING/WebKit child to stop
  3. remove only this user-local tree:
       $TEST_EXT
  4. request re-enable of $SYSTEM_UUID

A logout/login may still be the safest way to refresh the GNOME session after
actual removal. A reboot is not required.
EOF
    exit 0
fi

bash "$SCRIPT_DIR/check-wayland-recovery.sh"

echo "=== REMOVE SEPARATE WAYLAND DING PROTOTYPE ==="
echo "Recovery preflight passed. Applying removal."

gnome-extensions disable "$TEST_UUID" >/dev/null 2>&1 || true

for _ in {1..40}; do
    if ! pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' >/dev/null 2>&1; then
        break
    fi
    sleep 0.25
done

if pgrep -f '/grayhaired-live-desktop@grayhaired.tech/app/ding.js' >/dev/null 2>&1; then
    echo "ERROR: GrayHaired DING/WebKit child is still running after disable." >&2
    echo "The extension tree was NOT removed." >&2
    echo "Log out and back in, then run the --apply command again." >&2
    exit 1
fi

if [[ -d "$TEST_EXT" ]]; then
    rm -rf -- "$TEST_EXT"
fi

gnome-extensions enable "$SYSTEM_UUID" >/dev/null 2>&1 || true

cat <<EOF
Removed separate GrayHairedDesktop Wayland prototype:
  $TEST_EXT

Requested re-enable of normal Zorin desktop icons:
  $SYSTEM_UUID

Because this environment has a known GNOME/Zorin extension lifecycle issue,
if the normal icons/taskbar do not return cleanly, use a normal logout/login.
Do not repeatedly hot-toggle extensions. A reboot is not required.
EOF
