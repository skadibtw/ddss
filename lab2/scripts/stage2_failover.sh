#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pg_ctl -D "${HOME}/failover_pgdata" stop -m fast >/dev/null 2>&1 || true
rm -rf "${HOME}/failover_pgdata"
mkdir -p "${HOME}/failover_pgdata"
rsync -aH --delete "${HOME}/backup/base/" "${HOME}/failover_pgdata/"

cat >> "${HOME}/failover_pgdata/postgresql.auto.conf" <<CONF
port = '9099'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp ${HOME}/archive/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "${HOME}/failover_pgdata/recovery.signal"
pg_ctl -D "${HOME}/failover_pgdata" -l "${HOME}/failover_pgdata/startup.log" start
sleep 5
pg_isready -h localhost -p "9099"
psql -v ON_ERROR_STOP=1 -h localhost -p "9099" -d "bigbluecity" -c "SELECT current_setting('port') AS port, pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"
