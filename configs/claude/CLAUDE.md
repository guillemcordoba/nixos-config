# System: NixOS

This machine runs NixOS. Follow these rules strictly:

## Running commands in projects

- Before running any project command, check for a `flake.nix` in the project root.
- If a `flake.nix` exists, **always** prefix commands with `nix develop --command` to run them inside the default devShell. For example:
  - `nix develop --command cargo build` instead of `cargo build`
  - `nix develop --command python main.py` instead of `python main.py`
  - `nix develop --command npm install` instead of `npm install`
- If the project has no `flake.nix`, check parent directories or proceed normally.

## Installing packages

- **Never** use `apt`, `yum`, `pacman`, `pip install --global`, `npm install -g`, `cargo install`, or any imperative package manager to install system-wide tools.
- To run a tool that is not available, use `nix run nixpkgs#<package>` instead. For example:
  - `nix run nixpkgs#jq -- '.foo' file.json` instead of installing jq
  - `nix run nixpkgs#ripgrep -- 'pattern' .` instead of installing ripgrep
  - `nix run nixpkgs#curl -- https://example.com` instead of installing curl
- If a command is missing and you need it, find the correct package name from nixpkgs and use `nix run nixpkgs#<package>`.

## General

- Assume `nix` is always available.
- Do not modify `/etc/nixos/` or any system configuration files unless explicitly asked.
- When suggesting dependency additions to a project, suggest adding them to `flake.nix` devShell inputs rather than installing globally.
