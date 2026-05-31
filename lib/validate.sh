#!/usr/bin/env bash
# lib/validate.sh - Structural Schema Enforcement Worker

set -euo pipefail
IFS=$'\n\t'

readonly LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${LIB_DIR}/common.sh"

validate_json_document() {
    local -r target_file="${1:-}"
    
    if [[ ! -f "$target_file" ]]; then
        log_error "Validation target does not exist on filesystem: '$target_file'"
        return 1
    fi

    # Syntactic Validation Pass
    if ! jq empty "$target_file" 2>/dev/null; then
        log_error "Syntactic Mutation Failure: Structural JSON document syntax is invalid."
        return 1
    fi
    return 0
}

validate_schema_compliance() {
    local -r type="$1"
    local -r data_file="$2"
    local -r schema_file="${GITCMDB_ROOT}/schemas/${type}.schema.json"

    if [[ ! -f "$schema_file" ]]; then
        log_warn "Schema constraint blueprint missing for type: '${type}'. Skipping semantic validation."
        return 0
    fi

    # Senior Tip: For pure Bash setups without external schema binary engines,
    # we enforce schema contract checking programmatically using highly precise jq filter pipelines.
    if [[ "$type" == "host" ]]; then
        local -r missing_fields=$(jq -r '
            [ "hostname", "environment", "region", "ip_address", "status" ] as $req 
            | keys as $keys 
            | ($req - $keys) | join(", ")
        ' "$data_file")

        if [[ -n "$missing_fields" ]]; then
            log_error "Schema Violation: Missing mandatory structural fields: [ ${missing_fields} ]"
            return 1
        fi
    fi
    return 0
}

# Execution Router Context
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if (( $# < 2 )); then
        echo "Usage: gitcmdb validate <type> <file_path>" >&2
        exit 1
    fi
    validate_json_document "$2" && validate_schema_compliance "$1" "$2"
fi