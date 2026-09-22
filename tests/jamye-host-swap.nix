{pkgs}: let
  # Exercise the production restore script against disposable PostgreSQL
  # clusters. Only host identity, ownership, and /var/lib are sandboxed.
  restoreScript = pkgs.writeText "jamye-host-swap-restore-test.sh" (
    builtins.replaceStrings ["/var/lib"] ["$JAMYE_TEST_DATA"]
    (builtins.readFile ../scripts/jamye-host-swap-restore.sh)
  );
  check = app: postgres:
    pkgs.runCommand "${app}-host-swap-restore-check" {
      nativeBuildInputs = [postgres pkgs.coreutils pkgs.diffutils pkgs.findutils pkgs.gnutar];
    } ''
      export JAMYE_TEST_DATA="$TMPDIR/state"
      export PGHOST="$TMPDIR/socket" PGUSER=postgres
      export JAMYE_SWAP_APP=${app}
      mkdir -p "$PGHOST"
      initdb -D "$TMPDIR/pg" -U postgres --auth=trust --no-locale >/dev/null
      pg_ctl -D "$TMPDIR/pg" -o "-F -h ''' -k $PGHOST" -w start >/dev/null
      trap 'pg_ctl -D "$TMPDIR/pg" -m immediate -w stop >/dev/null' EXIT

      if [ "$JAMYE_SWAP_APP" = jamye-plz ]; then
        database=jamye
        export JAMYE_TEST_HOST=midgard
      else
        database=jamye-server
        export JAMYE_TEST_HOST=alfheim
      fi
      uname() { echo "$JAMYE_TEST_HOST"; }
      runuser() { shift 3; "$@"; }
      chown() { :; }
      install() {
        local args=()
        while [ "$#" -gt 0 ]; do
          case "$1" in
            -o|-g) shift 2 ;;
            *) args+=("$1"); shift ;;
          esac
        done
        ${pkgs.coreutils}/bin/install "''${args[@]}"
      }
      export -f uname runuser chown install
      expect_failure() {
        if ${pkgs.bash}/bin/bash ${restoreScript}; then
          echo "Restore unexpectedly succeeded: $1" >&2
          exit 1
        fi
      }

      expect_failure "missing snapshot"
      createuser "$database"
      createdb --owner="$database" "$database"
      psql -v ON_ERROR_STOP=1 -d "$database" -c 'CREATE TABLE messages (id int PRIMARY KEY); INSERT INTO messages VALUES (1), (2);'
      bundle="$JAMYE_TEST_DATA/jamye-host-swap/2026-09-17/$JAMYE_SWAP_APP"
      mkdir -p "$bundle" "$TMPDIR/media" "$TMPDIR/app"
      pg_dump -Fc -d "$database" > "$bundle/database.dump"
      echo 'public.messages|2' > "$bundle/table-counts.txt"
      echo 'media fixture' > "$TMPDIR/media/object"
      echo 'app fixture' > "$TMPDIR/app/state"
      tar -C "$TMPDIR/media" -cf "$bundle/minio.tar" .
      tar -C "$TMPDIR/app" -cf "$bundle/app.tar" .
      echo 'redis fixture' > "$bundle/redis.rdb"
      echo "$JAMYE_SWAP_APP" > "$bundle/application"
      touch "$bundle/SNAPSHOT_COMPLETE"
      cd "$bundle"
      sha256sum database.dump table-counts.txt minio.tar app.tar redis.rdb application > SHA256SUMS
      expect_failure "nonempty database"
      psql -v ON_ERROR_STOP=1 -d "$database" -c 'DROP TABLE messages;'
      echo 'corruption' >> redis.rdb
      expect_failure "corrupt snapshot"
      echo 'redis fixture' > redis.rdb

      ${pkgs.bash}/bin/bash ${restoreScript}
      test -f RESTORE_COMPLETE
      test "$(psql -At -d "$database" -c 'SELECT count(*) FROM messages')" = 2
      cmp "$TMPDIR/media/object" "$JAMYE_TEST_DATA/$JAMYE_SWAP_APP-minio/data/object"
      cmp "$TMPDIR/app/state" "$JAMYE_TEST_DATA/$JAMYE_SWAP_APP/state"
      cmp redis.rdb "$JAMYE_TEST_DATA/redis-$JAMYE_SWAP_APP/dump.rdb"
      psql -v ON_ERROR_STOP=1 -d "$database" -c 'INSERT INTO messages VALUES (3);'
      ${pkgs.bash}/bin/bash ${restoreScript}
      test "$(psql -At -d "$database" -c 'SELECT count(*) FROM messages')" = 3
      touch "$out"
    '';
in
  pkgs.runCommand "jamye-host-swap-restore-check" {
    checks = [
      (check "jamye-plz" pkgs.postgresql_18)
      (check "jamye-server" pkgs.postgresql_17)
    ];
  } ''
    for check in $checks; do test -f "$check"; done
    touch "$out"
  ''
