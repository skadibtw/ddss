#!/bin/bash
# create.sh
# Можно запускать целиком:
#   bash scripts/create.sh --reset

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

echo "STEP 0: optional reset"
if [ "${1:-}" = "--reset" ]; then
  pg_ctl -D "$HOME/nwc36" stop -m fast >/dev/null 2>&1 || true
  rm -rf "$HOME/nwc36" "$HOME/sbm10" "$HOME/nym69" /tmp/archive
fi

echo "STEP 1: prepare directories"
mkdir -p "$HOME/sbm10" "$HOME/nym69" /tmp/archive
chmod 700 "$HOME/sbm10" "$HOME/nym69" /tmp/archive

echo "STEP 2: initdb (if cluster not exists)"
if [ ! -d "$HOME/nwc36" ]; then
  initdb -D "$HOME/nwc36" \
    --encoding=UTF8 \
    --locale=ru_RU.UTF-8 \
    --lc-collate=ru_RU.UTF-8 \
    --lc-ctype=ru_RU.UTF-8 \
    --lc-messages=ru_RU.UTF-8 \
    --lc-monetary=ru_RU.UTF-8 \
    --lc-numeric=ru_RU.UTF-8 \
    --lc-time=ru_RU.UTF-8 \
    --data-checksums \
    --auth=peer \
    --auth-host=scram-sha-256
fi

echo "STEP 3: start bootstrap instance on 9099"
pg_ctl -D "$HOME/nwc36" stop -m fast >/dev/null 2>&1 || true
pg_ctl -D "$HOME/nwc36" -l "$HOME/nwc36/logfile" \
  -o "-p 9099 -c listen_addresses=localhost -c unix_socket_directories=/tmp" start

for _ in $(seq 1 20); do
  if pg_isready -h localhost -p 9099 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
pg_isready -h localhost -p 9099

echo "STEP 4: postgresql.conf via ALTER SYSTEM"
psql -v ON_ERROR_STOP=1 -p 9099 -d postgres <<'SQL'
ALTER SYSTEM SET port = '9099';
ALTER SYSTEM SET listen_addresses = 'localhost';
ALTER SYSTEM SET unix_socket_directories = '/tmp';

ALTER SYSTEM SET max_connections = '300';
ALTER SYSTEM SET shared_buffers = '1GB';
ALTER SYSTEM SET temp_buffers = '16MB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET checkpoint_timeout = '10min';
ALTER SYSTEM SET effective_cache_size = '3GB';
ALTER SYSTEM SET fsync = 'on';
ALTER SYSTEM SET commit_delay = '10';
ALTER SYSTEM SET commit_siblings = '5';

ALTER SYSTEM SET wal_level = 'replica';
ALTER SYSTEM SET synchronous_commit = 'on';
ALTER SYSTEM SET min_wal_size = '1GB';
ALTER SYSTEM SET max_wal_size = '4GB';
ALTER SYSTEM SET archive_mode = 'on';
ALTER SYSTEM SET archive_command = 'test ! -f /tmp/archive/%f && cp %p /tmp/archive/%f';
ALTER SYSTEM SET archive_timeout = '300';

ALTER SYSTEM SET logging_collector = 'on';
ALTER SYSTEM SET log_destination = 'stderr';
ALTER SYSTEM SET log_directory = 'log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';
ALTER SYSTEM SET log_min_messages = 'notice';
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_line_prefix = '%m [%p] user=%u db=%d app=%a client=%h ';
ALTER SYSTEM SET log_timezone = 'Europe/Moscow';

ALTER SYSTEM SET timezone = 'Europe/Moscow';
ALTER SYSTEM SET lc_messages = 'ru_RU.UTF-8';
ALTER SYSTEM SET lc_monetary = 'ru_RU.UTF-8';
ALTER SYSTEM SET lc_numeric = 'ru_RU.UTF-8';
ALTER SYSTEM SET lc_time = 'ru_RU.UTF-8';
ALTER SYSTEM SET client_encoding = 'UTF8';
SQL

echo "STEP 5: pg_hba.conf (ALTER SYSTEM не умеет это настраивать)"
cat > "$HOME/nwc36/pg_hba.conf" <<'EOF'
local   all   all                 peer
host    all   all   127.0.0.1/32  scram-sha-256
host    all   all   ::1/128       scram-sha-256
host    all   all   0.0.0.0/0     reject
host    all   all   ::/0          reject
EOF

echo "STEP 6: restart with new settings"
pg_ctl -D "$HOME/nwc36" restart -m fast

for _ in $(seq 1 20); do
  if pg_isready -h localhost -p 9099 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
pg_isready -h localhost -p 9099

echo "STEP 7: setup objects and data"
psql -v ON_ERROR_STOP=1 -p 9099 -d postgres -f scripts/setup.sql

echo "STEP 8: run checks"
psql -v ON_ERROR_STOP=1 -p 9099 -d postgres -f scripts/check.sql

echo
echo "DONE"
echo "Peer connect: psql -p 9099 -d bigbluecity"
echo 'TCP connect:  PGPASSWORD="secure_password_123" psql -p 9099 -h localhost -U dbuser -d bigbluecity'
