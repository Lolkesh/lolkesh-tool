#!/usr/bin/env bash

set -euo pipefail

MANIFEST_PATH=""
MANIFEST_DIR=""
BACKUP_PATH=""
STARTED_AT=""

init_install_state() {
  STARTED_AT="$(date -Iseconds)"
  MANIFEST_DIR="${BASE}/output"
  MANIFEST_PATH="${MANIFEST_DIR}/install-manifest.json"
}

ensure_base_is_safe() {
  if [ ! -d "${BASE}" ]; then
    return 0
  fi

  if [ -f "${BASE}/.omni-managed" ]; then
    log "OK" "Existing managed install detected at ${BASE}"
    return 0
  fi

  if [ "${FORCE:-0}" -eq 1 ]; then
    warn "Forcing install into unmanaged existing directory: ${BASE}"
    return 0
  fi

  warn "Refusing to write into existing unmanaged directory: ${BASE}"
  warn "Use --force if you want to adopt and overwrite with v7 backend generation."
  exit 1
}

backup_existing_base() {
  if [ "${DRY_RUN:-0}" -eq 1 ] || [ "${CHECK_ONLY:-0}" -eq 1 ]; then
    return 0
  fi

  if [ ! -d "${BASE}" ]; then
    return 0
  fi

  if [ -z "$(ls -A "${BASE}" 2>/dev/null)" ]; then
    return 0
  fi

  mkdir -p "${MANIFEST_DIR}/backups"
  BACKUP_PATH="${MANIFEST_DIR}/backups/pre-v7-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "${BACKUP_PATH}" -C "$(dirname "${BASE}")" "$(basename "${BASE}")"
  log "OK" "Backup created: ${BACKUP_PATH}"
}

write_manifest() {
  local status="$1"
  local ended_at
  local generation_mode
  local backend
  ended_at="$(date -Iseconds)"
  if [ "${LEGACY_BACKEND:-0}" -eq 1 ]; then
    generation_mode="legacy-v6"
    backend="${SCRIPT_DIR}/Install_command_v6"
  else
    generation_mode="templates-v7"
    backend="${SCRIPT_DIR}/templates"
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    return 0
  fi

  mkdir -p "${MANIFEST_DIR}"
  cat > "${MANIFEST_PATH}" <<EOF
{
  "version": "v7",
  "status": "${status}",
  "started_at": "${STARTED_AT}",
  "ended_at": "${ended_at}",
  "base": "${BASE}",
  "ui": "${UI}",
  "flags": {
    "check_only": ${CHECK_ONLY},
    "dry_run": ${DRY_RUN},
    "skip_system_deps": ${SKIP_SYSTEM_DEPS},
    "skip_python_deps": ${SKIP_PYTHON_DEPS},
    "no_network_install": ${NO_NETWORK_INSTALL},
    "safe_defaults": ${SAFE_DEFAULTS},
    "force": ${FORCE}
  },
  "generation_mode": "${generation_mode}",
  "backend": "${backend}",
  "backup_path": "${BACKUP_PATH}"
}
EOF
}
