{config, ...}: let
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
}
