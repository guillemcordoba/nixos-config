{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    helix.url = "github:helix-editor/helix/25.07";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  nixConfig = {
    extra-substituters = [ "https://helix.cachix.org" ];
    extra-trusted-public-keys =
      [ "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs=" ];
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations = {
      guillem = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          # To create bootable ISO images
          # (nixpkgs
          #   + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")

          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.guillem = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs system; };

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];
            environment.systemPackages =
              [ pkgs.rust-bin.stable.latest.default pkgs.clang ];
          })

        ];
      };
    };
  };
}
