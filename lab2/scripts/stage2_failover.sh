#!/usr/bin/env bash
set -euo pipefail

export FAILOVER_PGDATA="$HOME/failover_pgdata"
export STANDBY_TS1="$HOME/sbm10"
export STANDBY_TS2="$HOME/nym69"
export BACKUP_BASE_DIR="$HOME/backup/base"
export BACKUP_TS1_DIR="$HOME/backup/tblspc/sbm10"
export BACKUP_TS2_DIR="$HOME/backup/tblspc/nym69"
export ARCHIVE_DIR="$HOME/archive"
export STANDBY_PORT=9099
export DB_NAME=bigbluecity
export DB_USER=dbuser
export DB_PASSWORD=secure_password_123

echo "Run this stage on standby: postgres2@pg132"

pg_ctl -D "$FAILOVER_PGDATA" stop -m fast >/dev/null 2>&1 || true
rm -rf "$FAILOVER_PGDATA" "$STANDBY_TS1" "$STANDBY_TS2"
mkdir -p "$FAILOVER_PGDATA" "$STANDBY_TS1" "$STANDBY_TS2"
rsync -aH --delete "$BACKUP_BASE_DIR/" "$FAILOVER_PGDATA/"
rsync -aH --delete "$BACKUP_TS1_DIR/" "$STANDBY_TS1/"
rsync -aH --delete "$BACKUP_TS2_DIR/" "$STANDBY_TS2/"
chmod 700 "$FAILOVER_PGDATA"

bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '$FAILOVER_PGDATA'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='$STANDBY_TS1' ;;
    *nym69*) TS_MAP["\${oid}"]='$STANDBY_TS2' ;;
  esac
done
rm -f '$FAILOVER_PGDATA'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '$FAILOVER_PGDATA'/pg_tblspc/"\${oid}"
done
EOF

cat >> "$FAILOVER_PGDATA/postgresql.auto.conf" <<CONF
port = '$STANDBY_PORT'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "$FAILOVER_PGDATA/recovery.signal"
if ! pg_ctl -D "$FAILOVER_PGDATA" -l "$FAILOVER_PGDATA/startup.log" start; then
  echo
  echo "Startup log:"
  cat "$FAILOVER_PGDATA/startup.log"
  exit 1
fi
sleep 5
pg_isready -p "$STANDBY_PORT"
PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h localhost -U "$DB_USER" -p "$STANDBY_PORT" -d "$DB_NAME" -c "SELECT current_setting('port') AS port, pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"
