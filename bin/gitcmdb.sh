#!/usr/bin/env bash
#
# bin/gitcmdb - Unified Command Line Interface Entrypoint
#
# Description:
#   Primary routing system for GitCMDB. Intercepts arguments, 
#   validates base runtime parameters, and forwards execution strings.
#

set -euo pipefail
IFS=$'\n\t'

# Determine application routing space
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GITCMDB_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

show_usage() {
    cat << EOF
GitCMDB CLI Engine v1.0.0

Usage:
  gitcmdb <command> [arguments]

Core Operational Commands:
  init                           Initialize or reset configuration database schemas
  add <type> <id> [options]      Create an asset record atomically
  update <type> <id> [options]   Mutate keys within an existing asset record
  delete <type> <id>             Safely drop an asset record from tracking state
  get <type> <id>                Read a localized raw asset configuration
  query <type> [options]         Execute structured high-performance text-pipeline queries
  history <type> <id>            Trace cryptographic ledger state logs for an asset
  validate                       Run strict JSON-schema compliance check on datasets

Global Options:
  -h, --help                     Display this core interface map

Examples:
  gitcmdb add host srv-01 --env prod --region us-east-1
  gitcmdb query hosts --env prod --status active
EOF
}

# Fast-fail for invocation without commands
if (( $# < 1 )); then
    show_usage
    exit 1
fi

# Intercept core help strings
case "$1" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
esac

# Capture primary instruction block
readonly COMMAND="$1"
shift # Advance argument array stack

case "$COMMAND" in
    init)
        exec "${GITCMDB_ROOT}/bin/gitcmdb-init" "$@"
        ;;
    
    add|update|delete|get)
        if [[ ! -f "${GITCMDB_ROOT}/lib/store.sh" ]]; then
            echo "[ERROR] Storage engine component (lib/store.sh) is missing." >&2
            exit 1
        fi
        # Source store logic or execute it as a script wrapper
        # Senior Tip: Executing individual tasks isolates sub-shell environments cleanly
        exec bash "${GITCMDB_ROOT}/lib/store.sh" "$COMMAND" "$@"
        ;;
    
    query)
        if [[ ! -f "${GITCMDB_ROOT}/lib/query.sh" ]]; then
            echo "[ERROR] Text-processing query pipeline engine (lib/query.sh) is missing." >&2
            exit 1
        fi
        exec bash "${GITCMDB_ROOT}/lib/query.sh" "$@"
        ;;
    
    history)
        if [[ ! -f "${GITCMDB_ROOT}/lib/txn.sh" ]]; then
            echo "[ERROR] Transaction and history manager (lib/txn.sh) is missing." >&2
            exit 1
        fi
        exec bash "${GITCMDB_ROOT}/lib/txn.sh" "history" "$@"
        ;;
        
    validate)
        if [[ ! -f "${GITCMDB_ROOT}/lib/validate.sh" ]]; then
            echo "[ERROR] Schema validation worker engine (lib/validate.sh) is missing." >&2
            exit 1
        fi
        exec bash "${GITCMDB_ROOT}/lib/validate.sh" "$@"
        ;;
    
    *)
        echo -e "\033[0;31m[ERROR] Unknown command configuration state string: '$COMMAND'\033[0m" >&2
        echo "Run 'gitcmdb --help' to review valid operations layout map." >&2
        exit 1
        ;;
esac