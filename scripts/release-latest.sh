#!/usr/bin/env bash
set -euo pipefail

# Fetch latest pgcli from PyPI, update requirements, and run full release.
# Usage: ./scripts/release-latest.sh [--dry-run]

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

dry_run=false
[[ "${1:-}" == "--dry-run" ]] && dry_run=true

echo "Fetching latest pgcli version from PyPI..."
latest=$(curl -s https://pypi.org/pypi/pgcli/json | python3 -c "import sys,json; print(json.load(sys.stdin)['info']['version'])")
echo "Latest pgcli: $latest"

current=$(grep -E '^pgcli==' requirements.in | sed 's/pgcli==//')
echo "Current in requirements.in: ${current:-none}"

if [[ "$latest" == "$current" ]]; then
  echo "Already at latest. Use VERSION=${latest}-r2 to rebuild same version."
  exit 0
fi

if $dry_run; then
  echo "[dry-run] Would update requirements.in to pgcli==$latest"
  echo "[dry-run] Would run: make update"
  echo "[dry-run] Would run: make release IMAGE=\"\${IMAGE:-ghcr.io/tholst/pgcli}\" VERSION=\"$latest\""
  exit 0
fi

echo "Updating requirements.in to pgcli==$latest..."
if [[ "$(uname)" == Darwin ]]; then
  sed -i '' "s/^pgcli==.*/pgcli==$latest/" requirements.in
else
  sed -i "s/^pgcli==.*/pgcli==$latest/" requirements.in
fi

echo "Regenerating requirements.lock..."
make update

echo "Building and publishing ghcr.io/tholst/pgcli:$latest..."
make release IMAGE="${IMAGE:-ghcr.io/tholst/pgcli}" VERSION="$latest"
