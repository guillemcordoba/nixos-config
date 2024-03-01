{ config, pkgs, ... }: 

{
	home =  {
	  username = "guillem";
	  homeDirectory = "/home/guillem";

	  stateVersion = "23.11";

	  packages = with pkgs; [
	    helix
	    discord
	    spotify
	    signal-desktop
	    zoom-us
			chromium
			firefox
			rust-analyzer
			nodePackages.typescript-language-server
			nodejs_20
		];

		sessionVariables = {
			EDITOR = "hx";
		};

		file.".config/qtile".source = ./configs/qtile;
		file.".config/alacritty".source = ./configs/alacritty;
		file.".config/helix".source = ./configs/helix;
	};

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
	        min_time_to_notify = 15000;
	      };
				nix_shell = {
		      format = "[$symbol$name]($style) ";
				};
				rust = {
		      format = "$symbol";
				};
				nodejs = {
		      format = "$symbol";
				};
      };
		};

		bash = {
			enable = true;

			shellAliases = {
				cd = "z";
				lg = "lazygit";
			};

			initExtra = ''
        eval "$(starship init bash)"
        eval "$(zoxide init bash)"
        export DIRENV_LOG_FORMAT=
			'';
		};

		git = {
			enable = true;
			userName = "guillem.cordoba";
			userEmail = "guillem.cordoba@gmail.com";

			extraConfig = {
				init.defaultBranch = "main";
				push = {
					autoSetupRemote = true;
				};
				core.editor = "hx";
			};
		};
		lazygit.enable = true;

	};
	services = {	
	  gpg-agent = {
			enable = true;
			defaultCacheTtl = 1800;
			enableSshSupport = true;
		};
	};
}
