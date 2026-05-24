{...}: {
  # Enable these imports after collecting disk IDs and generated hardware config
  # during the NixOS installer phase.
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../services/homepage.nix
    ../../services/forgejo.nix
    ../../services/vaultwarden.nix
  ];

  networking.hostName = "midgard";

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
