{
  config,
  inputs,
  ...
}: let
  secretFile = ../secrets/jamye-server.yaml;
in {
  imports = [
    inputs.jamye-server.nixosModules.default
  ];

  sops.secrets."jamye-server/access_token_secret".sopsFile = secretFile;

  sops.secrets."jamye-server/minio_root_user".sopsFile = secretFile;
  sops.secrets."jamye-server/minio_root_password".sopsFile = secretFile;

  sops.secrets."jamye-server/media_access_key".sopsFile = secretFile;
  sops.secrets."jamye-server/media_secret_key".sopsFile = secretFile;

  sops.secrets."jamye-server/cleanup_access_key".sopsFile = secretFile;
  sops.secrets."jamye-server/cleanup_secret_key".sopsFile = secretFile;

  sops.templates."jamye-server.env" = {
    owner = "jamye-server";
    group = "jamye-server";
    mode = "0400";
    restartUnits = [
      "jamye-server-api.service"
      "jamye-server-worker.service"
    ];
    content = ''
      JAMYE_ACCESS_TOKEN_SECRET=${config.sops.placeholder."jamye-server/access_token_secret"}
      JAMYE_ACCESS_TOKEN_ISSUER=https://jamye-api.ridewithmin.com
      JAMYE_ACCESS_TOKEN_AUDIENCE=jamye-app

      JAMYE_KAKAO_OAUTH_ENABLED=false
      JAMYE_GOOGLE_OAUTH_ENABLED=false
    '';
  };

  sops.templates."jamye-server-media.env" = {
    owner = "jamye-server";
    group = "jamye-server";
    mode = "0400";
    restartUnits = [
      "jamye-server-minio-identities.service"
      "jamye-server-api.service"
      "jamye-server-worker.service"
    ];
    content = ''
      JAMYE_OBJECT_STORAGE_ACCESS_KEY_ID=${config.sops.placeholder."jamye-server/media_access_key"}
      JAMYE_OBJECT_STORAGE_SECRET_ACCESS_KEY=${config.sops.placeholder."jamye-server/media_secret_key"}
    '';
  };

  sops.templates."jamye-server-cleanup.env" = {
    owner = "jamye-server";
    group = "jamye-server";
    mode = "0400";
    restartUnits = [
      "jamye-server-minio-identities.service"
      "jamye-server-worker.service"
    ];
    content = ''
      JAMYE_ACCOUNT_OBJECT_DELETION_ACCESS_KEY_ID=${config.sops.placeholder."jamye-server/cleanup_access_key"}
      JAMYE_ACCOUNT_OBJECT_DELETION_SECRET_ACCESS_KEY=${config.sops.placeholder."jamye-server/cleanup_secret_key"}
    '';
  };

  sops.templates."jamye-server-minio-root.env" = {
    mode = "0400";
    restartUnits = [
      "minio.service"
      "jamye-server-minio-identities.service"
    ];
    content = ''
      MINIO_ROOT_USER=${config.sops.placeholder."jamye-server/minio_root_user"}
      MINIO_ROOT_PASSWORD=${config.sops.placeholder."jamye-server/minio_root_password"}
    '';
  };

  services.jamye-server = {
    enable = true;

    # midgard의 8080은 현재 비어 있습니다.
    listenAddress = "0.0.0.0:8080";
    environmentFile = config.sops.templates."jamye-server.env".path;

    objectStorage = {
      publicEndpoint = "https://jamye-media.ridewithmin.com";
      bucket = "jamye-server-media";

      mediaCredentialsFile =
        config.sops.templates."jamye-server-media.env".path;
      cleanupCredentialsFile =
        config.sops.templates."jamye-server-cleanup.env".path;
      rootCredentialsFile =
        config.sops.templates."jamye-server-minio-root.env".path;
    };
  };
}
