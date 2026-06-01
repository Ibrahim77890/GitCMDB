#!/usr/bin/env bash
#
# bin/gitcmdb-init - Workspace Initialization Engine
#
# Description:
#   Initializes or repairs the structured directory layouts, builds
#   default schemas, and ensures the Git ledger is synchronized.
#

set -euo pipefail
IFS=$'\n\t'

# Resolve root directory relative to script position for portability
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
GITCMDB_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly GITCMDB_ROOT

# Source common utilities for unified logging
if [[ -f "${GITCMDB_ROOT}/lib/common.sh" ]]; then
  source "${GITCMDB_ROOT}/lib/common.sh"
else
  # Fallback inline logging if lib/common.sh isn't built yet
  log_info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
  log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }
  log_error() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }
fi

seed_base_schemas() {
  log_info "Writing core object JSON structural schemas..."

  # Generate host schema contract
  cat << 'EOF' > "${GITCMDB_ROOT}/schemas/host.schema.json"
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Host",
  "type": "object",
  "properties": {
    "hostname": { "type": "string", "pattern": "^[a-zA-Z0-9.-]+$" },
    "environment": { "type": "string", "enum": ["prod", "staging", "dev"] },
    "region": { "type": "string" },
    "role": { "type": "string" },
    "ip_address": { "type": "string", "format": "ipv4" },
    "status": { "type": "string", "enum": ["active", "provisioning", "decommissioned", "vulnerable"] },
    "kernel": { "type": "string" },
    "owner": { "type": "string" },
    "tags": { "type": "array", "items": { "type": "string" } }
  },
  "required": ["hostname", "environment", "region", "ip_address", "status"]
}
EOF

  # Generate basic service schema contract
  cat << 'EOF' > "${GITCMDB_ROOT}/schemas/service.schema.json"
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Service",
  "type": "object",
  "properties": {
    "service_name": { "type": "string" },
    "environment": { "type": "string" },
    "tier": { "type": "string", "enum": ["frontend", "backend", "database", "cache"] },
    "owner": { "type": "string" },
    "port": { "type": "integer" }
  },
  "required": ["service_name", "environment", "tier"]
}
EOF

  chmod 644 "${GITCMDB_ROOT}/schemas/"*.json
  log_success "Database schemas written to disk."
}

sync_git_ledger() {
  log_info "Synchronizing tracking ledger..."
  if [[ -d "${GITCMDB_ROOT}/.git" ]]; then
    pushd "${GITCMDB_ROOT}" &> /dev/null
    git add schemas/*.json
    if ! git diff-index --quiet HEAD --; then
      git commit -m "add(schemas): baseline system validation definitions"
      log_success "Ledger updated with initialization schemas."
    else
      log_info "Ledger is already up to date."
    fi
    popd &> /dev/null
  fi
}

main() {
  log_info "Beginning GitCMDB initialization sequence..."

  # Ensure system directories are sound
  mkdir -p "${GITCMDB_ROOT}"/{bin,lib,schemas,data,docs,scripts,tests}

  seed_base_schemas
  sync_git_ledger

  log_success "Workspace initialization successfully verified."
}

main "$@"
