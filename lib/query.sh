#!/usr/bin/env bash
# lib/query.sh - Stream Processing Query Optimization Pipeline

set -euo pipefail
IFS=$'\n\t'

readonly LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${LIB_DIR}/common.sh"

show_query_help() {
    cat << EOF
GitCMDB Query Pipeline Engine

Usage:
  gitcmdb query <type> [filters]

Available Filter Flags:
  --env <string>       Filter by targeted runtime tier
  --region <string>    Filter by region localization token
  --status <string>    Filter by current structural health metric status
  --raw                Output matching records as a raw newline-delimited stream of JSON

Examples:
  gitcmdb query host --env prod --status active
EOF
}

execute_pipeline_query() {
    local -r type="$1"
    shift
    
    local target_env=""   local target_region=""   local target_status=""   local format_raw=0

    while (( $# > 0 )); do
        case "$1" in
            --env)    target_env="$2"; shift 2 ;;
            --region) target_region="$2"; shift 2 ;;
            --status) target_status="$2"; shift 2 ;;
            --raw)    format_raw=1; shift ;;
            *) shift ;;
        esac
    done

    # 1. Compute physical search path optimization space dynamically
    local scan_path="${GITCMDB_ROOT}/data"
    [[ -n "$target_env" ]] && scan_path="${scan_path}/${target_env}"
    [[ -n "$target_region" ]] && scan_path="${scan_path}/${target_region}"

    if [[ ! -d "$scan_path" ]]; then
        log_warn "The specified data partition directory path search space does not exist: $scan_path"
        return 0
    fi

    # 2. ripgrep Fast Scan Phase -> streaming direct path pointers to jq filter phase
    # Senior Tip: Using null-terminated streams prevents file expansion argument overflows
    log_info "Scanning storage layout blocks using zero-allocation data pipeline indexes..."
    
    local -a jq_filters=()
    [[ -n "$target_status" ]] && jq_filters+=(".status == \"$target_status\"")

    local filter_string="select(. != null)"
    if (( ${#jq_filters[@]} > 0 )); then
        IFS=" and "
        filter_string="select(${jq_filters[*]})"
        IFS=$'\n\t'
    fi

    # 3. Stream Engine Processing Pipeline execution loop
    if (( format_raw == 1 )); then
        rg --files-with-matches --null --glob "*.json" "." "$scan_path" | \
            xargs -0 jq -c "$filter_string"
    else
        # Pretty tabulate formatting representation using standard awk engine processors
        echo -e "HOSTNAME\tENVIRONMENT\tREGION\tROLE\tIP_ADDRESS\tSTATUS"
        echo -e "--------\t-----------\t------\t----\t----------\t------"
        
        rg --files-with-matches --null --glob "*.json" "." "$scan_path" | \
            xargs -0 jq -r "[.hostname, .environment, .region, .role, .ip_address, .status] | @tsv" 2>/dev/null | \
            awk -F'\t' -v status="$target_status" '
                BEGIN { OFS="\t" }
                {
                    if (status == "" || $6 == status) {
                        print $1, $2, $3, $4, $5, $6
                    }
                }
            ' | column -t -s $'\t'
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if (( $# < 1 )) || [[ "$1" == "--help" ]]; then
        show_query_help
        exit 0
    fi
    execute_pipeline_query "$@"
fi