#!/usr/bin/env bash
# lib/query.sh - Stream Processing Query Optimization Pipeline

set -euo pipefail
IFS=$'\n\t'

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR
# shellcheck source=lib/common.sh
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
  local -r record_type="$1"
  shift
  : "$record_type"

  local target_env=""
  local target_region=""
  local target_status=""
  local format_raw=0

  while (($# > 0)); do
    case "$1" in
      --env)
        target_env="$2"
        shift 2
        ;;
      --region)
        target_region="$2"
        shift 2
        ;;
      --status)
        target_status="$2"
        shift 2
        ;;
      --raw)
        format_raw=1
        shift
        ;;
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
  if ((${#jq_filters[@]} > 0)); then
    local joined=""
    local filter
    for filter in "${jq_filters[@]}"; do
      if [[ -z "$joined" ]]; then
        joined="$filter"
      else
        joined="$joined and $filter"
      fi
    done
    filter_string="select(${joined})"
  fi

  # 3. Stream Engine Processing Pipeline execution loop
  if ((format_raw == 1)); then
    find "$scan_path" -type f -name "*.json" -print0 2> /dev/null |
      xargs -0 -r jq -c "$filter_string"
  else
    # Pretty tabulate formatting representation using standard awk engine processors
    echo -e "HOSTNAME\tENVIRONMENT\tREGION\tROLE\tIP_ADDRESS\tSTATUS"
    echo -e "--------\t-----------\t------\t----\t----------\t------"

    find "$scan_path" -type f -name "*.json" -print0 2> /dev/null |
      xargs -0 -r jq -r "[.hostname, .environment, .region, .role, .ip_address, .status] | @tsv" 2> /dev/null |
      awk -F'\t' -v status="$target_status" '
                BEGIN { OFS="\t" }
                {
                    if (status == "" || $6 == status) {
                        print $1, $2, $3, $4, $5, $6
                    }
                }
            '
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if (($# < 1)) || [[ "$1" == "--help" ]]; then
    show_query_help
    exit 0
  fi
  execute_pipeline_query "$@"
fi
