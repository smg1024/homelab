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

  sops.secrets."jamye-server/kakao_client_id".sopsFile = secretFile;
  sops.secrets."jamye-server/kakao_client_secret".sopsFile = secretFile;
  sops.secrets."jamye-server/google_client_id".sopsFile = secretFile;
  sops.secrets."jamye-server/google_client_secret".sopsFile = secretFile;
  sops.secrets."jamye-server/apple_team_id".sopsFile = secretFile;
  sops.secrets."jamye-server/apple_key_id".sopsFile = secretFile;
  sops.secrets."jamye-server/apple_private_key".sopsFile = secretFile;

  sops.secrets."jamye-server/legal_operator_name".sopsFile = secretFile;
  sops.secrets."jamye-server/legal_contact_email".sopsFile = secretFile;
  sops.secrets."jamye-server/legal_operator_address".sopsFile = secretFile;
  sops.secrets."jamye-server/operator_account_ids".sopsFile = secretFile;

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

      JAMYE_KAKAO_OAUTH_ENABLED=true
      JAMYE_KAKAO_CLIENT_ID=${config.sops.placeholder."jamye-server/kakao_client_id"}
      JAMYE_KAKAO_CLIENT_SECRET=${config.sops.placeholder."jamye-server/kakao_client_secret"}
      JAMYE_KAKAO_REDIRECT_URIS=https://jamye-api.ridewithmin.com/api/v1/auth/oauth/kakao/callback

      JAMYE_GOOGLE_OAUTH_ENABLED=true
      JAMYE_GOOGLE_CLIENT_ID=${config.sops.placeholder."jamye-server/google_client_id"}
      JAMYE_GOOGLE_CLIENT_SECRET=${config.sops.placeholder."jamye-server/google_client_secret"}
      JAMYE_GOOGLE_REDIRECT_URIS=https://jamye-api.ridewithmin.com/api/v1/auth/oauth/google/callback

      # Sign in with Apple (native iOS). The audiences are the app bundle ids
      # (development and production, grouped under one primary App ID so one
      # key serves both); the .p8 key is stored in SOPS as a single-line
      # base64 PKCS#8 body.
      JAMYE_APPLE_SIGNIN_ENABLED=true
      JAMYE_APPLE_AUDIENCES=dev.local.jamyeapp,com.ridewithmin.jamyeapp
      JAMYE_APPLE_TEAM_ID=${config.sops.placeholder."jamye-server/apple_team_id"}
      JAMYE_APPLE_KEY_ID=${config.sops.placeholder."jamye-server/apple_key_id"}
      JAMYE_APPLE_PRIVATE_KEY=${config.sops.placeholder."jamye-server/apple_private_key"}

      # Avatar hosting (server task-19). Hosted avatar URLs are minted under
      # this public API origin. Behind the proxy every client shares one
      # public-read bucket, so the limit is raised above the 600/60s default.
      JAMYE_AVATAR_PUBLIC_BASE_URL=https://jamye-api.ridewithmin.com
      JAMYE_RATE_LIMIT_AVATAR_PUBLIC_READ_LIMIT=6000
      JAMYE_RATE_LIMIT_AVATAR_PUBLIC_READ_WINDOW_SECONDS=60

      # Universal links (server task-20a): both iOS apps. Android app links
      # keep the server's development defaults until the production upload
      # key fingerprint exists.
      JAMYE_APP_LINKS_AASA_APP_IDS=6ZH8V43A7D.dev.local.jamyeapp,6ZH8V43A7D.com.ridewithmin.jamyeapp

      # Public legal pages /privacy, /terms, /account-deletion, /support
      # (server task-20a).
      JAMYE_LEGAL_OPERATOR_NAME=${config.sops.placeholder."jamye-server/legal_operator_name"}
      JAMYE_LEGAL_CONTACT_EMAIL=${config.sops.placeholder."jamye-server/legal_contact_email"}
      JAMYE_LEGAL_OPERATOR_ADDRESS=${config.sops.placeholder."jamye-server/legal_operator_address"}

      # Accounts that receive the report alert push (server task-20b).
      JAMYE_OPERATOR_ACCOUNT_IDS=${config.sops.placeholder."jamye-server/operator_account_ids"}
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
