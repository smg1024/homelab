{den, ...}: {
  den.hosts.aarch64-linux.alfheim.users.poby.classes = ["homeManager"];

  den.aspects.alfheim = {
    includes = [
      den.aspects.homelab-base
      den.aspects.podman
      den.aspects.jamye-server
      den.aspects.jamye-host-swap
    ];

    nixos = {
      imports = [
        ./_alfheim/hardware-configuration.nix
        ./_alfheim/disko.nix
      ];

      i18n.defaultLocale = "en_US.UTF-8";

      services.dbus.implementation = "broker";

      services.openssh.openFirewall = false;

      documentation.enable = false;

      system.stateVersion = "24.11";
    };
  };
}
