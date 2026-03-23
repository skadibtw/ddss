#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/env.sh"

for cmd in psql pg_ctl pg_basebackup rsync scp; do
  command -v "${cmd}" >/dev/null
done

echo "[1/6] prepare local backup directories"
mkdir -p "${ARCHIVE_DIR}" "${BACKUP_ROOT}/base" "${BACKUP_ROOT}/tblspc/sbm10" "${BACKUP_ROOT}/tblspc/nym69"
chmod 700 "${ARCHIVE_DIR}" "${BACKUP_ROOT}" "${BACKUP_ROOT}/base" "${BACKUP_ROOT}/tblspc" "${BACKUP_ROOT}/tblspc/sbm10" "${BACKUP_ROOT}/tblspc/nym69"

echo "[2/6] enable WAL archiving to standby"
ARCHIVE_COMMAND="test ! -f ${ARCHIVE_DIR}/%f && cp %p ${ARCHIVE_DIR}/%f && scp -q ${ARCHIVE_DIR}/%f ${STANDBY_USER}@${STANDBY_HOST}:${ARCHIVE_DIR}/%f"

psql -v ON_ERROR_STOP=1 -p "${PRIMARY_PORT}" -d postgres <<SQL
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_timeout = '300';
ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}';
SQL

echo "[3/6] restart primary to apply archive_mode"
pg_ctl -D "${PRIMARY_PGDATA}" restart -m fast

echo "[4/6] create initial base backup"
rm -rf "${BACKUP_ROOT}/base" "${BACKUP_ROOT}/tblspc/sbm10" "${BACKUP_ROOT}/tblspc/nym69"
mkdir -p "${BACKUP_ROOT}/base" "${BACKUP_ROOT}/tblspc/sbm10" "${BACKUP_ROOT}/tblspc/nym69"
pg_basebackup -D "${BACKUP_ROOT}/base" -Fp -X stream -P -c fast \
  --tablespace-mapping="${PRIMARY_TS1}=${BACKUP_ROOT}/tblspc/sbm10" \
  --tablespace-mapping="${PRIMARY_TS2}=${BACKUP_ROOT}/tblspc/nym69"

echo "[5/6] force WAL switch so archive is visible on standby"
psql -v ON_ERROR_STOP=1 -p "${PRIMARY_PORT}" -d postgres -c 'SELECT pg_switch_wal();'

echo "[6/6] copy base backup to standby"
rsync -aH --delete "${BACKUP_ROOT}/" "${STANDBY_USER}@${STANDBY_HOST}:${BACKUP_ROOT}/"

echo
echo "Done. Reserve copy is ready in ${STANDBY_USER}@${STANDBY_HOST}:${BACKUP_ROOT}"
echo "Before failover/PITR, create ${ARCHIVE_DIR}, ${FAILOVER_PGDATA} and ${TRANSFER_DIR} on standby."
