#!/usr/bin/env bash
# lib/txn.sh - Transaction Concurrency Controller & Ledger Manager

set -euo pipefail
IFS=$'\n\t'

readonly LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${LIB_DIR}/common.sh"

readonly LOCK_FILE="/tmp/gitcmdb_global_engine.lock"

execute_transactional_commit() {
    local -r target_file="$1"
    local -r action_desc="$2"
    
    # 1. Acquire Exclusive Advisory Lock via flock descriptor 200
    exec 200>"$LOCK_FILE"
    log_info "Attempting to acquire exclusive transaction storage lock..."
    
    if ! flock -x -w 5 200; then
        log_error "Lock Acquisition Timeout: Distributed concurrency lock held by an active worker process."
        return 1
    fi
    log_info "Transaction storage lock successfully acquired."

    # 2. Sync to Immutable Ledger State (Git Core Operations)
    pushd "$GITCMDB_ROOT" &> /dev/null
    had_error=0
    
    {
        # Check if the file was deleted or added/modified
        if [[ -f "$target_file" ]]; then
            git add "$target_file"
        else
            git rm -q "$target_file" 2>/dev/null || true
        fi

        # Execute atomic tracking commit if a structural delta exists
        if ! git diff-index --quiet HEAD --; then
            git commit -m "$action_desc" -q
            log_success "Ledger transaction recorded: $action_desc"
        else
            log_info "No database mutation detected. Ledger trace synchronized."
        fi
    } || {
        log_error "Critical State Mutation Failure encountered during ledger commit synchronization."
        had_error=1
    }

    # 3. Clean and Explicit Lock Release
    flock -u 200
    exec 200>&-
    popd &> /dev/null

    return $had_error
}

stream_object_history() {
    local -r target_file="$1"
    
    # Translate file path to relative path mapping to evaluate cleanly in Git context
    local -r relative_path="${target_file#$GITCMDB_ROOT/}"

    pushd "$GITCMDB_ROOT" &> /dev/null
    if [[ ! -f "$relative_path" ]] && ! git log --error-on-no-match -q -- "$relative_path" &>/dev/null; then
        log_error "Asset database record path target has no historical log state entries."
        popd &> /dev/null
        return 1
    fi

    echo -e "${CLR_SUCCESS}--- Cryptographic History Trace Log: ${relative_path} ---${CLR_RESET}"
    git log --color=always --patch --stat -- "$relative_path"
    popd &> /dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    readonly OP="${1:-}"
    case "$OP" in
        history)
            shift
            type=$(sanitize_input_string "${1:-}")
            id=$(sanitize_input_string "${2:-}")
            env=$(sanitize_input_string "${3:-prod}")
            region=$(sanitize_input_string "${4:-us-east-1}")
            resolved_path=$(resolve_object_path "$type" "$id" "$env" "$region")
            stream_object_history "$resolved_path"
            ;;
    esac
fi