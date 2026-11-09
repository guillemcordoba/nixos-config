{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix.url = "github:helix-editor/helix";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-unstable.url = "github:YaLTeR/niri";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  nixConfig = {
    extra-substituters = [ "https://helix.cachix.org" ];
    extra-trusted-public-keys = [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;

      nixosConfigurations = nixpkgs.lib.genAttrs [ "workstation" "thinkpad" ] (
        hostName:
        nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = {
            pkgs-unstable = import inputs.nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
            inherit inputs;
          };
          modules = [
            # To create bootable ISO images
            # (nixpkgs
            #   + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")

            ./configuration.nix
            ./hosts/${hostName}
            { networking.hostName = hostName; }
            ./modules/niri.nix
            ./modules/dankmaterialshell.nix
            ./modules/disk-cleanup.nix
            ./modules/claude-remote-control.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.guillem = import ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs system;
                inherit (specialArgs) pkgs-unstable;
              };

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }
            ({ pkgs, ... }: {
              nixpkgs.overlays = [
                inputs.rust-overlay.overlays.default

              ];
              environment.systemPackages = [
                (pkgs.rust-bin.stable.latest.default.override {
                  extensions = [ "rust-src" ];
                })
                pkgs.clang
              ];
            })

          ];
        }
      );
    };
}
