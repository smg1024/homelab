{
  inputs,
  pkgs,
  ...
}: let
  docs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.docs;
in {
  services.caddy.virtualHosts."docs.ridewithmin.com".extraConfig = ''
    @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48

    handle @tailnet {
      root * ${docs}
      file_server
    }

    respond 404
  '';
}
