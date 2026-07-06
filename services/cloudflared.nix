{config, ...}: {
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

      ingress."blog.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "blog.ridewithmin.com";
          originServerName = "blog.ridewithmin.com";
        };
      };

      ingress."git.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "git.ridewithmin.com";
          originServerName = "git.ridewithmin.com";
        };
      };

      ingress."vault.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "vault.ridewithmin.com";
          originServerName = "vault.ridewithmin.com";
        };
      };

      ingress."jamye-plz.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "jamye-plz.ridewithmin.com";
          originServerName = "jamye-plz.ridewithmin.com";
        };
      };

      ingress."status.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "status.ridewithmin.com";
          originServerName = "status.ridewithmin.com";
        };
      };

      ingress."docs.ridewithmin.com" = {
        service = "https://localhost:443";
        originRequest = {
          httpHostHeader = "docs.ridewithmin.com";
          originServerName = "docs.ridewithmin.com";
        };
      };
    };
  };
}
