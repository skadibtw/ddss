#!/bin/bash
# create.sh
# Минимальный orchestration-скрипт лабораторной:
# initdb -> config -> start -> setup.sql -> check.sql
#
# Запуск:
#   bash scripts/create.sh
# Полный reset перед запуском:
#   bash scripts/create.sh --reset

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLUSTER_DIR="${CLUSTER_DIR:-$HOME/nwc36}"
PG_PORT="${PG_PORT:-9099}"
PG_DATABASE="${PG_DATABASE:-bigbluecity}"
PG_USER="${PG_USER:-dbuser}"
PG_PASSWORD="${PG_PASSWORD:-secure_password_123}"
PG_LOCALE="${PG_LOCALE:-ru_RU.UTF-8}"
PG_ENCODING="${PG_ENCODING:-UTF8}"

TABLESPACE_NAME_1="${TABLESPACE_NAME_1:-sbm10_space}"
TABLESPACE_NAME_2="${TABLESPACE_NAME_2:-nym69_space}"
TABLESPACE_DIR_1="${TABLESPACE_DIR_1:-$HOME/sbm10}"
TABLESPACE_DIR_2="${TABLESPACE_DIR_2:-$HOME/nym69}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/tmp/archive}"

if [ "${1:-}" = "--reset" ]; then
    pg_ctl -D "$CLUSTER_DIR" stop -m fast >/dev/null 2>&1 || true
    rm -rf "$CLUSTER_DIR" "$TABLESPACE_DIR_1" "$TABLESPACE_DIR_2" "$ARCHIVE_DIR"
fi

mkdir -p "$TABLESPACE_DIR_1" "$TABLESPACE_DIR_2" "$ARCHIVE_DIR"
chmod 700 "$TABLESPACE_DIR_1" "$TABLESPACE_DIR_2" "$ARCHIVE_DIR"

if [ ! -d "$CLUSTER_DIR" ]; then
    initdb -D "$CLUSTER_DIR" \
      --encoding="$PG_ENCODING" \
      --locale="$PG_LOCALE" \
      --lc-collate="$PG_LOCALE" \
      --lc-ctype="$PG_LOCALE" \
      --lc-messages="$PG_LOCALE" \
      --lc-monetary="$PG_LOCALE" \
      --lc-numeric="$PG_LOCALE" \
      --lc-time="$PG_LOCALE" \
      --data-checksums \
      --auth=peer \
      --auth-host=scram-sha-256
fi

cat > "$CLUSTER_DIR/postgresql.conf" <<EOF
port = $PG_PORT
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'

max_connections = 300
shared_buffers = 1GB
temp_buffers = 16MB
work_mem = 4MB
checkpoint_timeout = 10min
effective_cache_size = 3GB
fsync = on
commit_delay = 10
commit_siblings = 5

wal_level = replica
synchronous_commit = on
min_wal_size = 1GB
max_wal_size = 4GB
archive_mode = on
archive_command = 'test ! -f $ARCHIVE_DIR/%f && cp %p $ARCHIVE_DIR/%f'
archive_timeout = 300

logging_collector = on
log_destination = 'stderr'
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_min_messages = notice
log_connections = on
log_disconnections = on
log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h '
log_timezone = 'Europe/Moscow'

timezone = 'Europe/Moscow'
lc_messages = '$PG_LOCALE'
lc_monetary = '$PG_LOCALE'
lc_numeric = '$PG_LOCALE'
lc_time = '$PG_LOCALE'
client_encoding = '$PG_ENCODING'
EOF

cat > "$CLUSTER_DIR/pg_hba.conf" <<'EOF'
local   all   all                 peer
host    all   all   127.0.0.1/32  scram-sha-256
host    all   all   ::1/128       scram-sha-256
host    all   all   0.0.0.0/0     reject
host    all   all   ::/0          reject
EOF

if pg_ctl -D "$CLUSTER_DIR" status >/dev/null 2>&1; then
    pg_ctl -D "$CLUSTER_DIR" reload
else
    pg_ctl -D "$CLUSTER_DIR" -l "$CLUSTER_DIR/logfile" start
fi

for _ in $(seq 1 20); do
    if pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! pg_isready -h localhost -p "$PG_PORT" >/dev/null 2>&1; then
    echo "ERROR: postgres is not ready"
    exit 1
fi

psql -v ON_ERROR_STOP=1 \
  -v db_name="$PG_DATABASE" \
  -v app_user="$PG_USER" \
  -v app_password="$PG_PASSWORD" \
  -v pg_locale="$PG_LOCALE" \
  -v ts1_name="$TABLESPACE_NAME_1" \
  -v ts2_name="$TABLESPACE_NAME_2" \
  -v ts1_dir="$TABLESPACE_DIR_1" \
  -v ts2_dir="$TABLESPACE_DIR_2" \
  -p "$PG_PORT" -d postgres \
  -f "$SCRIPT_DIR/setup.sql"

psql -v ON_ERROR_STOP=1 \
  -v db_name="$PG_DATABASE" \
  -p "$PG_PORT" -d postgres \
  -f "$SCRIPT_DIR/check.sql"

echo ""
echo "DONE"
echo "Peer: psql -p $PG_PORT -d $PG_DATABASE"
echo "TCP:  PGPASSWORD=\"$PG_PASSWORD\" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE"
