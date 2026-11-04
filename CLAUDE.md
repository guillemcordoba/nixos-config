# NixOS Configuration Repository

Personal NixOS system configuration for user **guillem**, managed with flakes and home-manager.

## Repository Structure

```
flake.nix                  # Flake entry point: inputs, overlays, NixOS + home-manager wiring
flake.lock                 # Pinned dependency versions
configuration.nix          # System-level NixOS config (packages, services, users, locale)
home.nix                   # Home-manager config (user packages, shell, git, editor, dotfiles)
hosts/
  workstation/             # Desktop: nvidia, VirtualBox, Claude Remote Control repos
  thinkpad/                # X1 Carbon Gen 9: lid suspend, swayidle, laptop cargo settings
modules/
  niri.nix                 # Niri window manager NixOS module
  dankmaterialshell.nix    # DankMaterialShell NixOS module (currently a stub)
  claude-remote-control.nix # One always-on Remote Control service per repo in services.claudeRemoteControl.repos
configs/
  alacritty/alacritty.toml # Terminal emulator config
  helix/config.toml        # Helix editor settings
  helix/languages.toml     # Helix per-language settings (formatters, LSPs)
  niri/config.kdl          # Niri window manager keybinds and layout
  zed/settings.json        # Zed editor settings
  zed/keymap.json          # Zed keybindings
  qtile/config.py          # Qtile WM config (legacy, X11)
  claude/CLAUDE.md         # Claude Code per-user CLAUDE.md (symlinked to ~/.claude/CLAUDE.md)
guides/                    # Personal reference notes (wifi, iso-image, virtualbox, install-thinkpad)
```

## Machines

All machines are configured from one branch, `main`. Each has a `nixosConfigurations.<hostname>` entry in `flake.nix` and a `hosts/<hostname>/` directory. Anything specific to a machine goes in its host directory, including home-manager settings via `home-manager.users.guillem`, rather than in a long-lived branch.

- **`workstation`**: Desktop
- **`thinkpad`**: X1 Carbon Gen 9. Its `hardware-configuration.nix` is generated during install, see `guides/install-thinkpad.md`; until then this config intentionally fails to evaluate.

## Key Technical Details

### Flake Inputs
- **nixpkgs**: `nixos-25.11` (stable channel)
- **nixpkgs-unstable**: Used for select packages (e.g. `claude-code`)
- **home-manager**: `release-25.11`, follows nixpkgs
- **helix**: Pinned to `25.07` branch with cachix binary cache
- **rust-overlay**: For Rust toolchain with `rust-src`
- **niri**: Wayland compositor via `sodiboo/niri-flake`, overlaid onto nixpkgs
- **dms** (DankMaterialShell): Shell/bar from `AvengeMedia/DankMaterialShell`
- **dgop**: Companion tool for DMS from `AvengeMedia/dgop`

### System Configuration (`configuration.nix`)
- Shared by every host, `x86_64-linux`
- The hostname comes from the host's name in `flake.nix`
- Locale: `ca_ES.UTF-8` (Catalan), keyboard layout: `es` variant `cat`
- Timezone: `Europe/Madrid`
- Display manager: GDM with Wayland
- Docker enabled (rootless)
- Flakes and nix-command experimental features enabled
- Nix formatter: `nixfmt`
- Fonts: Nerd Fonts (Fira Code, Droid Sans Mono)
- Unfree packages allowed

### Home Manager (`home.nix`)
- Default editor: `hx` (Helix)
- Shell: Bash with starship prompt, zoxide (`cd` aliased to `z`), direnv, atuin (fuzzy search), carapace
- Git: user `guillem.cordoba`, email `guillem.cordoba@gmail.com`, default branch `main`, auto-setup remote push, editor `hx`
- Shell aliases: `lg`=lazygit, `nr`=`nix run nixpkgs#`, `ns`=`nix shell nixpkgs#`, `j`=just
- Dotfiles are symlinked via `home.file` from `configs/` into `~/.config/`
- The file `configs/claude/CLAUDE.md` is symlinked to `~/.claude/CLAUDE.md`

### Window Manager
- **Niri** (Wayland tiling compositor) is the active WM, configured via `configs/niri/config.kdl`
- **DankMaterialShell** is used as the shell/bar with systemd auto-start
- Niri uses `mod-key "Alt"`, touchpad natural scroll + tap enabled
- Qtile config exists but is legacy/unused (X11)

## How to Apply Changes

```bash
# Rebuild and switch (from repo root)
sudo nixos-rebuild switch --flake .

# Test without making it the boot default
sudo nixos-rebuild test --flake .

# Update flake inputs
nix flake update

# Update a single input
nix flake update <input-name>

# Format nix files
nixfmt *.nix modules/*.nix
```

## Conventions When Editing

- Nix files use 2-space indentation and are formatted with `nixfmt` (in `environment.systemPackages`)
- System-wide packages go in `configuration.nix` `environment.systemPackages`
- User/GUI packages go in `home.nix` `home.packages`
- Packages from unstable channel use `pkgs-unstable.<pkg>` (passed via `specialArgs`)
- New dotfile configs go in `configs/<app>/` and are linked via `home.file` in `home.nix`
- New NixOS modules go in `modules/` and are added to the `modules` list in `flake.nix`
- `hosts/<hostname>/hardware-configuration.nix` is generated per machine - avoid modifying it unless targeting that machine
- The `stateVersion` is `"23.11"` - do not change this
- When adding flake inputs, remember to pass them through `specialArgs` or `extraSpecialArgs` as needed
