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
      hash = "sha256-vNSHU7txQLs0m0UChuszURXjEoMj4r1902+1ei0/DaI=";
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

    virtualHosts."status.ridewithmin.com".extraConfig = ''
      reverse_proxy http://127.0.0.1:3001
    '';
  };
}
