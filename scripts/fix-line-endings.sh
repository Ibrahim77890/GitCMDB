#!/usr/bin/env bash
# Fix line endings for all bash scripts (convert CRLF to LF)

set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"

echo "[*] Converting line endings from CRLF to LF..."

for f in bin/gitcmdb bin/gitcmdb.sh bin/gitcmdb-init.sh lib/*.sh scripts/*.sh tests/*.sh install.sh; do
  if [ -f "$f" ]; then
    sed -i 's/\r$//' "$f"
    echo "  ✓ $f"
  fi
done

echo "[+] Done! All bash scripts converted to Unix line endings."
echo "[+] You can now run: make fmt && make lint && make test"
