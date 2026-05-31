#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Seed a small dataset
bash "$ROOT/scripts/seed-data.sh" 10 7
# Run a query
bash "$ROOT/bin/gitcmdb.sh" query hosts --env prod --status active >/dev/null || { echo "query failed"; exit 2; }

echo "query test passed"
