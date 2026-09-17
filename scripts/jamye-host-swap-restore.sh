#!/usr/bin/env bash
# Invoked by the declared systemd unit, after PostgreSQL role/database setup
# and before MinIO, Redis, migrations, or the application's public listener.
set -euo pipefail
umask 077

app=${JAMYE_SWAP_APP:?Missing application}
case "$app:$(uname -n)" in
  jamye-plz:midgard) database=jamye; app_user=jamye ;;
  jamye-server:alfheim) database=jamye-server; app_user=jamye-server ;;
  *) echo "Unexpected application/destination host" >&2; exit 1 ;;
esac
bundle="/var/lib/jamye-host-swap/2026-09-17/$app"
test -f "$bundle/RESTORE_COMPLETE" && exit 0
test -f "$bundle/SNAPSHOT_COMPLETE"
cd "$bundle"
test "$(cat application)" = "$app"
sha256sum --check --quiet SHA256SUMS

if [ ! -f database-restored ]; then
  tables=$(runuser -u postgres -- psql -X -At -v ON_ERROR_STOP=1 --dbname="$database" \
    -c "SELECT count(*) FROM pg_tables WHERE schemaname = 'public'")
  test "$tables" = 0 || { echo "Destination database is not empty; refusing to overwrite it" >&2; exit 1; }
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
