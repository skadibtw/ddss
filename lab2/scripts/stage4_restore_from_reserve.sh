#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/env.sh"

if [ -z "${TARGET_TIME:-}" ]; then
  echo "Set TARGET_TIME to timestamp printed by stage4_prepare.sql"
  exit 1
fi

DUMP_FILE="${TRANSFER_DIR}/products_before_delete.dump"

ssh "${SSH_OPTS[@]}" "${STANDBY_SSH}" "bash -s" <<EOF
set -euo pipefail

pg_ctl -D '${RESERVE_STAGE4_PGDATA}' stop -m fast >/dev/null 2>&1 || true
rm -rf '${RESERVE_STAGE4_PGDATA}'
mkdir -p '${RESERVE_STAGE4_PGDATA}' '${TRANSFER_DIR}'
rsync -aH --delete '${BACKUP_ROOT}/base/' '${RESERVE_STAGE4_PGDATA}/'

cat >> '${RESERVE_STAGE4_PGDATA}/postgresql.auto.conf' <<CONF
port = '${STANDBY_PITR_PORT}'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp ${ARCHIVE_DIR}/%f %p'
recovery_target_time = '${TARGET_TIME}'
recovery_target_inclusive = 'true'
recovery_target_action = 'promote'
CONF

touch '${RESERVE_STAGE4_PGDATA}/recovery.signal'
pg_ctl -D '${RESERVE_STAGE4_PGDATA}' -l '${RESERVE_STAGE4_PGDATA}/startup.log' start
sleep 5
psql -v ON_ERROR_STOP=1 -h localhost -p '${STANDBY_PITR_PORT}' -d '${PRIMARY_DB}' -c 'TABLE products;'
pg_dump -h localhost -p '${STANDBY_PITR_PORT}' -d '${PRIMARY_DB}' -Fc -t public.products -f '${DUMP_FILE}'
EOF

mkdir -p "${TRANSFER_DIR}"
scp "${SSH_OPTS[@]}" "${STANDBY_SSH}:${DUMP_FILE}" "${TRANSFER_DIR}/products_before_delete.dump"
scp "${SSH_OPTS[@]}" "${TRANSFER_DIR}/products_before_delete.dump" "${PRIMARY_SSH}:${DUMP_FILE}"

ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "pg_restore --clean --if-exists --no-owner --no-privileges -h localhost -p '${PRIMARY_PORT}' -d '${PRIMARY_DB}' -t public.products '${DUMP_FILE}' && psql -v ON_ERROR_STOP=1 -h localhost -p '${PRIMARY_PORT}' -d '${PRIMARY_DB}' -c 'TABLE products;'"
