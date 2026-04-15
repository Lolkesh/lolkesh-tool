#!/usr/bin/env bash

set -euo pipefail

render_template() {
  local src="$1"
  local dest="$2"

  if [ ! -f "$src" ]; then
    warn "Template not found: $src"
    exit 1
  fi

  if [ -f "$dest" ] && [ "${FORCE:-0}" -ne 1 ]; then
    warn "Skipping existing file (use --force to overwrite): $dest"
    return 0
  fi

  run_cmd mkdir -p "$(dirname "$dest")"

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log "OK" "Would render template: $dest"
    return 0
  fi

  sed \
    -e "s|__BASE__|${BASE}|g" \
    -e "s|__UI__|${UI}|g" \
    -e "s|__SECRET_KEY__|${SECRET_KEY}|g" \
    -e "s|__ADMIN_PASSWORD__|${ADMIN_PASSWORD}|g" \
    "$src" > "$dest"
}

write_env_file() {
  local env_path="${BASE}/.env"
  if [ -f "$env_path" ] && [ "${FORCE:-0}" -ne 1 ]; then
    warn "Skipping existing secrets file: $env_path"
    return 0
  fi

  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    log "OK" "Would write secure environment file: $env_path"
    return 0
  fi

  umask 077
  cat > "$env_path" <<EOF
SECRET_KEY=${SECRET_KEY}
ADMIN_USERNAME=admin
ADMIN_PASSWORD=${ADMIN_PASSWORD}
REDIS_URL=redis://localhost:6379/0
EOF
  chmod 600 "$env_path"
}

generate_from_templates() {
  local template_root="${SCRIPT_DIR}/templates"
  if [ ! -d "$template_root" ]; then
    warn "Template directory not found: $template_root"
    exit 1
  fi

  step "Generating secure credentials"
  if [ "${DRY_RUN:-0}" -eq 1 ]; then
    SECRET_KEY="dry-run-secret"
    ADMIN_PASSWORD="dry-run-password"
  else
    SECRET_KEY="$(openssl rand -hex 32)"
    ADMIN_PASSWORD="$(openssl rand -hex 12)"
  fi

  step "Rendering backend templates"
  render_template "${template_root}/base/docker-compose.yml.tmpl" "${BASE}/docker-compose.yml"
  render_template "${template_root}/base/requirements.txt.tmpl" "${BASE}/requirements.txt"
  render_template "${template_root}/base/README.md.tmpl" "${BASE}/README.md"
  render_template "${template_root}/base/dashboard/app.py.tmpl" "${BASE}/dashboard/app.py"
  render_template "${template_root}/base/core/worker.py.tmpl" "${BASE}/core/worker.py"
  write_env_file

  step "Rendering UI templates"
  render_template "${template_root}/ui/package.json.tmpl" "${UI}/package.json"
  render_template "${template_root}/ui/index.html.tmpl" "${UI}/index.html"
  render_template "${template_root}/ui/src/main.jsx" "${UI}/src/main.jsx"
}
