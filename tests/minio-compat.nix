{
  pkgs,
  hosts,
}: let
  inherit (pkgs) lib;
  config = hosts.alfheim.config;
  removed = hosts.alfheim.extendModules {
    modules = [{services.mesos.enable = true;}];
  };
in
  assert lib.assertMsg config.services.minio.enable "Jamye's MinIO service must remain enabled";
  assert lib.assertMsg
  (config.services.minio.dataDir == ["/var/lib/jamye-server-minio/data"])
  "MinIO must keep the existing media directory";
  assert lib.assertMsg
  (config.systemd.services.minio.serviceConfig.User
    == "minio"
    && config.systemd.services.minio.serviceConfig.EnvironmentFile == config.sops.templates."jamye-server-minio-root.env".path)
  "MinIO must retain its service account and runtime credentials";
  assert lib.assertMsg
  (config.nixpkgs.config.permittedInsecurePackages
    == ["minio-client-2025-08-13T08-35-41Z"]
    && lib.all (name:
      !(hosts.${name}.config.systemd.services ? minio)
      && !(lib.any (lib.hasPrefix "minio") (hosts.${name}.config.nixpkgs.config.permittedInsecurePackages or []))) ["midgard" "yggdrasil"])
  "MinIO and its client exception must stay scoped to alfheim";
  assert lib.assertMsg
  (lib.any (entry: !entry.assertion && lib.hasInfix "services.mesos" entry.message) removed.config.assertions)
  "MinIO compatibility must preserve unrelated removed-option checks";
    pkgs.runCommand "minio-compat-check" {} ''
      touch "$out"
    ''
