#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${TARGET_TIME:-}" ]; then
  echo "Set TARGET_TIME to timestamp printed by stage4_prepare.sql"
  exit 1
fi

DUMP_FILE="/tmp/ddss_lab2_transfer/products_before_delete.dump"

pg_ctl -D "/tmp/ddss_lab2_stage4_pgdata" stop -m fast >/dev/null 2>&1 || true
rm -rf "/tmp/ddss_lab2_stage4_pgdata"
mkdir -p "/tmp/ddss_lab2_stage4_pgdata" "/tmp/ddss_lab2_transfer"
rsync -aH --delete "/tmp/ddss_lab2_backup/base/" "/tmp/ddss_lab2_stage4_pgdata/"

cat >> "/tmp/ddss_lab2_stage4_pgdata/postgresql.auto.conf" <<CONF
port = '9191'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp /tmp/ddss_lab2_archive/%f %p'
recovery_target_time = '${TARGET_TIME}'
recovery_target_inclusive = 'true'
recovery_target_action = 'promote'
CONF

touch "/tmp/ddss_lab2_stage4_pgdata/recovery.signal"
pg_ctl -D "/tmp/ddss_lab2_stage4_pgdata" -l "/tmp/ddss_lab2_stage4_pgdata/startup.log" start
sleep 5
psql -v ON_ERROR_STOP=1 -h localhost -p "9191" -d "bigbluecity" -c 'TABLE products;'
pg_dump -h localhost -p "9191" -d "bigbluecity" -Fc -t public.products -f "${DUMP_FILE}"

echo
echo "Dump created: ${DUMP_FILE}"
echo "Next on primary:"
echo "  scp '${DUMP_FILE}' 'postgres0@pg125:${DUMP_FILE}'"
echo "  pg_restore --clean --if-exists --no-owner --no-privileges -h localhost -p '9099' -d 'bigbluecity' -t public.products '${DUMP_FILE}'"
