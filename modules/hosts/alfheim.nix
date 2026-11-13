{den, ...}: {
  den.hosts.aarch64-linux.alfheim.users.poby.classes = ["homeManager"];

  den.aspects.alfheim = {
    includes = [
      den.aspects.homelab-base
      den.aspects.podman
      den.aspects.jamye-server
    ];

    nixos = {lib, ...}: {
      imports = [
        ./_alfheim/hardware-configuration.nix
        ./_alfheim/disko.nix
      ];

      nixpkgs.config.allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) ["claude-code"];

      i18n.defaultLocale = "en_US.UTF-8";

      services.dbus.implementation = "broker";

      services.openssh.openFirewall = false;

      documentation.enable = false;

      system.stateVersion = "24.11";
    };

    provides.poby.homeManager = {pkgs, ...}: {
      home.packages = with pkgs; [
        claude-code
        codex
      ];
    };
  };
}
