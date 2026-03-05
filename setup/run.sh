#!/usr/bin/env bash
set -euo pipefail

# Go to repo root (parent of /setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Pick python
if command -v python3 >/dev/null 2>&1; then
  PYBIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYBIN="python"
else
  echo "ERROR: Python not found. Install Python 3.x and try again."
  exit 1
fi

# Create venv at repo root
if [ ! -d ".venv" ]; then
  "$PYBIN" -m venv .venv
  echo "Created virtual environment: $REPO_ROOT/.venv"
else
  echo "Virtual environment already exists: $REPO_ROOT/.venv"
fi

# ✅ Activate venv in this script session
# shellcheck disable=SC1091
source ".venv/bin/activate"

# Sanity checks (venv is "running")
if [ -z "${VIRTUAL_ENV:-}" ]; then
  echo "ERROR: venv activation failed (VIRTUAL_ENV not set)."
  exit 1
fi
PY_PATH="$(command -v python)"
if [[ "$PY_PATH" != *"/.venv/"* ]]; then
  echo "ERROR: Not using venv python. Current python: $PY_PATH"
  exit 1
fi

# Upgrade tooling inside venv
python -m pip install --upgrade pip setuptools wheel

# Install deps inside venv
if [ -f "requirements.txt" ]; then
  python -m pip install -r requirements.txt
  echo "Installed dependencies from requirements.txt"
elif [ -f "pyproject.toml" ]; then
  python -m pip install -e .
  echo "Installed project from pyproject.toml (editable)"
else
  echo "WARNING: No requirements.txt or pyproject.toml found. Nothing to install."
fi

echo ""
echo "Done."
