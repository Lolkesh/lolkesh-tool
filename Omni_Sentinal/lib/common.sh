#!/usr/bin/env bash

set -euo pipefail

STEP_INDEX=0
DRY_RUN=0

log() {
  printf '\033[1;36m[%s]\033[0m %s\n' "$1" "$2"
}

warn() {
  printf '\033[1;33m[!]\033[0m %s\n' "$1"
}

step() {
  STEP_INDEX=$((STEP_INDEX + 1))
  log "STEP ${STEP_INDEX}" "$1"
}

run_cmd() {
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    printf '\033[1;35m[DRY-RUN]\033[0m'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}
