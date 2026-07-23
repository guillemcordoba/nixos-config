# System: NixOS

This machine runs NixOS. Follow these rules strictly:

## Running commands in projects

- Claude Code is always launched from within a `nix develop` shell. You do **not** need to prefix commands with `nix develop --command` when running them in the current project — just run them directly (e.g. `cargo build`, `python main.py`, `npm install`).
- If you need to run commands in a **different** project that has its own `flake.nix`, prefix with `nix develop /path/to/project --command` to enter that project's devShell.

## Installing packages

- **Never** use `apt`, `yum`, `pacman`, `pip install --global`, `npm install -g`, `cargo install`, or any imperative package manager to install system-wide tools.
- To run a tool that is not available, use `nix run nixpkgs#<package>` instead. For example:
  - `nix run nixpkgs#jq -- '.foo' file.json` instead of installing jq
  - `nix run nixpkgs#ripgrep -- 'pattern' .` instead of installing ripgrep
  - `nix run nixpkgs#curl -- https://example.com` instead of installing curl
- If a command is missing and you need it, find the correct package name from nixpkgs and use `nix run nixpkgs#<package>`.

## Workflow: investigate → brainstorm → ask before implementing

For any non-trivial task (new features, refactors, behavior changes), ALWAYS follow these steps before writing code — even in auto-accept / autonomous mode:

1. **Investigate first.** Gather evidence before forming an opinion: read the relevant code, configs, and docs in the repo. If the local information is not enough, or you have any doubt about how to proceed (unfamiliar library, ambiguous API, unclear best practice), research on the web (WebSearch/WebFetch) before deciding anything.
2. **Brainstorm.** Come up with the possible ways to implement the feature, with the trade-offs of each (complexity, maintainability, how well it fits the existing code).
3. **Ask me.** Present the options and your recommendation, and wait for my answer before implementing (use AskUserQuestion when available). Do NOT skip this step because auto-accept or autonomous mode is on — auto mode only removes permission prompts for tools, not the obligation to check the approach with me.

Only skip this workflow for trivial changes (typo fixes, one-line tweaks I've already described exactly) or when I've already chosen the approach explicitly.

## General

- Assume `nix` is always available.
- Do not modify `/etc/nixos/` or any system configuration files unless explicitly asked.
- When suggesting dependency additions to a project, suggest adding them to `flake.nix` devShell inputs rather than installing globally.
