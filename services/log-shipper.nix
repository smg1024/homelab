{
  config,
  pkgs,
  ...
}: let
  hostName = config.networking.hostName;
  vlInsertUrl =
    if hostName == "yggdrasil"
    then "http://127.0.0.1:9428/internal/insert"
    else "http://yggdrasil.tail6fc192.ts.net:9428/internal/insert";
in {
  services.vlagent = {
    enable = true;
    remoteWrite.url = vlInsertUrl;
  };

  services.journald.upload = {
    enable = true;
    settings.Upload.URL = "http://localhost:9429/insert/journald";
  };

  # journal-upload POSTs to the local vlagent listener (9429). Without ordering it
  # races vlagent on boot, exits with EIO, and its failed state fails
  # `nixos-rebuild switch`. Order it after vlagent and block until the listener
  # accepts connections so the unit starts cleanly on cold boots and deploys.
  systemd.services.systemd-journal-upload = {
    after = ["vlagent.service"];
    wants = ["vlagent.service"];
    serviceConfig.ExecStartPre = "${pkgs.curl}/bin/curl --retry 30 --retry-delay 1 --retry-all-errors -sS -o /dev/null http://localhost:9429/health";
  };
}
