#!/usr/bin/env bash
set -euo pipefail

export FAILOVER_PGDATA="$HOME/failover_pgdata"
export BACKUP_BASE_DIR="$HOME/backup/base"
export ARCHIVE_DIR="$HOME/archive"
export STANDBY_PORT=9099
export DB_NAME=bigbluecity

echo "Run this stage on standby: postgres2@pg132"

pg_ctl -D "$FAILOVER_PGDATA" stop -m fast >/dev/null 2>&1 || true
rm -rf "$FAILOVER_PGDATA"
mkdir -p "$FAILOVER_PGDATA"
chmod 700 "$FAILOVER_PGDATA"
rsync -aH --delete "$BACKUP_BASE_DIR/" "$FAILOVER_PGDATA/"

cat >> "$FAILOVER_PGDATA/postgresql.auto.conf" <<CONF
port = '$STANDBY_PORT'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "$FAILOVER_PGDATA/recovery.signal"
pg_ctl -D "$FAILOVER_PGDATA" -l "$FAILOVER_PGDATA/startup.log" start
sleep 5
pg_isready -p "$STANDBY_PORT"
psql -v ON_ERROR_STOP=1 -p "$STANDBY_PORT" -d "$DB_NAME" -c "SELECT current_setting('port') AS port, pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"
