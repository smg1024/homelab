# One-time, fail-closed import for the September 2026 host swap. Keep the
# completion stamp and source snapshots until the migration is retired.
{
  config,
  lib,
  pkgs,
  ...
}: let
  app =
    if config.networking.hostName == "midgard"
    then "jamye-plz"
    else "jamye-server";
  restoreUnit = "jamye-host-swap.service";
  gatedUnits =
    ["minio" "redis-${app}" "${app}-migrate"]
    ++ lib.optionals (app == "jamye-plz") ["caddy"];
in {
  systemd.services =
    lib.genAttrs gatedUnits (_: {
      requires = [restoreUnit];
      after = [restoreUnit];
    })
    // {
      jamye-host-swap = {
        description = "Restore ${app} before its first start on the new host";
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
          export JAMYE_SWAP_APP=${lib.escapeShellArg app}
          ${builtins.readFile ../scripts/jamye-host-swap-restore.sh}
        '';
      };
    };
}
