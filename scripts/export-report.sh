#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT=${1:-"report.md"}

cat > "$OUT" << EOF
# GitCMDB Report

Generated on: $(date --utc)

## Hosts summary

| Region | Count |
|--------|-------|
EOF

find "$ROOT/data" -name '*.json' -print0 2> /dev/null | xargs -0 jq -r '.region' 2> /dev/null | sort | uniq -c | while read -r cnt region; do
  region=$(echo "$region" | xargs)
  echo "| $region | $cnt |" >> "$OUT"
done

echo "Report written to $OUT"
