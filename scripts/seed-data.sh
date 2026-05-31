#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="$ROOT/data/prod/us-east-1/hosts"
mkdir -p "$TARGET_DIR"

COUNT=${1:-100}
SEED=${2:-42}

for i in $(seq 1 "$COUNT"); do
  printf -v id "srv-%03d" "$i"
  # simple deterministic pseudo-random using awk with seed
  rand=$(awk -v s="$SEED" -v i="$i" 'BEGIN { srand(s+i); print int(rand()*10000) }')
  roles=(api web worker database cache)
  statuses=(active provisioning maintenance vulnerable)
  role=${roles[$((rand % ${#roles[@]}))]}
  status=${statuses[$((rand % ${#statuses[@]}))]}
  ip="10.10.$((rand % 250)).$(((rand/7) % 250))"
  kernel="5.$((rand % 10)).$(((rand/13) % 10))"
  owner="owner$((rand % 10 + 1))@example.com"
  cat > "$TARGET_DIR/${id}.json" <<EOF
{
  "hostname": "$id",
  "environment": "prod",
  "region": "us-east-1",
  "role": "$role",
  "ip_address": "$ip",
  "status": "$status",
  "kernel": "$kernel",
  "owner": "$owner",
  "tags": ["linux","auto-seed"]
}
EOF
done

echo "Seeded $COUNT host records in $TARGET_DIR"