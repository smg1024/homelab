{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../services/ingress.nix
    ../../services/cloudflared.nix
  ];

  networking.hostName = "yggdrasil";

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  system.stateVersion = "25.11";
}
