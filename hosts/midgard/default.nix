{pkgs, ...}: {
  # Enable these imports after collecting disk IDs and generated hardware config
  # during the NixOS installer phase.
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/podman.nix
    ../../services/homepage.nix
    ../../services/forgejo.nix
    ../../services/vaultwarden.nix
    ../../services/jamye-plz.nix
    ../../services/jamye-host-swap.nix
  ];

  # jamye-plz uses the final OSS MinIO release, marked insecure in nixpkgs.
  nixpkgs.config.permittedInsecurePackages = [
    "minio-2025-10-15T17-29-55Z"
  ];

  networking.hostName = "midgard";
  services.dbus.implementation = "dbus";

  fonts = {
    packages = with pkgs; [
      pretendard
      noto-fonts-cjk-sans
    ];

    fontconfig = {
      enable = true;
      defaultFonts.sansSerif = [
        "Pretendard"
        "Noto Sans CJK KR"
      ];
    };
  };

  home-manager.users.poby.imports = [
    ../../home/poby/midgard.nix
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  system.stateVersion = "25.11";
}
