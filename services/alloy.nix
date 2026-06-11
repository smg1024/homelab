{
  config,
  lib,
  ...
}: let
  hostName = config.networking.hostName;
  lokiPushUrl =
    if hostName == "yggdrasil"
    then "http://127.0.0.1:3100/loki/api/v1/push"
    else "http://yggdrasil.tail6fc192.ts.net:3100/loki/api/v1/push";
in {
  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:12345"
      "--disable-reporting"
    ];
  };

  systemd.services.alloy.serviceConfig.SupplementaryGroups = lib.mkAfter [
    "adm"
  ];

  environment.etc."alloy/config.alloy".text = ''
    logging {
      level = "info"
    }

    loki.source.journal "system" {
      forward_to = [loki.write.homelab.receiver]
      labels     = {node = "${hostName}", source = "journald"}
      max_age    = "30m"
    }

    loki.write "homelab" {
      endpoint {
        url = "${lokiPushUrl}"
      }

      external_labels = {
        cluster = "homelab",
      }
    }
  '';
}
