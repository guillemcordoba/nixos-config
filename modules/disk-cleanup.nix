{ pkgs, ... }:

let
  sweepCargoTargets = pkgs.writeShellApplication {
    name = "sweep-cargo-targets";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
    ];
    text = ''
      root="$HOME/projects"
      start_below_gb=50
      stop_above_gb=150
      # Leave recently touched targets alone so we never delete under a running build.
      active_minutes=60

      avail_gb() { df --output=avail -BG "$root" | tail -1 | tr -dc '0-9'; }

      if (( $(avail_gb) >= start_below_gb )); then
        exit 0
      fi

      # Cargo tags every target dir with CACHEDIR.TAG, which avoids matching unrelated "target" dirs.
      find "$root" \( -name node_modules -o -name .git \) -prune -o \
        -type d -name target -exec test -f '{}/CACHEDIR.TAG' \; -print -prune |
        while read -r dir; do
          last_used=$(find "$dir" -maxdepth 2 -printf '%T@\n' | sort -n | tail -1)
          printf '%s\t%s\n' "''${last_used%.*}" "$dir"
        done |
        sort -n |
        while IFS=$'\t' read -r last_used dir; do
          if (( $(avail_gb) >= stop_above_gb )); then
            break
          fi
          if (( last_used > $(date +%s) - active_minutes * 60 )); then
            continue
          fi
          echo "Removing $dir (last used $(date -d "@$last_used" +%F))"
          rm -rf "$dir"
        done
    '';
  };
in
{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
    # Nix garbage-collects mid-build when free space drops below min-free.
    settings = {
      min-free = 20 * 1024 * 1024 * 1024;
      max-free = 100 * 1024 * 1024 * 1024;
    };
  };

  systemd.services.sweep-cargo-targets = {
    description = "Delete least recently used cargo target dirs when disk is low";
    serviceConfig = {
      Type = "oneshot";
      User = "guillem";
      ExecStart = "${sweepCargoTargets}/bin/sweep-cargo-targets";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.sweep-cargo-targets = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
    };
  };
}
