{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/podman.nix
    ../../services/jamye-plz.nix
  ];

  # MinIO's final OSS release is marked insecure in nixpkgs. Keep the exception
  # scoped to alfheim and pinned to the exact package version.
  nixpkgs.config.permittedInsecurePackages = [
    "minio-2025-10-15T17-29-55Z"
  ];

  networking.hostName = "alfheim";
  i18n.defaultLocale = "en_US.UTF-8";

  boot.initrd.systemd.enable = true;
  services.dbus.implementation = "broker";

  services.openssh.openFirewall = false;

  documentation.enable = false;

  system.stateVersion = "24.11";
}
