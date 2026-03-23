#!/usr/bin/env bash
set -euo pipefail

export PRIMARY_PGDATA="$HOME/nwc36"
export PRIMARY_PORT=9099
export PRIMARY_TS1="$HOME/sbm10"
export PRIMARY_TS2="$HOME/nym69"
export ARCHIVE_DIR="$HOME/archive"
export BACKUP_DIR="$HOME/backup"
export BACKUP_BASE_DIR="$BACKUP_DIR/base"
export BACKUP_TS1_DIR="$BACKUP_DIR/tblspc/sbm10"
export BACKUP_TS2_DIR="$BACKUP_DIR/tblspc/nym69"
export STANDBY_USER=postgres2
export STANDBY_HOST=pg132
export STANDBY_ARCHIVE_DIR=/var/db/postgres2/archive
export STANDBY_BACKUP_DIR=/var/db/postgres2/backup
export PRIMARY_RESTORE_PGDATA="$HOME/nwc36_restore"

for cmd in psql pg_ctl pg_basebackup rsync scp ssh; do
  command -v "${cmd}" >/dev/null
done

if pg_ctl -D "$PRIMARY_RESTORE_PGDATA" status >/dev/null 2>&1; then
  echo "Stop $PRIMARY_RESTORE_PGDATA first: port $PRIMARY_PORT is occupied by restored cluster"
  exit 1
fi

echo "[1/6] prepare local backup directories"
rm -rf "$ARCHIVE_DIR" "$BACKUP_DIR"
mkdir -p "$ARCHIVE_DIR" "$BACKUP_BASE_DIR" "$BACKUP_TS1_DIR" "$BACKUP_TS2_DIR"
chmod 700 "$ARCHIVE_DIR" "$BACKUP_DIR" "$BACKUP_BASE_DIR" "$BACKUP_DIR/tblspc" "$BACKUP_TS1_DIR" "$BACKUP_TS2_DIR"

echo "[1.5/6] prepare standby directories"
ssh "$STANDBY_USER@$STANDBY_HOST" "pg_ctl -D /var/db/postgres2/failover_pgdata stop -m fast >/dev/null 2>&1 || true; pg_ctl -D /var/db/postgres2/stage4_pgdata stop -m fast >/dev/null 2>&1 || true; rm -rf '$STANDBY_ARCHIVE_DIR' '$STANDBY_BACKUP_DIR' /var/db/postgres2/failover_pgdata /var/db/postgres2/stage4_pgdata /var/db/postgres2/sbm10 /var/db/postgres2/nym69 && mkdir -p '$STANDBY_ARCHIVE_DIR' '$STANDBY_BACKUP_DIR' /var/db/postgres2/transfer /var/db/postgres2/failover_pgdata && chmod 700 '$STANDBY_ARCHIVE_DIR' /var/db/postgres2/transfer /var/db/postgres2/failover_pgdata"

echo "[2/6] enable WAL archiving to standby"
ARCHIVE_COMMAND="test ! -f $ARCHIVE_DIR/%f && cp %p $ARCHIVE_DIR/%f && scp -q $ARCHIVE_DIR/%f $STANDBY_USER@$STANDBY_HOST:$STANDBY_ARCHIVE_DIR/%f"

psql -v ON_ERROR_STOP=1 -p "$PRIMARY_PORT" -d postgres <<SQL
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_timeout = '300';
ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}';
SQL

grep -qxF 'local   replication   postgres0   peer' "$PRIMARY_PGDATA/pg_hba.conf" || echo 'local   replication   postgres0   peer' >> "$PRIMARY_PGDATA/pg_hba.conf"

echo "[3/6] restart primary to apply archive_mode"
pg_ctl -D "$PRIMARY_PGDATA" restart -m fast

echo "[4/6] create initial base backup"
rm -rf "$BACKUP_BASE_DIR" "$BACKUP_TS1_DIR" "$BACKUP_TS2_DIR"
mkdir -p "$BACKUP_BASE_DIR" "$BACKUP_TS1_DIR" "$BACKUP_TS2_DIR"
pg_basebackup -p "$PRIMARY_PORT" -D "$BACKUP_BASE_DIR" -Fp -X stream -P -c fast \
  --tablespace-mapping="$PRIMARY_TS1=$BACKUP_TS1_DIR" \
  --tablespace-mapping="$PRIMARY_TS2=$BACKUP_TS2_DIR"

echo "[5/6] force WAL switch so archive is visible on standby"
psql -v ON_ERROR_STOP=1 -p "$PRIMARY_PORT" -d postgres -c 'SELECT pg_switch_wal();'

echo "[6/6] copy base backup to standby"
rsync -aH --delete "$BACKUP_DIR/" "$STANDBY_USER@$STANDBY_HOST:$STANDBY_BACKUP_DIR/"

echo
echo "Done. Reserve copy is ready in $STANDBY_USER@$STANDBY_HOST:$STANDBY_BACKUP_DIR"
echo "Standby directories are prepared automatically."
