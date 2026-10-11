# One-time, fail-closed import for the October 2026 jamye-server host move.
# Keep the completion stamp and source snapshots until the migration is retired.
{
  config,
  lib,
  pkgs,
  ...
}: let
  restoreUnit = "jamye-host-swap.service";
  gatedUnits = [
    "minio"
    "redis-jamye-server"
    "jamye-server-minio-identities"
    "jamye-server-migrate"
    "jamye-server-api"
    "jamye-server-worker"
  ];
in {
  assertions = [
    {
      assertion = config.networking.hostName == "alfheim";
      message = "services/jamye-host-swap.nix is only valid on alfheim";
    }
  ];

  systemd.targets.jamye-server = {
    requires = [restoreUnit];
    after = [restoreUnit];
  };

  systemd.services =
    lib.genAttrs gatedUnits (_: {
      requires = [restoreUnit];
      after = [restoreUnit];
    })
    // {
      jamye-host-swap = {
        description = "Restore jamye-server before its first start on alfheim";
        requires = ["postgresql.target"];
        after = ["postgresql.target"];
        path = [
          pkgs.coreutils
          pkgs.diffutils
          pkgs.findutils
          pkgs.gnutar
          pkgs.util-linux
          config.services.postgresql.package
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          UMask = "0077";
          TimeoutStartSec = "10min";
        };
        script = ''
          ${builtins.readFile ../scripts/jamye-host-swap-restore.sh}
        '';
      };
    };
}
