#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SEED_SCRIPT="$ROOT/scripts/seed-data.sh"

COUNT=${1:-1000}

echo "Seeding $COUNT records (if none exist)"
bash "$SEED_SCRIPT" "$COUNT" 42

echo "Running sample queries and measuring durations"
# sample query: count active hosts
ruby -e 'puts "skipping ruby if not needed"' 2> /dev/null || true
# use time measurement with jq and rg
t1=$(date +%s%N)
rg -l '"status": "active"' "$ROOT/data/prod" | xargs -r jq -c '.' > /dev/null 2>&1 || true
t2=$(date +%s%N)
elapsed_ms=$(((t2 - t1) / 1000000))
printf "Active-host scan took %d ms\n" "$elapsed_ms"

# simple aggregation timing
t1=$(date +%s%N)
find "$ROOT/data/prod" -name '*.json' -print0 | xargs -0 jq -r '.region' | sort | uniq -c > /dev/null 2>&1 || true
t2=$(date +%s%N)
elapsed_ms=$(((t2 - t1) / 1000000))
printf "Region aggregation took %d ms\n" "$elapsed_ms"

echo "Benchmark completed"
