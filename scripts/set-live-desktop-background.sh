#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/grayhaired-live-desktop"
CONFIG_FILE="$CONFIG_DIR/background.json"

usage() {
    cat <<'EOF'
Usage:
  bash scripts/set-live-desktop-background.sh automatic
  bash scripts/set-live-desktop-background.sh gunmetal
  bash scripts/set-live-desktop-background.sh charcoal
  bash scripts/set-live-desktop-background.sh slate
  bash scripts/set-live-desktop-background.sh navy
  bash scripts/set-live-desktop-background.sh black
  bash scripts/set-live-desktop-background.sh '#41464C'
EOF
}

value="${1:-}"
[[ -n "$value" ]] || {
    usage
    exit 2
}

mode="manual"
case "${value,,}" in
    automatic|auto)
        mode="automatic"
        color="#41464C"
        ;;
    gunmetal)
        color="#41464C"
        ;;
    charcoal)
        color="#303030"
        ;;
    slate)
        color="#4A5568"
        ;;
    navy|dark-blue|darkblue)
        color="#243447"
        ;;
    black)
        color="#000000"
        ;;
    *)
        if [[ "$value" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
            color="${value^^}"
        else
            echo "Unsupported background choice: $value" >&2
            usage
            exit 2
        fi
        ;;
esac

mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<EOF
{
  "mode": "$mode",
  "color": "$color"
}
EOF

printf '[GRAYHAIRED-MANUAL17] Saved mode=%s color=%s\n' "$mode" "$color"
printf '[GRAYHAIRED-MANUAL17] Config: %s\n' "$CONFIG_FILE"
printf '[GRAYHAIRED-MANUAL17] Reload only the GrayHaired child with:\n'
printf '  bash %s/GrayHairedDesktop/scripts/reload-grayhaired.sh\n' "$HOME"
