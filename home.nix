{ pkgs, inputs, system, ... }:

{
  imports = [
    # inputs.niri.homeModules.niri
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri

  ];
  programs.dank-material-shell = {
    enable = true;
    dgop.package = inputs.dgop.packages.${pkgs.system}.default;

    systemd = {
      enable = true; # Systemd service for auto-start
      restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
    };

    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    niri = {
      enableKeybinds = true; # Sets static preset keybinds
      enableSpawn = true; # Auto-start DMS with niri, if enabled
    };
  };

  home = {
    username = "guillem";
    homeDirectory = "/home/guillem";

    stateVersion = "23.11";

    packages = let
      # https://discourse.nixos.org/t/nix-flamegraph-or-profiling-tool/33333
      stackCollapse = pkgs.writeTextFile {
        name = "stack-collapse.py";
        destination = "/bin/stack-collapse.py";
        text = builtins.readFile (builtins.fetchurl {
          url =
            "https://raw.githubusercontent.com/NixOS/nix/master/contrib/stack-collapse.py";
          sha256 =
            "sha256:0mi9cf3nx7xjxcrvll1hlkhmxiikjn0w95akvwxs50q270pafbjw";
        });
        executable = true;
      };
      nix-flamegraph = pkgs.writeShellApplication {
        name = "nix-flamegraph";
        runtimeInputs = [ stackCollapse pkgs.inferno pkgs.chromium ];
        text = ''
          #!/bin/bash
          WORKDIR=$(mktemp -d)

          nix eval -vvvvvvvvvvvvvvvvvvvv --raw --option trace-function-calls true $1 1>/dev/null 2> $WORKDIR/nix-function-calls.trace
          stack-collapse.py $WORKDIR/nix-function-calls.trace > $WORKDIR/nix-function-calls.folded
          inferno-flamegraph $WORKDIR/nix-function-calls.folded > $WORKDIR/nix-function-calls-$1.svg
          chromium "$WORKDIR/nix-function-calls-$1.svg"
        '';
        checkPhase = "";
      };

    in with pkgs; [
      inputs.helix.outputs.packages.${system}.default
      # helix
      zed-editor
      discord
      spotify
      signal-desktop
      zoom-us
      chromium
      firefox
      rust-analyzer
      nodePackages.typescript-language-server
      nodejs_22
      peek
      (pkgs.writeShellScriptBin "nr" ''
        nix run nixpkgs#"$@"
      '')
      nix-flamegraph
      # libnotify
    ];

    sessionVariables = { EDITOR = "hx"; };

    file.".config/qtile".source = ./configs/qtile;
    file.".config/niri".source = ./configs/niri;
    file.".config/alacritty".source = ./configs/alacritty;
    file.".config/helix".source = ./configs/helix;
    file.".config/zed".source = ./configs/zed;
    file.".claude/CLAUDE.md".source = ./configs/claude/CLAUDE.md;
    file.".claude/settings.json".source = ./configs/claude/settings.json;
  };

  xdg = {
    desktopEntries.chromium-new-window = {
      name = "Chromium (New Window)";
      exec = "chromium --new-window %u";
      terminal = false;
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "chromium-new-window.desktop";
        "x-scheme-handler/http" = "chromium-new-window.desktop";
        "x-scheme-handler/https" = "chromium-new-window.desktop";
      };
    };
  };

  programs.niri.config = null;
  programs = {

    home-manager.enable = true;
    zoxide.enable = true;

    direnv = {
      enable = true;
      # silent = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
      settings = {
        cmd_duration = {
          min_time = 2000;
          # show_milliseconds = false;
          # disabled = false;
          show_notifications = true;
          min_time_to_notify = 5000;
        };
        nix_shell = { format = "[$symbol$name]($style) "; };
        rust = { format = "$symbol"; };
        nodejs = { format = "$symbol"; };
      };
    };

    bash = {
      enable = true;

      shellAliases = {
        cd = "z";
        lg = "lazygit";
        nr = "nix run nixpkgs#";
        ns = "nix shell nixpkgs#";
        j = "just";
      };

      initExtra = ''
                eval "$(starship init bash)"
                eval "$(zoxide init bash)"
                export DIRENV_LOG_FORMAT=
        			'';
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "guillem.cordoba";
          email = "guillem.cordoba@gmail.com";
        };
        init.defaultBranch = "main";
        push = { autoSetupRemote = true; };
        core.editor = "hx";
      };
    };
    lazygit.enable = true;
  };
  # services.dunst.enable = true;
  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
    };

    flameshot.enable = true;
  };
  programs.atuin = {
    enable = true;
    settings = {
      # auto_sync = true;
      # sync_frequency = "5m";
      # sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
    flags = [ "--disable-up-arrow" ];
  };

  programs.carapace.enable = true;

}
