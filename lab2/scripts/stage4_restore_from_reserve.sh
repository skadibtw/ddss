#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Run this stage on standby: postgres2@pg132"

if [ -z "${TARGET_TIME:-}" ]; then
  echo "Set TARGET_TIME to timestamp printed by stage4_prepare.sql"
  exit 1
fi

DUMP_FILE="${HOME}/transfer/products_before_delete.dump"

pg_ctl -D "${HOME}/stage4_pgdata" stop -m fast >/dev/null 2>&1 || true
rm -rf "${HOME}/stage4_pgdata"
rm -rf "${HOME}/stage4_ts1" "${HOME}/stage4_ts2"
mkdir -p "${HOME}/stage4_pgdata" "${HOME}/stage4_ts1" "${HOME}/stage4_ts2" "${HOME}/transfer"
chmod 700 "${HOME}/stage4_pgdata" "${HOME}/stage4_ts1" "${HOME}/stage4_ts2" "${HOME}/transfer"
rsync -aH --delete "${HOME}/backup/base/" "${HOME}/stage4_pgdata/"
rsync -aH --delete "${HOME}/backup/tblspc/sbm10/" "${HOME}/stage4_ts1/"
rsync -aH --delete "${HOME}/backup/tblspc/nym69/" "${HOME}/stage4_ts2/"

bash -s <<EOF
set -euo pipefail
declare -A TS_MAP
for link in '${HOME}/stage4_pgdata'/pg_tblspc/*; do
  [ -L "\${link}" ] || continue
  oid="\$(basename "\${link}")"
  target="\$(readlink "\${link}")"
  case "\${target}" in
    *sbm10*) TS_MAP["\${oid}"]='${HOME}/stage4_ts1' ;;
    *nym69*) TS_MAP["\${oid}"]='${HOME}/stage4_ts2' ;;
  esac
done
rm -f '${HOME}/stage4_pgdata'/pg_tblspc/*
for oid in "\${!TS_MAP[@]}"; do
  ln -s "\${TS_MAP[\${oid}]}" '${HOME}/stage4_pgdata'/pg_tblspc/"\${oid}"
done
EOF

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
psql -v ON_ERROR_STOP=1 -p "9191" -d "bigbluecity" -c 'TABLE products;'
pg_dump -p "9191" -d "bigbluecity" -Fc -t public.products -f "${DUMP_FILE}"

echo
echo "Dump created: ${DUMP_FILE}"
echo "Next on primary:"
echo "  scp '${DUMP_FILE}' 'postgres0@pg125:/var/db/postgres0/transfer/products_before_delete.dump'"
echo "  pg_restore --clean --if-exists --no-owner --no-privileges -p '9099' -d 'bigbluecity' -t public.products '${DUMP_FILE}'"
