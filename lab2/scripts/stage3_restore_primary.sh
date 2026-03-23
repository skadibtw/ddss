#!/usr/bin/env bash
set -euo pipefail

export PRIMARY_PGDATA="$HOME/nwc36"
export PRIMARY_RESTORE_PGDATA="$HOME/nwc36_restore"
export PRIMARY_RESTORE_TS1="$HOME/restore_ts1"
export PRIMARY_RESTORE_TS2="$HOME/restore_ts2"
export BACKUP_BASE_DIR="$HOME/backup/base"
export BACKUP_TS1_DIR="$HOME/backup/tblspc/sbm10"
export BACKUP_TS2_DIR="$HOME/backup/tblspc/nym69"
export ARCHIVE_DIR="$HOME/archive"
export PRIMARY_PORT=9099
export DB_NAME=bigbluecity
export DB_USER=dbuser
export DB_PASSWORD=secure_password_123

echo "Run this stage on primary: postgres0@pg125"

for cmd in pg_ctl pg_isready psql rsync; do
  command -v "${cmd}" >/dev/null
done

echo "[1/5] stop broken primary cluster"
pg_ctl -D "$PRIMARY_PGDATA" stop -m immediate >/dev/null 2>&1 || true

echo "[2/5] prepare new locations"
rm -rf "$PRIMARY_RESTORE_PGDATA" "$PRIMARY_RESTORE_TS1" "$PRIMARY_RESTORE_TS2"
mkdir -p "$PRIMARY_RESTORE_PGDATA" "$PRIMARY_RESTORE_TS1" "$PRIMARY_RESTORE_TS2"

echo "[3/5] restore base backup into new PGDATA"
rsync -aH --delete "$BACKUP_BASE_DIR/" "$PRIMARY_RESTORE_PGDATA/"
rsync -aH --delete "$BACKUP_TS1_DIR/" "$PRIMARY_RESTORE_TS1/"
rsync -aH --delete "$BACKUP_TS2_DIR/" "$PRIMARY_RESTORE_TS2/"
chmod 700 "$PRIMARY_RESTORE_PGDATA" "$PRIMARY_RESTORE_TS1" "$PRIMARY_RESTORE_TS2"

cat >> "$PRIMARY_RESTORE_PGDATA/postgresql.auto.conf" <<CONF
port = '$PRIMARY_PORT'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "$PRIMARY_RESTORE_PGDATA/recovery.signal"

echo "[4/5] remap tablespaces to new locations"
bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '$PRIMARY_RESTORE_PGDATA'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='$PRIMARY_RESTORE_TS1' ;;
    *nym69*) TS_MAP["\${oid}"]='$PRIMARY_RESTORE_TS2' ;;
  esac
done
rm -f '$PRIMARY_RESTORE_PGDATA'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '$PRIMARY_RESTORE_PGDATA'/pg_tblspc/"\${oid}"
done
EOF

echo "[5/5] start restored primary and verify"
if ! pg_ctl -D "$PRIMARY_RESTORE_PGDATA" -l "$PRIMARY_RESTORE_PGDATA/startup.log" start; then
  echo
  echo "Startup log:"
  cat "$PRIMARY_RESTORE_PGDATA/startup.log"
  exit 1
fi
sleep 5
pg_isready -p "$PRIMARY_PORT"
PGPASSWORD="$DB_PASSWORD" psql -v ON_ERROR_STOP=1 -h localhost -U "$DB_USER" -p "$PRIMARY_PORT" -d "$DB_NAME" -c "SELECT pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"

echo
echo "Primary is restored in $PRIMARY_RESTORE_PGDATA"
