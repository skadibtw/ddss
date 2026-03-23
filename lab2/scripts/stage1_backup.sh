#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for cmd in psql pg_ctl pg_basebackup rsync scp; do
  command -v "${cmd}" >/dev/null
done

echo "[1/6] prepare local backup directories"
mkdir -p "/tmp/ddss_lab2_archive" "/tmp/ddss_lab2_backup/base" "/tmp/ddss_lab2_backup/tblspc/sbm10" "/tmp/ddss_lab2_backup/tblspc/nym69"
chmod 700 "/tmp/ddss_lab2_archive" "/tmp/ddss_lab2_backup" "/tmp/ddss_lab2_backup/base" "/tmp/ddss_lab2_backup/tblspc" "/tmp/ddss_lab2_backup/tblspc/sbm10" "/tmp/ddss_lab2_backup/tblspc/nym69"

echo "[2/6] enable WAL archiving to standby"
ARCHIVE_COMMAND="test ! -f /tmp/ddss_lab2_archive/%f && cp %p /tmp/ddss_lab2_archive/%f && scp -q /tmp/ddss_lab2_archive/%f postgres2@pg132:/tmp/ddss_lab2_archive/%f"

psql -v ON_ERROR_STOP=1 -p "9099" -d postgres <<SQL
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_timeout = '300';
ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}';
SQL

echo "[3/6] restart primary to apply archive_mode"
pg_ctl -D "${HOME}/nwc36" restart -m fast

echo "[4/6] create initial base backup"
rm -rf "/tmp/ddss_lab2_backup/base" "/tmp/ddss_lab2_backup/tblspc/sbm10" "/tmp/ddss_lab2_backup/tblspc/nym69"
mkdir -p "/tmp/ddss_lab2_backup/base" "/tmp/ddss_lab2_backup/tblspc/sbm10" "/tmp/ddss_lab2_backup/tblspc/nym69"
pg_basebackup -D "/tmp/ddss_lab2_backup/base" -Fp -X stream -P -c fast \
  --tablespace-mapping="${HOME}/sbm10=/tmp/ddss_lab2_backup/tblspc/sbm10" \
  --tablespace-mapping="${HOME}/nym69=/tmp/ddss_lab2_backup/tblspc/nym69"

echo "[5/6] force WAL switch so archive is visible on standby"
psql -v ON_ERROR_STOP=1 -p "9099" -d postgres -c 'SELECT pg_switch_wal();'

echo "[6/6] copy base backup to standby"
rsync -aH --delete "/tmp/ddss_lab2_backup/" "postgres2@pg132:/tmp/ddss_lab2_backup/"

echo
echo "Done. Reserve copy is ready in postgres2@pg132:/tmp/ddss_lab2_backup"
echo "Before failover/PITR, create /tmp/ddss_lab2_archive, /tmp/ddss_lab2_failover_pgdata and /tmp/ddss_lab2_transfer on standby."
