{config, ...}: let
  hostName = config.networking.hostName;
  hubUrl =
    if hostName == "yggdrasil"
    then "http://127.0.0.1:8090"
    else "http://yggdrasil.tail6fc192.ts.net:8090";
in {
  sops.secrets."beszel/hub_key" = {sopsFile = ../../secrets/beszel.yaml;};
  sops.secrets."beszel/universal_token" = {sopsFile = ../../secrets/beszel.yaml;};

  # KEY (hub public key) + TOKEN (universal token) let the agent authenticate and
  # self-register over WebSocket. Rendered to an env file so values never land in
  # the Nix store.
  sops.templates."beszel-agent.env" = {
    restartUnits = ["beszel-agent.service"];
    content = ''
      KEY=${config.sops.placeholder."beszel/hub_key"}
      TOKEN=${config.sops.placeholder."beszel/universal_token"}
    '';
  };

  services.beszel.agent = {
    enable = true;
    environment = {
      HUB_URL = hubUrl;
      SYSTEM_NAME = hostName;
    };
    environmentFile = config.sops.templates."beszel-agent.env".path;
  };
}
