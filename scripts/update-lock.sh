#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

python3 -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip pip-tools
pip-compile \
  --generate-hashes \
  --resolver=backtracking \
  --strip-extras \
  --rebuild \
  --output-file=requirements.lock \
  requirements.in

echo "Updated requirements.lock from requirements.in"
