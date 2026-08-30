#!/usr/bin/env bash
set -euo pipefail

UUID="grayhaired-live-desktop@grayhaired.tech"
EXT="$HOME/.local/share/gnome-shell/extensions/$UUID"
GRID="$EXT/app/desktopGrid.js"

usage() {
    cat <<'EOF'
Usage:
  bash scripts/set-live-desktop-test-url.sh desktop-c
  bash scripts/set-live-desktop-test-url.sh desktop-d
  bash scripts/set-live-desktop-test-url.sh https://grayhaired.tech/desktop-c
EOF
}

[[ -f "$GRID" ]] || {
    echo "GrayHaired desktopGrid.js not found: $GRID" >&2
    exit 2
}

value="${1:-}"
[[ -n "$value" ]] || {
    usage
    exit 2
}

case "$value" in
    desktop-c|desktop-d)
        target="https://grayhaired.tech/$value"
        ;;
    https://grayhaired.tech/desktop-c|https://grayhaired.tech/desktop-c/)
        target="https://grayhaired.tech/desktop-c"
        ;;
    https://grayhaired.tech/desktop-d|https://grayhaired.tech/desktop-d/)
        target="https://grayhaired.tech/desktop-d"
        ;;
    *)
        echo "For this controlled test, use desktop-c or desktop-d only." >&2
        usage
        exit 2
        ;;
esac

python3 - "$GRID" "$target" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
target = sys.argv[2]
text = path.read_text(encoding="utf-8")

pattern = re.compile(r"https://grayhaired\.tech/desktop-[cd]/?")
matches = pattern.findall(text)
if not matches:
    raise SystemExit("No desktop-c/desktop-d URL references found; refusing to edit unknown file")

updated = pattern.sub(target, text)
path.write_text(updated, encoding="utf-8")
print(f"[GRAYHAIRED-URL] Updated {len(matches)} installed URL reference(s) to {target}")
PY

echo "[GRAYHAIRED-URL] Reload only the GrayHaired child with:"
echo "  bash $HOME/GrayHairedDesktop/scripts/reload-grayhaired.sh"
echo
echo "Note: this is a temporary installed-code test. A clean reinstall restores the configured default."
