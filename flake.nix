{
  description = "Homelab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    disko,
    home-manager,
    sops-nix,
    ...
  }: let
    mkHost = {
      hostModule,
      system ? "x86_64-linux",
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
        };

        modules = [
          ./modules/base.nix
          ./modules/gc.nix
          ./modules/swap.nix
          ./modules/users.nix
          ./modules/ssh.nix
          ./modules/tailscale.nix
          ./modules/secrets.nix
          ./services/node-exporter.nix
          ./services/alloy.nix

          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
            home-manager.users.poby = {
              imports = [
                ./home/poby/base.nix
                ./home/poby/ops.nix
              ];
            };
          }

          hostModule
        ];
      };
  in {
    nixosConfigurations = {
      yggdrasil = mkHost {
        hostModule = ./hosts/yggdrasil;
      };
      midgard = mkHost {
        hostModule = ./hosts/midgard;
      };
      alfheim = mkHost {
        hostModule = ./hosts/alfheim;
        system = "aarch64-linux";
      };
    };
  };
}
