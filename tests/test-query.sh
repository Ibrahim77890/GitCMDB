#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export GITCMDB_ROOT="$ROOT"

# Seed a small dataset
echo "[*] Seeding test data..."
bash "$ROOT/scripts/seed-data.sh" 10 7

# Verify data exists
if ! ls "$ROOT/data/prod/us-east-1/hosts/"*.json &> /dev/null; then
  echo "[ERROR] No host records found in data directory"
  exit 2
fi

# Run a query with diagnostic output on failure
echo "[*] Executing query test..."
if ! bash "$ROOT/bin/gitcmdb.sh" query hosts --env prod --status active 2>&1 | grep -q .; then
  echo "[ERROR] Query produced no output"
  echo "[DEBUG] Attempting diagnostic query..."
  GITCMDB_ROOT="$ROOT" bash "$ROOT/lib/query.sh" hosts --env prod 2>&1 || true
  exit 2
fi

echo "query test passed"
