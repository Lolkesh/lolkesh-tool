# Omni Sentinal

Omni Sentinal is a modular security automation platform with a FastAPI backend, Celery workers, Redis queueing, and a plugin-first architecture.  
The project is scaffolded by `Install_command_v5`, which generates the runtime under `~/omni-sentinal` and the UI under `~/omni-ui`.

## Why This Build

- KISS-first design: plugin modules are plain Python files.
- Persistent plugin storage: installed plugins are physically written to `plugins/`.
- Runtime toggles: plugins can be enabled/disabled in `config.json` without deleting code.
- Arch-focused setup path with minimal package overhead.

## Architecture Overview

Core runtime layout (generated in `~/omni-sentinal`):

- `core/plugin_loader.py`: dynamic discovery, loading, install, and enable/disable management.
- `plugins/*.py`: plugin modules (hardcoded files on disk).
- `config.json`: plugin enable/disable state map.
- `core/worker.py`: executes plugin hooks during scan lifecycle.
- `dashboard/app.py`: plugin management API (`/plugins` endpoints).

### Plugin Lifecycle

1. `plugin_loader.load_enabled_plugins()` reads `config.json`.
2. Enabled entries are loaded from `plugins/<name>.py` using `importlib`.
3. Worker triggers plugin hooks, e.g. `on_scan_complete(context)` and `on_scan_failed(context)`.
4. New plugins installed via API are atomically saved to `plugins/` and persisted across restarts.

## Arch Linux Setup

## 1) System Packages

Install the base toolchain:

```bash
sudo pacman -Syu --needed \
  base-devel git curl wget unzip \
  python python-pip python-virtualenv \
  nodejs npm \
  redis docker nmap
```

Optional utilities (depending on enabled features/plugins):

```bash
sudo pacman -S --needed gobuster ffuf chromium
```

AUR tools (choose one helper):

```bash
# yay
sudo pacman -S --needed yay

# or paru
sudo pacman -S --needed paru
```

Potential AUR installs:

```bash
yay -S --needed feroxbuster seclists
# or
paru -S --needed feroxbuster seclists
```

## 2) Python Dependencies

Use a venv to reduce system contamination and RAM overhead at runtime:

```bash
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install fastapi uvicorn celery redis python-dotenv bcrypt PyJWT requests python-nmap cryptography fpdf2 markdown2 schedule dnspython
```

## 3) Services

Enable backend services:

```bash
sudo systemctl enable --now redis
sudo systemctl enable --now docker
```

Add your user to the docker group (then re-login):

```bash
sudo usermod -aG docker "$USER"
```

## 4) Generate Project

Run the scaffold script:

```bash
chmod +x Install_command_v5
./Install_command_v5
```

Generated paths:

- Backend: `~/omni-sentinal`
- UI: `~/omni-ui`

## Plugin Developer Guide

## Plugin Contract (Minimal)

Each plugin is a Python module in `plugins/` with optional hook functions:

- `on_scan_complete(context: dict) -> Any`
- `on_scan_failed(context: dict) -> Any`

The `context` object includes scan metadata (`scan_id`, `target`, `services`, `cves`, etc.).

## Hardcoding a Plugin (Persistent Install)

### Option A: Direct file drop

1. Create `plugins/my_plugin.py`.
2. Add toggle in `config.json`:

```json
{
  "plugins": {
    "my_plugin": true
  }
}
```

3. Restart API/worker (or trigger plugin reload endpoint path in your flow).

### Option B: API install (recommended)

POST plugin source to `/plugins`:

```bash
curl -X POST http://localhost:8000/plugins \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "module_name": "my_plugin",
    "source_code": "def on_scan_complete(context):\n    print(\"my_plugin\", context.get(\"target\"))\n",
    "enabled": true
  }'
```

This writes `plugins/my_plugin.py` atomically and updates `config.json`.

## Enable/Disable Without Deleting Source

Toggle plugin state:

```bash
curl -X PATCH http://localhost:8000/plugins/my_plugin \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"enabled": false}'
```

List plugin states:

```bash
curl -H "Authorization: Bearer <token>" http://localhost:8000/plugins
```

## Example Hello World Plugin

`plugins/hello_world.py`:

```python
from datetime import datetime

def on_scan_complete(context: dict) -> dict:
    target = context.get("target", "unknown-target")
    message = f"[hello_world] scan completed for {target} at {datetime.utcnow().isoformat()}Z"
    print(message)
    return {"message": message}
```

Enable state in `config.json`:

```json
{
  "plugins": {
    "hello_world": true
  }
}
```

## Usage

From backend project directory (`~/omni-sentinal`):

```bash
uvicorn dashboard.app:app --host 0.0.0.0 --port 8000
celery -A core.worker:app worker --concurrency=4 --loglevel=info
```

From UI directory (`~/omni-ui`):

```bash
npm install
npm run dev -- --host 0.0.0.0 --port 5173
```

## Troubleshooting (Arch Linux)

- `redis connection refused`: verify `systemctl status redis` and `REDIS_URL`.
- `Permission denied` writing plugins: ensure user owns project dir and `plugins/` is writable.
- Plugins not loading: verify module name matches `config.json` key and file is valid Python.
- Missing binary tools (`gobuster`, `ffuf`, etc.): install via pacman/AUR and verify `PATH`.
- Docker errors after group change: log out/in after `usermod -aG docker`.

## Performance Notes

- Plugin loader only imports enabled modules, reducing memory overhead.
- Plugin installation uses atomic writes (`os.replace`) to avoid partial files.
- `config.json` is small and read/written with minimal filesystem calls.
- Keep plugin code dependency-light for fast worker startup and lower RAM usage.
