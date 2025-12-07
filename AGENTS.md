# AGENTS.md

## Architecture Overview

This is a NixOS flake-based system configuration with integrated home-manager. The flake dynamically imports hostname and username from `home/secrets.nix` (falls back to `secrets.example.nix`).

## Critical File Relationships

### Secrets System
- `home/secrets.nix` is imported by **three** entry points:
  1. `flake.nix` - to get hostname/username for configuration name
  2. `system/system.nix` - for user creation, cron jobs, paths
  3. `home/home.nix` - for home directory setup
- The secrets file is gitignored but must exist; use `secrets.example.nix` as template
- Changing hostname/username requires updating secrets.nix, then rebuild uses `nixosConfigurations.${secrets.hostName}`

### Desktop Environment Toggle System
- **Two-layer module system**: system-level + home-manager-level
- System modules: `system/desktop-environments/{cosmic,cinnamon}.nix`
  - Define `services.{cosmic,cinnamon}.enable` options
  - Handle display managers, system packages, portals
- Home modules: `home/desktop-environments/cinnamon.nix`
  - Define `home.cinnamon.enable` option
  - Handle user-level dconf settings, themes
- **Toggle in two places**:
  - `system/system.nix` lines 21-22: system-level services
  - `home/home.nix` line 20: user-level tweaks
- Currently: COSMIC enabled system-wide, Cinnamon disabled

### Hardware-Specific vs System Config Split
- `system/configuration.nix` - hardware-specific (NVIDIA, bluetooth, udev rules)
- `system/system.nix` - system-wide settings (users, services, boot, nix config)
- This split allows easier config reuse across machines

### Rebuild Script Workflow
- Lives at `home/bin/rebuild`, symlinked to `~/.local/bin/rebuild`
- **Workflow**: Format → Rsync to /etc/nixos → Update (optional) → Rebuild → Git commit on success
- Only commits on **successful** rebuild (intentional - tracks working generations only)
- Uses rsync with `--delete --force` to clean stale files from /etc/nixos
- Excludes: `.git`, `tools/`, `.venv/`, logs, LICENSE, README.md
- Generation number extracted from `nix-env --list-generations` for commit message

## Non-Obvious Conventions

### State Version
- `stateVersion = "25.11"` defined in flake, passed to both NixOS and home-manager
- Prevents accidental state migration on channel updates

### Package Organization
- System packages: `system/packages.nix` (CLI tools, formatters, system utilities)
- User packages: `home/packages.nix` (GUI apps, flatpaks, user tools)
- Some packages (like virt-manager) enabled via `programs.virt-manager.enable` rather than in package lists

### Automatic Maintenance
- Daily cron at midnight runs `rebuild` script (defined in system.nix)
- Weekly nix store optimization and garbage collection (nix.optimise, nix.gc)
- System auto-upgrade configured but daily cron effectively handles updates

### Home-Manager Integration
- Inline module in flake.nix, not separate file
- Uses `home-manager.users."${secrets.username}"` pattern
- Backup extension "backup" prevents file conflicts on rebuild

## Common Gotchas

- **Secrets must exist**: Build fails if `home/secrets.nix` missing and example doesn't have required fields
- **Desktop portal conflicts**: Only one desktop environment should be enabled at a time; portals are set per-DE
- **Flake updates**: Use `rebuild -u` from anywhere; don't manually run `nix flake update` in /etc/nixos
- **Git repo**: /etc/nixos is a copy, not symlink; changes go in ~/.dotfiles then rebuild syncs them