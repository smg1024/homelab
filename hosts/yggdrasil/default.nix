{...}: {
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../services/ingress.nix
    ../../services/cloudflared.nix
    ../../services/uptime-kuma.nix
    ../../services/prometheus
    ../../services/loki.nix
    ../../services/victorialogs.nix
    ../../services/beszel/hub.nix
    ../../services/grafana
    ../../services/docs-site.nix
  ];

  networking.hostName = "yggdrasil";
  services.dbus.implementation = "broker";

  home-manager.users.poby.imports = [
    ../../home/poby/yggdrasil.nix
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  system.stateVersion = "25.11";
}
