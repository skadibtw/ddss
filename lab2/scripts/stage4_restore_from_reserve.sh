#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${TARGET_TIME:-}" ]; then
  echo "Set TARGET_TIME to timestamp printed by stage4_prepare.sql"
  exit 1
fi

DUMP_FILE="${HOME}/transfer/products_before_delete.dump"

pg_ctl -D "${HOME}/stage4_pgdata" stop -m fast >/dev/null 2>&1 || true
rm -rf "${HOME}/stage4_pgdata"
mkdir -p "${HOME}/stage4_pgdata" "${HOME}/transfer"
rsync -aH --delete "${HOME}/backup/base/" "${HOME}/stage4_pgdata/"

cat >> "${HOME}/stage4_pgdata/postgresql.auto.conf" <<CONF
port = '9191'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp ${HOME}/archive/%f %p'
recovery_target_time = '${TARGET_TIME}'
recovery_target_inclusive = 'true'
recovery_target_action = 'promote'
CONF

touch "${HOME}/stage4_pgdata/recovery.signal"
pg_ctl -D "${HOME}/stage4_pgdata" -l "${HOME}/stage4_pgdata/startup.log" start
sleep 5
psql -v ON_ERROR_STOP=1 -h localhost -p "9191" -d "bigbluecity" -c 'TABLE products;'
pg_dump -h localhost -p "9191" -d "bigbluecity" -Fc -t public.products -f "${DUMP_FILE}"

echo
echo "Dump created: ${DUMP_FILE}"
echo "Next on primary:"
echo "  scp '${DUMP_FILE}' 'postgres0@pg125:/var/db/postgres0/transfer/products_before_delete.dump'"
echo "  pg_restore --clean --if-exists --no-owner --no-privileges -h localhost -p '9099' -d 'bigbluecity' -t public.products '${DUMP_FILE}'"
