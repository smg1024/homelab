{
  inputs,
  pkgs,
  ...
}: let
  blog = inputs.blog.packages.${pkgs.stdenv.hostPlatform.system}.default;
  siteRoot = "${blog}/${blog.passthru.sitePath}";
in {
  systemd.services.static-web-server-blog = {
    description = "Dev with Min static site";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];

    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.static-web-server}/bin/static-web-server --host 0.0.0.0 --port 8083 --root ${siteRoot} --log-level error";
      Restart = "on-failure";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
}
