#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SCRIPT_DIR}/env.sh"

for cmd in psql pg_ctl pg_basebackup rsync ssh scp; do
  command -v "${cmd}" >/dev/null
done

echo "[1/6] prepare local and remote directories"
ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "mkdir -p '${ARCHIVE_DIR}' '${BACKUP_ROOT}/base' '${BACKUP_ROOT}/tblspc/sbm10' '${BACKUP_ROOT}/tblspc/nym69' && chmod 700 '${ARCHIVE_DIR}' '${BACKUP_ROOT}' '${BACKUP_ROOT}/base' '${BACKUP_ROOT}/tblspc' '${BACKUP_ROOT}/tblspc/sbm10' '${BACKUP_ROOT}/tblspc/nym69'"
ssh "${SSH_OPTS[@]}" "${STANDBY_SSH}" "mkdir -p '${ARCHIVE_DIR}' '${BACKUP_ROOT}' '${FAILOVER_PGDATA}' '${TRANSFER_DIR}' && chmod 700 '${ARCHIVE_DIR}' '${BACKUP_ROOT}' '${FAILOVER_PGDATA}' '${TRANSFER_DIR}'"

echo "[2/6] enable WAL archiving to standby"
ARCHIVE_COMMAND="test ! -f ${ARCHIVE_DIR}/%f && cp %p ${ARCHIVE_DIR}/%f && scp -q ${ARCHIVE_DIR}/%f ${STANDBY_USER}@${STANDBY_HOST}:${ARCHIVE_DIR}/%f"

ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "psql -v ON_ERROR_STOP=1 -p '${PRIMARY_PORT}' -d postgres <<'SQL'
ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_timeout = '300';
ALTER SYSTEM SET archive_command = '${ARCHIVE_COMMAND}';
SQL
"

echo "[3/6] restart primary to apply archive_mode"
ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "pg_ctl -D ${PRIMARY_PGDATA} restart -m fast"

echo "[4/6] create initial base backup"
ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "rm -rf '${BACKUP_ROOT}/base' '${BACKUP_ROOT}/tblspc/sbm10' '${BACKUP_ROOT}/tblspc/nym69' && mkdir -p '${BACKUP_ROOT}/base' '${BACKUP_ROOT}/tblspc/sbm10' '${BACKUP_ROOT}/tblspc/nym69' && pg_basebackup -D '${BACKUP_ROOT}/base' -Fp -X stream -P -c fast --tablespace-mapping='${PRIMARY_TS1}=${BACKUP_ROOT}/tblspc/sbm10' --tablespace-mapping='${PRIMARY_TS2}=${BACKUP_ROOT}/tblspc/nym69'"

echo "[5/6] force WAL switch so archive is visible on standby"
ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "psql -v ON_ERROR_STOP=1 -p '${PRIMARY_PORT}' -d postgres -c 'SELECT pg_switch_wal();'"

echo "[6/6] copy base backup to standby"
ssh "${SSH_OPTS[@]}" "${PRIMARY_SSH}" "rsync -aH --delete '${BACKUP_ROOT}/' '${STANDBY_USER}@${STANDBY_HOST}:${BACKUP_ROOT}/'"
ssh "${SSH_OPTS[@]}" "${STANDBY_SSH}" "ls -lah '${BACKUP_ROOT}' '${ARCHIVE_DIR}'"

echo
echo "Done. Reserve copy is ready in ${STANDBY_SSH}:${BACKUP_ROOT}"
