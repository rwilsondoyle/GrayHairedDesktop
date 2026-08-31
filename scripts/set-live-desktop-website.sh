#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/grayhaired-live-desktop"
CONFIG_FILE="$CONFIG_DIR/site.json"

usage() {
    cat <<'EOF'
Usage:
  bash scripts/set-live-desktop-website.sh desktop-c
  bash scripts/set-live-desktop-website.sh desktop-d
  bash scripts/set-live-desktop-website.sh msn
  bash scripts/set-live-desktop-website.sh duckduckgo
  bash scripts/set-live-desktop-website.sh https://example.com/
EOF
}

value="${1:-}"
[[ -n "$value" ]] || { usage; exit 2; }

case "$value" in
    desktop-c)
        url="https://grayhaired.tech/desktop-c"
        label="GrayHaired Desktop C"
        ;;
    desktop-d)
        url="https://grayhaired.tech/desktop-d"
        label="GrayHaired Desktop D"
        ;;
    msn)
        url="https://www.msn.com/"
        label="MSN"
        ;;
    duckduckgo)
        url="https://duckduckgo.com/"
        label="DuckDuckGo"
        ;;
    http://*|https://*)
        url="$value"
        label="Custom Website"
        ;;
    *)
        echo "Website must be one of the named presets or start with http:// or https://." >&2
        usage
        exit 2
        ;;
esac

mkdir -p "$CONFIG_DIR"
python3 - "$CONFIG_FILE" "$url" "$label" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
url = sys.argv[2]
label = sys.argv[3]
payload = {
    "url": url,
    "label": label,
}
path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(f"[GRAYHAIRED-SITE21] saved {label}: {url}")
PY
