#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/env.sh"

pg_ctl -D "${FAILOVER_PGDATA}" stop -m fast >/dev/null 2>&1 || true
rm -rf "${FAILOVER_PGDATA}"
mkdir -p "${FAILOVER_PGDATA}"
rsync -aH --delete "${BACKUP_ROOT}/base/" "${FAILOVER_PGDATA}/"

cat >> "${FAILOVER_PGDATA}/postgresql.auto.conf" <<CONF
port = '${STANDBY_PORT}'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp ${ARCHIVE_DIR}/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "${FAILOVER_PGDATA}/recovery.signal"
pg_ctl -D "${FAILOVER_PGDATA}" -l "${FAILOVER_PGDATA}/startup.log" start
sleep 5
pg_isready -h localhost -p "${STANDBY_PORT}"
psql -v ON_ERROR_STOP=1 -h localhost -p "${STANDBY_PORT}" -d "${PRIMARY_DB}" -c "SELECT current_setting('port') AS port, pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"
