#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Run this stage on standby: postgres2@pg132"

pg_ctl -D "${HOME}/failover_pgdata" stop -m fast >/dev/null 2>&1 || true
rm -rf "${HOME}/failover_pgdata"
rm -rf "${HOME}/failover_ts1" "${HOME}/failover_ts2"
mkdir -p "${HOME}/failover_pgdata" "${HOME}/failover_ts1" "${HOME}/failover_ts2"
chmod 700 "${HOME}/failover_pgdata" "${HOME}/failover_ts1" "${HOME}/failover_ts2"
rsync -aH --delete "${HOME}/backup/base/" "${HOME}/failover_pgdata/"
rsync -aH --delete "${HOME}/backup/tblspc/sbm10/" "${HOME}/failover_ts1/"
rsync -aH --delete "${HOME}/backup/tblspc/nym69/" "${HOME}/failover_ts2/"

bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '${HOME}/failover_pgdata'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='${HOME}/failover_ts1' ;;
    *nym69*) TS_MAP["\${oid}"]='${HOME}/failover_ts2' ;;
  esac
done
rm -f '${HOME}/failover_pgdata'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '${HOME}/failover_pgdata'/pg_tblspc/"\${oid}"
done
EOF

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
pg_isready -p "9099"
psql -v ON_ERROR_STOP=1 -p "9099" -d "bigbluecity" -c "SELECT current_setting('port') AS port, pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"
