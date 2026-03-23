#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "/tmp/ddss_lab2_backup/base" ]; then
  BASE_MB="$(du -sm "/tmp/ddss_lab2_backup/base" | awk '{print $1}')"
else
  BASE_MB="0"
fi

NEW_MB_PER_DAY=200
CHANGED_MB_PER_DAY=650
WAL_MB_PER_DAY=$((NEW_MB_PER_DAY + CHANGED_MB_PER_DAY))
MONTH_DAYS=30
MONTH_WAL_MB=$((WAL_MB_PER_DAY * MONTH_DAYS))
MONTH_TOTAL_MB=$((BASE_MB + MONTH_WAL_MB))

printf 'Base backup size: %s MB\n' "${BASE_MB}"
printf 'Archived WAL per day: %s MB\n' "${WAL_MB_PER_DAY}"
printf 'Archived WAL per 30 days: %s MB\n' "${MONTH_WAL_MB}"
printf 'Total for 30 days: %s MB (%.2f GB)\n' "${MONTH_TOTAL_MB}" "$(awk "BEGIN {print ${MONTH_TOTAL_MB}/1024}")"

cat <<'EOF'

Interpretation:
- lower estimate assumes WAL volume is close to inserted + changed data;
- real value is higher because WAL also stores full-page images, index changes, vacuum activity and metadata updates;
- if base backup is small, WAL archive dominates monthly storage.
EOF
