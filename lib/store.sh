#!/usr/bin/env bash
# lib/store.sh - ACID-Like Physical I/O Storage Layer Engine

set -euo pipefail
IFS=$'\n\t'

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR
GITCMDB_ROOT="${GITCMDB_ROOT:-$(cd "${LIB_DIR}/.." && pwd)}"
export GITCMDB_ROOT
# shellcheck source=lib/common.sh
source "${LIB_DIR}/common.sh"

parse_options_to_json() {
  # Programmatically maps CLI key-value arrays directly into clean JSON
  local json_accumulator="{}"
  while (($# > 0)); do
    case "$1" in
      --env | --region | --role | --status | --kernel | --owner | --ip_address | --hostname)
        local key="${1#--}"
        local val="$2"
        json_accumulator=$(echo "$json_accumulator" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
        shift 2
        ;;
      --set)
        # Evaluates dynamic key=value override notation strings
        local key="${2%%=*}"
        local val="${2#*=}"
        json_accumulator=$(echo "$json_accumulator" | jq --arg k "$key" --arg v "$val" '. + {($k): $v}')
        shift 2
        ;;
      *) shift ;;
    esac
  done
  echo "$json_accumulator"
}

write_record_atomically() {
  local type="$1"
  local id="$2"
  local path="$3"
  local block_json="$4"

  local target_dir
  target_dir="$(dirname "$path")"
  mkdir -p "$target_dir"

  # Instantiate transient workspace scratchpad with explicit cleanup
  local temp_scratch
  temp_scratch=$(mktemp "/tmp/gitcmdb_io.XXXXXX") || return 1

  # Cleanup function
  cleanup_temp() {
    if [[ -f "$temp_scratch" ]]; then
      rm -f "$temp_scratch"
    fi
  }
  trap cleanup_temp RETURN

  if [[ -f "$path" ]]; then
    # Mutation Pass: Update and merge key states cleanly
    jq -s 'add' "$path" <(echo "$block_json") > "$temp_scratch" || return 1
  else
    # Creation Pass
    echo "$block_json" | jq --arg h "$id" '. + {"hostname": $h}' > "$temp_scratch" || return 1
  fi

  # Enforce absolute validation guard rail check before updating active data partitions
  if ! bash "${GITCMDB_ROOT}/lib/validate.sh" "$type" "$temp_scratch"; then
    log_error "Transaction aborted: The proposed update payload violates schema integrity."
    return 1
  fi

  # Atomic Rename Swap operation via structural POSIX engine primitives
  mv "$temp_scratch" "$path" || return 1
  chmod 644 "$path"
  return 0
}

# Principal Action Router Mapping
readonly ACTION="${1:-}"
shift || true

if [[ -n "$ACTION" ]]; then
  type=$(sanitize_input_string "${1:-}")
  id=$(sanitize_input_string "${2:-}")
  shift 2 || true

  # Extract environmental parameters dynamically from remaining flags
  env="prod"
  region="us-east-1"
  args_copy=("$@")
  for ((i = 0; i < ${#args_copy[@]}; i++)); do
    [[ "${args_copy[i]}" == "--env" ]] && env="${args_copy[i + 1]}"
    [[ "${args_copy[i]}" == "--region" ]] && region="${args_copy[i + 1]}"
  done

  resolved_file=$(resolve_object_path "$type" "$id" "$env" "$region")

  case "$ACTION" in
    get)
      if [[ ! -f "$resolved_file" ]]; then
        log_error "Asset identity mapping match not found: '$resolved_file'"
        exit 1
      fi
      jq '.' "$resolved_file"
      ;;

    add | update)
      payload_json=$(parse_options_to_json "$@")
      # Inject dynamic context overrides directly to ensure absolute consistency
      payload_json=$(echo "$payload_json" | jq --arg e "$env" --arg r "$region" '. + {"environment": $e, "region": $r}')

      if write_record_atomically "$type" "$id" "$resolved_file" "$payload_json"; then
        bash "${GITCMDB_ROOT}/lib/txn.sh" "$resolved_file" "feat(${type}): persist schema mutations for identifier '${id}'"
      fi
      ;;

    delete)
      if [[ -f "$resolved_file" ]]; then
        rm -f "$resolved_file"
        bash "${GITCMDB_ROOT}/lib/txn.sh" "$resolved_file" "fix(${type}): purge asset record identifier '${id}'"
        log_success "Asset identity registration deleted successfully from database partition mapping."
      else
        log_warn "Target database record mapping is already missing from disk space."
      fi
      ;;
  esac
fi
