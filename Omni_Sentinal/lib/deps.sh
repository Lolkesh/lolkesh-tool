#!/usr/bin/env bash

set -euo pipefail

declare -A _PIP_INSTALLED_CACHE=()

ensure_python_packages() {
  if [ "${SKIP_PYTHON_DEPS:-0}" -eq 1 ]; then
    warn "Skipping Python dependency installation (--skip-python-deps)"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log "OK" "Would upgrade pip and install Python dependencies"
    return 0
  fi

  python3 -m pip install --upgrade pip >/dev/null 2>&1 || \
    warn "pip upgrade failed; continuing with existing pip"

  local to_install=()
  local pkg
  for pkg in "$@"; do
    if [ -n "${_PIP_INSTALLED_CACHE[$pkg]:-}" ]; then
      continue
    fi
    _PIP_INSTALLED_CACHE["$pkg"]=1
    to_install+=("$pkg")
  done

  if [ "${#to_install[@]}" -eq 0 ]; then
    return 0
  fi

  run_cmd python3 -m pip install "${to_install[@]}"
}

install_system_deps() {
  if [ "${SKIP_SYSTEM_DEPS:-0}" -eq 1 ]; then
    warn "Skipping system dependency installation (--skip-system-deps)"
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    log "OK" "Detected pacman (Arch-based). Installing core dependencies..."
    if command -v sudo >/dev/null 2>&1; then
      run_cmd sudo pacman -Sy --needed --noconfirm \
        python python-pip base-devel git nodejs npm redis docker curl nmap openvpn chromium
    else
      warn "sudo is not available; skipping pacman dependency installation"
    fi
    return 0
  fi

  if command -v apt >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
    log "OK" "Detected apt (Debian-based). Installing core dependencies..."
    run_cmd sudo apt update
    run_cmd sudo apt install -y \
      python3-pip python3-dev build-essential git \
      nodejs npm redis-server docker.io curl nmap openvpn \
      chromium-browser exploitdb gobuster feroxbuster seclists ffuf \
      libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
      libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
      libgbm1 libasound2 libpangocairo-1.0-0 libgtk-3-0
    return 0
  fi

  warn "No supported package manager auto-install detected (expected pacman or apt)."
}

check_runtime_dependencies() {
  local missing=()
  local required_cmds=(python3 pip3 git node npm curl nmap openssl docker)
  local optional_cmds=(redis-server redis-cli gobuster ffuf chromium)
  local cmd

  for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    warn "Missing required dependencies: ${missing[*]}"
    warn "Install them and rerun. On Arch: sudo pacman -S --needed python python-pip git nodejs npm curl nmap openssl docker"
    if [ "${DRY_RUN:-0}" -eq 0 ]; then
      exit 1
    fi
  fi

  local missing_optional=()
  for cmd in "${optional_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || missing_optional+=("$cmd")
  done
  if [ "${#missing_optional[@]}" -gt 0 ]; then
    warn "Optional dependencies missing (some features disabled): ${missing_optional[*]}"
  fi
}
