{
  description = "Homelab NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
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
    system = "x86_64-linux";

    mkHost = hostModule:
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

          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.poby = import ./home/poby.nix;
          }

          hostModule
        ];
      };
  in {
    nixosConfigurations = {
      yggdrasil = mkHost ./hosts/yggdrasil;
      midgard = mkHost ./hosts/midgard;
    };
  };
}
