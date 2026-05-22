{config, ...}: {
  sops.secrets."vaultwarden/admin_token" = {
    sopsFile = ../secrets/vaultwarden.yaml;
  };

  sops.templates."vaultwarden.env" = {
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
    restartUnits = [
      "vaultwarden.service"
    ];
    content = ''
      ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/admin_token"}
    '';
  };

  services.vaultwarden = {
    enable = true;
    domain = "vault.ridewithmin.com";
    dbBackend = "sqlite";
    environmentFile = config.sops.templates."vaultwarden.env".path;

    config = {
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = true;
      ENABLE_WEBSOCKET = true;
    };
  };
}
