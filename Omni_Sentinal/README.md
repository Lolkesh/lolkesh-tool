# Omnisential Installer

This repository provides a modular installer for Omnisential.

## Quick Start (clone and run)

```bash
git clone <https://github.com/Lolkesh/lolkesh-tool> Omni_Sentinal
cd Omni_Sentinal
chmod +x install.sh Install_command_v7
./install.sh
```

## Common commands

```bash
# Preflight only (no file generation)
./install.sh --check-only

# Preview actions only (no writes/installs)
./install.sh --dry-run --no-network-install

# Use custom output locations
./install.sh --base-dir "$HOME/omni-sentinal" --ui-dir "$HOME/omni-ui"

# Compatibility mode: use legacy v6 generator
./install.sh --legacy-backend
```

## Notes

- Default generation mode is template-based (`templates-v7`).
- Installer output base defaults to `~/omni-sentinal`, UI defaults to `~/omni-ui`.
- Existing unmanaged base directories are protected; use `--force` to override.
