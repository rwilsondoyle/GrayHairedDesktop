#!/usr/bin/env bash
set -Eeuo pipefail

# This run script starts My Desktop from the project's virtual environment.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "Error: $*" >&2
  exit 1
}

cd "${REPO_ROOT}"

[[ -d ".venv" ]] || fail ".venv was not found. Run ./scripts/setup-zorin.sh first."

# Activate the virtual environment so the installed grayhaired-desktop command is used.
# shellcheck disable=SC1091
source ".venv/bin/activate"

# exec hands control to the app, preserving normal Ctrl+C behavior.
exec grayhaired-desktop
