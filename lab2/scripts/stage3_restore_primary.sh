#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for cmd in pg_ctl pg_isready psql rsync; do
  command -v "${cmd}" >/dev/null
done

echo "[1/5] stop broken primary cluster"
pg_ctl -D "${HOME}/nwc36" stop -m immediate >/dev/null 2>&1 || true

echo "[2/5] prepare new locations"
rm -rf "${HOME}/nwc36_restore" "${HOME}/restore_ts1" "${HOME}/restore_ts2"
mkdir -p "${HOME}/nwc36_restore" "${HOME}/restore_ts1" "${HOME}/restore_ts2"

echo "[3/5] restore base backup into new PGDATA"
rsync -aH --delete "${HOME}/backup/base/" "${HOME}/nwc36_restore/"
rsync -aH --delete "${HOME}/backup/tblspc/sbm10/" "${HOME}/restore_ts1/"
rsync -aH --delete "${HOME}/backup/tblspc/nym69/" "${HOME}/restore_ts2/"

cat >> "${HOME}/nwc36_restore/postgresql.auto.conf" <<CONF
port = '9099'
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'
restore_command = 'cp ${HOME}/archive/%f %p'
recovery_target_timeline = 'latest'
recovery_target_action = 'promote'
CONF

touch "${HOME}/nwc36_restore/recovery.signal"

echo "[4/5] remap tablespaces to new locations"
bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '${HOME}/nwc36_restore'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='${HOME}/restore_ts1' ;;
    *nym69*) TS_MAP["\${oid}"]='${HOME}/restore_ts2' ;;
  esac
done
rm -f '${HOME}/nwc36_restore'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '${HOME}/nwc36_restore'/pg_tblspc/"\${oid}"
done
EOF

echo "[5/5] start restored primary and verify"
pg_ctl -D "${HOME}/nwc36_restore" -l "${HOME}/nwc36_restore/startup.log" start
sleep 5
pg_isready -h localhost -p "9099"
psql -v ON_ERROR_STOP=1 -h localhost -p "9099" -d "bigbluecity" -c "SELECT pg_is_in_recovery() AS in_recovery, count(*) AS sales_rows FROM sales;"

echo
echo "Primary is restored in ${HOME}/nwc36_restore"
