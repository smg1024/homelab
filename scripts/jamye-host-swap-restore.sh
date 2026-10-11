#!/usr/bin/env bash
# Invoked on alfheim by the declared systemd unit, after PostgreSQL role and
# database setup and before jamye-server infrastructure or application units.
set -euo pipefail
umask 077

app=jamye-server
database=jamye-server
app_user=jamye-server
test "$(uname -n)" = alfheim || {
  echo "Unexpected destination host" >&2
  exit 1
}
bundle="/var/lib/jamye-host-swap/2026-10-11/$app"
test -f "$bundle/RESTORE_COMPLETE" && exit 0
test -f "$bundle/SNAPSHOT_COMPLETE"
cd "$bundle"
test "$(cat application)" = "$app"
sha256sum --check --quiet SHA256SUMS

if [ ! -f database-restored ]; then
  user_objects=$(runuser -u postgres -- psql -X -At -v ON_ERROR_STOP=1 --dbname="$database" <<'SQL'
WITH user_objects AS (
  SELECT c.oid
  FROM pg_class AS c
  JOIN pg_namespace AS n ON n.oid = c.relnamespace
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
    AND c.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
  UNION ALL
  SELECT p.oid
  FROM pg_proc AS p
  JOIN pg_namespace AS n ON n.oid = p.pronamespace
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
  UNION ALL
  SELECT t.oid
  FROM pg_type AS t
  JOIN pg_namespace AS n ON n.oid = t.typnamespace
  WHERE n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
  UNION ALL
  SELECT n.oid
  FROM pg_namespace AS n
  WHERE n.nspname <> 'public'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_'
  UNION ALL
  SELECT e.oid
  FROM pg_extension AS e
  WHERE e.extname <> 'plpgsql'
)
SELECT count(*) FROM user_objects;
SQL
  )
  test "$user_objects" = 0 || { echo "Destination database contains user objects; refusing to overwrite it" >&2; exit 1; }
  runuser -u postgres -- pg_restore --exit-on-error --single-transaction \
    --no-owner --role="$app_user" --dbname="$database" < database.dump
  touch database-restored
fi
runuser -u postgres -- psql -X -At -v ON_ERROR_STOP=1 --dbname="$database" > restored-table-counts.txt <<'SQL'
SELECT format('SELECT %L || ''|'' || count(*) FROM %I.%I;', schemaname || '.' || tablename, schemaname, tablename)
FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
\gexec
SQL
diff -u table-counts.txt restored-table-counts.txt

restore_tree() {
  local archive=$1 destination=$2 owner=$3 stamp=$4
  if [ ! -f "$stamp" ]; then
    if [ -d "$destination" ] && [ -n "$(find "$destination" -mindepth 1 -print -quit)" ]; then
      echo "Destination $destination is not empty; refusing to overwrite it" >&2
      exit 1
    fi
    install -d -m 0750 "$destination"
    tar --no-same-owner -C "$destination" -xf "$archive"
    chown -R "$owner:$owner" "$destination"
    touch "$stamp"
  fi
}
restore_tree minio.tar "/var/lib/$app-minio/data" minio minio-restored
restore_tree app.tar "/var/lib/$app" "$app_user" app-restored
if [ ! -f redis-restored ]; then
  redis_dir="/var/lib/redis-$app"
  test ! -e "$redis_dir/dump.rdb"
  install -d -m 0700 -o "redis-$app" -g "redis-$app" "$redis_dir"
  install -m 0600 -o "redis-$app" -g "redis-$app" redis.rdb "$redis_dir/dump.rdb"
  touch redis-restored
fi
touch RESTORE_COMPLETE
echo "Restored $app; database row counts and snapshot checksums verified"
