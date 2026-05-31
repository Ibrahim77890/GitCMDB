#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# Create a host via store.sh
bash "$ROOT/lib/store.sh" add host srv-test --env prod --region us-east-1 --ip_address 10.10.99.99 --status active --role api --kernel 5.10.1 --owner test@example.com || { echo "write failed"; exit 2; }
# Read it back
if ! jq '.' "$ROOT/data/prod/us-east-1/hosts/srv-test.json" >/dev/null; then
  echo "readback failed"; exit 3
fi

echo "write test passed"
