{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/podman.nix
  ];

  networking.hostName = "alfheim";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.initrd.systemd.enable = true;
  services.dbus.implementation = "broker";

  services.openssh.openFirewall = false;

  documentation.enable = false;

  system.stateVersion = "24.11";
}
