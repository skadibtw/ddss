#!/bin/bash

PRIMARY_HOST="pg125"
PRIMARY_USER="postgres0"
STANDBY_HOST="pg132"
STANDBY_USER="postgres2"

PRIMARY_PGDATA="${HOME}/nwc36"
PRIMARY_PORT="9099"
PRIMARY_DB="bigbluecity"
PRIMARY_TS1="${HOME}/sbm10"
PRIMARY_TS2="${HOME}/nym69"

STANDBY_PORT="9099"
STANDBY_PITR_PORT="9191"

BACKUP_ROOT="/tmp/ddss_lab2_backup"
ARCHIVE_DIR="/tmp/ddss_lab2_archive"
FAILOVER_PGDATA="/tmp/ddss_lab2_failover_pgdata"
PRIMARY_RESTORE_PGDATA="${HOME}/nwc36_restore"
PRIMARY_RESTORE_TS1="/tmp/ddss_lab2_restore_ts1"
PRIMARY_RESTORE_TS2="/tmp/ddss_lab2_restore_ts2"
RESERVE_STAGE4_PGDATA="/tmp/ddss_lab2_stage4_pgdata"
TRANSFER_DIR="/tmp/ddss_lab2_transfer"
