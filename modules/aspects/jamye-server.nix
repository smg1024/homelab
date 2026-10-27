{inputs, ...}: {
  den.aspects.jamye-server.nixos = {
    config,
    lib,
    pkgs,
    ...
  }: let
    secretFile = ../../secrets/jamye-server.yaml;
  in {
    # shortcut: MinIO is abandoned; keep Jamye's module pin until it migrates storage.
    disabledModules = ["rename.nix"];
    imports = [
      (import "${inputs.nixpkgs}/nixos/modules/rename.nix" {
        lib =
          lib
          // {
            mkRemovedOptionModule = path: message:
              if path == ["services" "minio"]
              then {}
              else lib.mkRemovedOptionModule path message;
          };
      })
      "${inputs.jamye-server.inputs.nixpkgs}/nixos/modules/services/web-servers/minio.nix"
      inputs.jamye-server.nixosModules.default
    ];

    # Jamye's bucket and identity setup still uses this abandoned client.
    nixpkgs.config.permittedInsecurePackages = ["minio-client-2025-08-13T08-35-41Z"];

    # Keep the application's PostgreSQL major version when moving hosts.
    services.postgresql.package = pkgs.postgresql_17;
    services.minio.dataDir = ["/var/lib/jamye-server-minio/data"];

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

        # Caddy on yggdrasil is the only proxy whose single-value X-Forwarded-For
        # the API trusts; Caddy sets it from CF-Connecting-IP (modules/aspects/ingress.nix).
        JAMYE_TRUSTED_PROXIES=100.121.86.93

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
        # this public API origin. The raised limit predates per-client keys and
        # is kept for now, to revisit later.
        JAMYE_AVATAR_PUBLIC_BASE_URL=https://jamye-api.ridewithmin.com
        JAMYE_RATE_LIMIT_AVATAR_PUBLIC_READ_LIMIT=6000
        JAMYE_RATE_LIMIT_AVATAR_PUBLIC_READ_WINDOW_SECONDS=60

        # Universal links (server task-20a): both iOS apps.
        JAMYE_APP_LINKS_AASA_APP_IDS=6ZH8V43A7D.dev.local.jamyeapp,6ZH8V43A7D.com.ridewithmin.jamyeapp
        # Android app links: the production package only (assetlinks takes one
        # package), signed by the Play App Signing key (Play installs) and the
        # EAS upload key (direct installs of the uploaded bundle). Both are
        # public certificate fingerprints.
        JAMYE_APP_LINKS_ANDROID_PACKAGE=com.ridewithmin.jamyeapp
        JAMYE_APP_LINKS_ANDROID_SHA256_CERT_FINGERPRINTS=49:41:D9:82:E0:A9:9E:25:78:27:4F:53:90:57:D4:89:11:86:3E:09:A3:96:87:19:B4:EF:51:84:63:FC:8D:87,48:AE:FB:79:97:23:FF:79:C8:07:13:CF:70:A4:E0:14:C2:54:C1:79:27:B2:A3:A7:B1:A0:96:02:47:6E:1B:48

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
  };
}
