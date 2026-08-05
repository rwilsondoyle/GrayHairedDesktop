#!/usr/bin/env bash
set -Eeuo pipefail

# This update script pulls the latest code and refreshes the local install.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

fail() {
  echo "Error: $*" >&2
  exit 1
}

on_error() {
  local exit_code=$?
  echo "Error: update failed. Please review the message above and try again." >&2
  exit "${exit_code}"
}
trap on_error ERR

cd "${REPO_ROOT}"

# Make sure this is a Git checkout before changing anything.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Run this script from inside a Git repository."

# Local edits, staged changes, or untracked files could be overwritten by an update,
# so stop and let the user decide first.
if [[ -n "$(git status --porcelain)" ]]; then
  fail "Uncommitted local changes were found. Commit, stash, or discard them before updating."
fi

git pull --ff-only

[[ -d ".venv" ]] || fail ".venv was not found. Run ./scripts/setup-zorin.sh first."

# Activate the existing virtual environment and reinstall the project.
# shellcheck disable=SC1091
source ".venv/bin/activate"
python -m pip install -e .

echo
echo "Success: GrayHaired Desktop is updated."
