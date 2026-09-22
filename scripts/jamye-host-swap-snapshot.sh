#!/usr/bin/env bash
# Run as root on the OLD app host, during the agreed maintenance window.
set -euo pipefail
umask 077

app=${1:?Expected jamye-plz or jamye-server}
case "$app:$(uname -n)" in
  jamye-plz:alfheim) database=jamye ;;
  jamye-server:midgard) database=jamye-server ;;
  *) echo "Unexpected application/source host" >&2; exit 1 ;;
esac
test "$(id -u)" = 0
bundle="/var/lib/jamye-host-swap/2026-09-17/$app"
test ! -e "$bundle"
install -d -m 0700 "$bundle"

if [ "$app" = jamye-server ]; then
  # Stopping the target also stops PostgreSQL via PartOf. Restart only the
  # database to take the logical dump; application writers remain stopped.
  systemctl stop jamye-server.target
  systemctl start postgresql.target
else
  systemctl stop jamye-plz-backend.service jamye-plz-stt-worker.service
  systemctl stop caddy.service minio.service redis-jamye-plz.service
fi

# Redis writes its final RDB on a clean shutdown. Never copy a live MinIO tree.
for unit in minio "redis-$app"; do
  if systemctl is-active --quiet "$unit"; then
    echo "Refusing to snapshot running $unit" >&2
    exit 1
  fi
done
runuser -u postgres -- pg_dump --format=custom --dbname="$database" > "$bundle/database.dump"
runuser -u postgres -- psql -X -At -v ON_ERROR_STOP=1 --dbname="$database" > "$bundle/table-counts.txt" <<'SQL'
SELECT format('SELECT %L || ''|'' || count(*) FROM %I.%I;', schemaname || '.' || tablename, schemaname, tablename)
FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
\gexec
SQL
tar -C /var/lib/minio/data -cf "$bundle/minio.tar" .
tar -C "/var/lib/$app" -cf "$bundle/app.tar" .
cp "/var/lib/redis-$app/dump.rdb" "$bundle/redis.rdb"
printf '%s\n' "$app" > "$bundle/application"
cd "$bundle"
sha256sum database.dump table-counts.txt minio.tar app.tar redis.rdb application > SHA256SUMS
touch SNAPSHOT_COMPLETE
echo "Snapshot complete: $bundle (source application remains stopped)"
