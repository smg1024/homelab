{
  inputs,
  pkgs,
  ...
}: let
  docs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.docs;
in {
  systemd.services.static-web-server-docs = {
    description = "Homelab docs static site";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.static-web-server}/bin/static-web-server --host 0.0.0.0 --port 8084 --root ${docs} --log-level error";
      Restart = "on-failure";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
