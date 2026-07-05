{config, ...}: {
  sops.secrets."beszel/admin_email" = {sopsFile = ../../secrets/beszel.yaml;};
  sops.secrets."beszel/admin_password" = {sopsFile = ../../secrets/beszel.yaml;};

  # First admin is seeded from sops on first boot. USER_EMAIL/USER_PASSWORD only
  # take effect while the hub DB is empty, so this is a no-op on later boots.
  # Rendered to an env file so the values never land in the Nix store.
  sops.templates."beszel-hub.env" = {
    restartUnits = ["beszel-hub.service"];
    content = ''
      USER_EMAIL=${config.sops.placeholder."beszel/admin_email"}
      USER_PASSWORD=${config.sops.placeholder."beszel/admin_password"}
    '';
  };

  # Binds all interfaces so agents on midgard/alfheim can reach it over the
  # tailnet (trusted iface, not firewalled publicly); Caddy fronts the browser
  # UI at beszel.ridewithmin.com.
  services.beszel.hub = {
    enable = true;
    host = "0.0.0.0";
    port = 8090;
    environmentFile = config.sops.templates."beszel-hub.env".path;
  };
}
