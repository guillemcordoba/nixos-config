{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.claudeRemoteControl;

  repoOptions = {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
      };
      spawn = lib.mkOption {
        type = lib.types.enum [
          "same-dir"
          "worktree"
          "session"
        ];
        default = "worktree";
      };
      permissionMode = lib.mkOption {
        type = lib.types.enum [
          "acceptEdits"
          "auto"
          "bypassPermissions"
          "default"
          "dontAsk"
          "plan"
        ];
        default = "default";
      };
    };
  };

  mkService = name: repo: {
    description = "Claude Code Remote Control for ${name}";
    wantedBy = [ "default.target" ];
    # Sessions need the same tools as a login shell, on top of the repo's devShell.
    path = [
      config.nix.package
      pkgs.git
      "/run/wrappers"
      "/etc/profiles/per-user/guillem"
      "/run/current-system/sw"
    ];
    # A user manager starting at boot has no login environment to inherit this from.
    environment.SSH_AUTH_SOCK = "%t/gcr/ssh";
    unitConfig = {
      # NixOS user units are global, so the GDM greeter's user manager would start this too.
      ConditionUser = "guillem";
      ConditionPathIsDirectory = repo.path;
      # At boot this can fail until the network is up, and a user unit can't order after
      # the system's network-online.target, so keep retrying.
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      WorkingDirectory = repo.path;
      ExecStart = lib.escapeShellArgs [
        "${config.nix.package}/bin/nix"
        "develop"
        repo.path
        "--command"
        "claude"
        "remote-control"
        "--name"
        name
        "--spawn"
        repo.spawn
        "--permission-mode"
        repo.permissionMode
      ];
      Restart = "always";
      RestartSec = 30;
    };
  };
in
{
  options.services.claudeRemoteControl.repos = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule repoOptions);
    default = { };
  };

  config = lib.mkIf (cfg.repos != { }) {
    # Without linger the user manager, and so these services, only run while logged in.
    users.users.guillem.linger = true;

    systemd.user.services = lib.mapAttrs' (
      name: repo: lib.nameValuePair "claude-remote-control-${name}" (mkService name repo)
    ) cfg.repos;
  };
}
