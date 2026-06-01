#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Basic smoke test: ensure install script exits 0
bash "$ROOT/install.sh" || {
  echo "install.sh failed"
  exit 2
}
# Ensure schemas directory exists
if [[ ! -d "$ROOT/schemas" ]]; then
  echo "schemas missing"
  exit 3
fi

echo "install smoke test passed"
