#!/usr/bin/env bash
# lib/common.sh - Core System Foundation & Cross-Cutting Utilities

# Prevent multiple evaluations of this common library
[[ -n "${__GITCMDB_COMMON_SH_INCLUDED:-}" ]] && return 0
readonly __GITCMDB_COMMON_SH_INCLUDED=1

# Validate execution environment context
if [[ -z "${GITCMDB_ROOT:-}" ]]; then
    echo -e "\033[0;31m[CRITICAL]\033[0m GITCMDB_ROOT environment variable is unbound." >&2
    exit 1
fi

# Standardized Console Telemetry Sub-Engine
if [[ -t 1 ]]; then
    readonly CLR_INFO="\033[0;34m"
    readonly CLR_SUCCESS="\033[0;32m"
    readonly CLR_WARN="\033[0;33m"
    readonly CLR_ERROR="\033[0;31m"
    readonly CLR_RESET="\033[0m"
else
    readonly CLR_INFO=""   readonly CLR_SUCCESS=""
    readonly CLR_WARN=""   readonly CLR_ERROR=""   readonly CLR_RESET=""
fi

log_info()    { echo -e "${CLR_INFO}[INFO]    $(date +'%Y-%m-%d %H:%M:%S') - $*${CLR_RESET}"; }
log_success() { echo -e "${CLR_SUCCESS}[SUCCESS] $(date +'%Y-%m-%d %H:%M:%S') - $*${CLR_RESET}"; }
log_warn()    { echo -e "${CLR_WARN}[WARN]    $(date +'%Y-%m-%d %H:%M:%S') - $*${CLR_RESET}" >&2; }
log_error()   { echo -e "${CLR_ERROR}[ERROR]   $(date +'%Y-%m-%d %H:%M:%S') - $*${CLR_RESET}" >&2; }

# Structural Path Resolution Engine
resolve_object_path() {
    local -r type="$1"
    local -r id="$2"
    local -r env="${3:-prod}"
    local -r region="${4:-us-east-1}"

    # Pluralization wrapper for consistent storage layouts
    local plural_type="${type}s"
    [[ "$type" == *s ]] && plural_type="$type"

    echo "${GITCMDB_ROOT}/data/${env}/${region}/${plural_type}/${id}.json"
}

# Defensive Input Sanitization Helper
sanitize_input_string() {
    local -r input_str="${1:-}"
    # Reject path traversal variants safely
    if [[ "$input_str" =~ \.\.|\/ ]]; then
        log_error "Security Exception: Malformed input argument pattern detected."
        return 1
    fi
    echo "$input_str"
}





