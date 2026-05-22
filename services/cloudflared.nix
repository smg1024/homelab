{
  config,
  ...
}: {
  sops.secrets."cloudflare/cloudflared_tunnel_credentials" = {
    mode = "0400";
  };

  services.cloudflared = {
    enable = true;

    tunnels."7464b4c7-93aa-4ef0-990d-76d6b0bb158a" = {
      credentialsFile = config.sops.secrets."cloudflare/cloudflared_tunnel_credentials".path;
      default = "http_status:404";

      ingress."home.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "home.ridewithmin.com";
          originServerName = "home.ridewithmin.com";
        };
      };
    };
  };
}
