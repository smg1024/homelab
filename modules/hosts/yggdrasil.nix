{den, ...}: {
  den.hosts.x86_64-linux.yggdrasil.users.poby.classes = ["homeManager"];

  den.aspects.yggdrasil = {
    includes = [
      den.aspects.homelab-base
      den.aspects.ingress
      den.aspects.cloudflared
      den.aspects.uptime-kuma
      den.aspects.victorialogs
      den.aspects.beszel-hub
    ];

    nixos = {
      imports = [
        ./_yggdrasil/hardware-configuration.nix
        ./_yggdrasil/disko.nix
      ];

      services.dbus.implementation = "broker";

      services.logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      system.stateVersion = "25.11";
    };

    provides.poby.homeManager = {
      programs.bash.shellAliases = {
        logs-caddy = "journalctl -fu caddy";
        logs-cloudflared = "journalctl -fu cloudflared-tunnel-7464b4c7-93aa-4ef0-990d-76d6b0bb158a";
        logs-kuma = "journalctl -fu uptime-kuma";
        status-ingress = "systemctl status caddy cloudflared-tunnel-7464b4c7-93aa-4ef0-990d-76d6b0bb158a uptime-kuma";
      };
    };
  };
}
