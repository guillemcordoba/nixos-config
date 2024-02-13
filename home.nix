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

		direnv = {
			enable = true;
			nix-direnv.enable = true;
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
