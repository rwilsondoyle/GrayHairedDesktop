#!/usr/bin/env bash
set -Eeuo pipefail

# This setup script prepares GrayHaired Desktop on Zorin OS or Ubuntu.
# It is safe to run again when you want to repair or refresh the install.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "Error: $*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  echo "Error: setup failed. Please review the message above, fix the problem, and run ./scripts/setup-zorin.sh again." >&2
  exit "${exit_code}"
}
trap on_error ERR

cd "${REPO_ROOT}"

# Make sure this script is running from a GrayHaired Desktop checkout.
[[ -f "pyproject.toml" ]] || fail "Run this script from the GrayHaired Desktop repository. pyproject.toml was not found."
[[ -d "src/grayhaired_desktop" ]] || fail "Run this script from the GrayHaired Desktop repository. src/grayhaired_desktop was not found."

# Python 3.12 or newer is required by the application.
PYTHON_BIN=""
if command -v python3.12 >/dev/null 2>&1; then
  PYTHON_BIN="python3.12"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
else
  fail "Python 3.12 or newer is required. Please install Python 3.12 and run this script again."
fi

"${PYTHON_BIN}" - <<'PY' || fail "Python 3.12 or newer is required. Please install or select a newer Python version."
import sys
raise SystemExit(0 if sys.version_info >= (3, 12) else 1)
PY

# Install only the operating system packages that are missing.
REQUIRED_PACKAGES=(python3-venv python3-pip libxcb-cursor0)
MISSING_PACKAGES=()
for package in "${REQUIRED_PACKAGES[@]}"; do
  if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep -q "install ok installed"; then
    MISSING_PACKAGES+=("${package}")
  fi
done

if (( ${#MISSING_PACKAGES[@]} > 0 )); then
  command -v apt-get >/dev/null 2>&1 || fail "apt-get was not found. Please install these packages manually: ${MISSING_PACKAGES[*]}"
  echo "Installing required Zorin/Ubuntu packages: ${MISSING_PACKAGES[*]}"
  sudo apt-get update
  sudo apt-get install -y "${MISSING_PACKAGES[@]}"
else
  echo "Required Zorin/Ubuntu packages are already installed."
fi

# Create the virtual environment once, then reuse it on later runs.
if [[ ! -d ".venv" ]]; then
  "${PYTHON_BIN}" -m venv .venv
else
  echo "Using existing .venv virtual environment."
fi

# Activate the virtual environment so pip installs into this project only.
# shellcheck disable=SC1091
source ".venv/bin/activate"
python -m pip install --upgrade pip
python -m pip install -e .

echo
echo "Success: GrayHaired Desktop is set up."
echo "Next, start the app with: ./scripts/run.sh"
