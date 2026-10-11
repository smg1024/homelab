{
  config,
  inputs,
  ...
}: let
  # Remove once the upstream module and frontend package stop using the
  # deprecated `pkgs.system`.
  patchedNixpkgs =
    inputs.jamye-plz.inputs.nixpkgs
    // {
      legacyPackages =
        builtins.mapAttrs (
          system: pkgs: pkgs // {inherit system;}
        )
        inputs.jamye-plz.inputs.nixpkgs.legacyPackages;
    };
  jamyePlz =
    (import "${inputs.jamye-plz}/flake.nix").outputs
    (inputs.jamye-plz.inputs
      // {
        self = jamyePlz;
        nixpkgs = patchedNixpkgs;
      });
  jamyePlzModule = moduleArgs @ {pkgs, ...}:
    jamyePlz.nixosModules.default
    (moduleArgs
      // {
        pkgs = pkgs // {system = pkgs.stdenv.hostPlatform.system;};
      });
in {
  imports = [jamyePlzModule];

  sops.secrets."jamye-plz/jwt_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/kakao_client_id" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/kakao_client_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/google_client_id" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/google_client_secret" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/minio_root_user" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/minio_root_password" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/minio_access_key" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/minio_secret_key" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/vapid_private_key" = {sopsFile = ../secrets/jamye-plz.yaml;};
  sops.secrets."jamye-plz/vapid_public_key" = {sopsFile = ../secrets/jamye-plz.yaml;};

  sops.templates."jamye-plz-minio-root.env" = {
    restartUnits = ["minio.service"];
    content = ''
      MINIO_ROOT_USER=${config.sops.placeholder."jamye-plz/minio_root_user"}
      MINIO_ROOT_PASSWORD=${config.sops.placeholder."jamye-plz/minio_root_password"}
    '';
  };

  sops.templates."jamye-plz.env" = {
    owner = "jamye";
    restartUnits = ["jamye-plz-backend.service"];
    content = ''
      JWT_SECRET=${config.sops.placeholder."jamye-plz/jwt_secret"}
      KAKAO_CLIENT_ID=${config.sops.placeholder."jamye-plz/kakao_client_id"}
      KAKAO_CLIENT_SECRET=${config.sops.placeholder."jamye-plz/kakao_client_secret"}
      GOOGLE_CLIENT_ID=${config.sops.placeholder."jamye-plz/google_client_id"}
      GOOGLE_CLIENT_SECRET=${config.sops.placeholder."jamye-plz/google_client_secret"}
      MINIO_ACCESS_KEY=${config.sops.placeholder."jamye-plz/minio_access_key"}
      MINIO_SECRET_KEY=${config.sops.placeholder."jamye-plz/minio_secret_key"}
      KAKAO_REDIRECT_URI=https://jamye-plz.ridewithmin.com/api/auth/kakao/callback
      GOOGLE_REDIRECT_URI=https://jamye-plz.ridewithmin.com/api/auth/google/callback
      FRONTEND_ORIGIN=https://jamye-plz.ridewithmin.com
      VAPID_PRIVATE_KEY=${config.sops.placeholder."jamye-plz/vapid_private_key"}
      VAPID_PUBLIC_KEY=${config.sops.placeholder."jamye-plz/vapid_public_key"}
      VAPID_CLAIM_EMAIL=smg981024@gmail.com
    '';
  };

  services.jamye-plz = {
    enable = true;
    listenPort = 8080;
    environmentFile = config.sops.templates."jamye-plz.env".path;
    storage = {
      publicUrl = "https://minio.ridewithmin.com";
      rootCredentialsFile = config.sops.templates."jamye-plz-minio-root.env".path;
    };
  };
}
