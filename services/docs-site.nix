{
  inputs,
  pkgs,
  ...
}: let
  docs = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.docs;
in {
  services.caddy.virtualHosts."docs.ridewithmin.com".extraConfig = ''
    root * ${docs}
    file_server
  '';
}
