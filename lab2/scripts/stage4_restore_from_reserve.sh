#!/usr/bin/env bash
set -euo pipefail

export STAGE4_PGDATA="$HOME/stage4_pgdata"
export STAGE4_TS1="$HOME/stage4_ts1"
export STAGE4_TS2="$HOME/stage4_ts2"
export TRANSFER_DIR="$HOME/transfer"
export BACKUP_BASE_DIR="$HOME/backup/base"
export BACKUP_TS1_DIR="$HOME/backup/tblspc/sbm10"
export BACKUP_TS2_DIR="$HOME/backup/tblspc/nym69"
export ARCHIVE_DIR="$HOME/archive"
export PITR_PORT=9191
export PRIMARY_PORT=9099
export DB_NAME=bigbluecity
export DUMP_FILE="$TRANSFER_DIR/products_before_delete.dump"

echo "Run this stage on standby: postgres2@pg132"

if [ -z "${TARGET_TIME:-}" ]; then
  echo "Set TARGET_TIME to timestamp printed by stage4_prepare.sql"
  exit 1
fi

pg_ctl -D "$STAGE4_PGDATA" stop -m fast >/dev/null 2>&1 || true
rm -rf "$STAGE4_PGDATA" "$STAGE4_TS1" "$STAGE4_TS2"
mkdir -p "$STAGE4_PGDATA" "$STAGE4_TS1" "$STAGE4_TS2" "$TRANSFER_DIR"
chmod 700 "$STAGE4_PGDATA" "$STAGE4_TS1" "$STAGE4_TS2" "$TRANSFER_DIR"
rsync -aH --delete "$BACKUP_BASE_DIR/" "$STAGE4_PGDATA/"
rsync -aH --delete "$BACKUP_TS1_DIR/" "$STAGE4_TS1/"
rsync -aH --delete "$BACKUP_TS2_DIR/" "$STAGE4_TS2/"

bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '$STAGE4_PGDATA'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='$STAGE4_TS1' ;;
    *nym69*) TS_MAP["\${oid}"]='$STAGE4_TS2' ;;
  esac
done
rm -f '$STAGE4_PGDATA'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '$STAGE4_PGDATA'/pg_tblspc/"\${oid}"
done
EOF

cat >> "$STAGE4_PGDATA/postgresql.auto.conf" <<CONF
port = '$PITR_PORT'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_time = '${TARGET_TIME}'
recovery_target_inclusive = 'true'
recovery_target_action = 'promote'
CONF

touch "$STAGE4_PGDATA/recovery.signal"
pg_ctl -D "$STAGE4_PGDATA" -l "$STAGE4_PGDATA/startup.log" start
sleep 5
psql -v ON_ERROR_STOP=1 -p "$PITR_PORT" -d "$DB_NAME" -c 'TABLE products;'
pg_dump -p "$PITR_PORT" -d "$DB_NAME" -Fc -t public.products -f "$DUMP_FILE"

echo
echo "Dump created: ${DUMP_FILE}"
echo "Next on primary:"
echo "  scp '${DUMP_FILE}' 'postgres0@pg125:/var/db/postgres0/transfer/products_before_delete.dump'"
echo "  pg_restore --clean --if-exists --no-owner --no-privileges -p '$PRIMARY_PORT' -d '$DB_NAME' -t public.products '${DUMP_FILE}'"
