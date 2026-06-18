{
  config,
  pkgs,
  ...
}: {
  sops.secrets."cloudflare/caddy_env" = {
    owner = config.services.caddy.user;
    group = config.services.caddy.group;
    mode = "0400";
    restartUnits = [
      "caddy.service"
    ];
  };

  services.caddy = {
    enable = true;
    enableReload = true;

    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/caddy-dns/cloudflare@v0.2.4"
      ];
      hash = "sha256-bzMqxWTqrJ1skZmRTXyEMCKStXpljbqe5r0Ve2cnBfM=";
    };

    environmentFile = config.sops.secrets."cloudflare/caddy_env".path;

    globalConfig = ''
      email smg981024@gmail.com
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    '';

    virtualHosts."home.ridewithmin.com".extraConfig = ''
      reverse_proxy http://midgard.tail6fc192.ts.net:8082
    '';

    virtualHosts."git.ridewithmin.com".extraConfig = ''
      reverse_proxy http://midgard.tail6fc192.ts.net:3000
    '';

    virtualHosts."vault.ridewithmin.com".extraConfig = ''
      reverse_proxy http://midgard.tail6fc192.ts.net:8222
    '';

    virtualHosts."jamye-plz.ridewithmin.com".extraConfig = ''
      reverse_proxy http://alfheim.tail6fc192.ts.net:8080
    '';

    virtualHosts."status.ridewithmin.com".extraConfig = ''
      redir / /status 302

      @publicStatus {
        path /status* /api/status-page* /api/entry-page /assets/* /icon.svg /favicon.ico /apple-touch-icon.png /manifest.json /upload/*
      }

      handle @publicStatus {
        reverse_proxy http://127.0.0.1:3001
      }

      respond 404
    '';

    virtualHosts."grafana.ridewithmin.com".extraConfig = ''
      @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48

      handle @tailnet {
        reverse_proxy http://127.0.0.1:3003
      }

      respond 404
    '';

    virtualHosts."http://yggdrasil.tail6fc192.ts.net:3002".extraConfig = ''
      reverse_proxy http://127.0.0.1:3001
    '';
  };
}
