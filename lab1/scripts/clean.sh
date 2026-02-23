#!/bin/bash
# clean.sh
# Удаляет кластер и каталоги табличных пространств.
#
# Запуск:
#   bash scripts/clean.sh
#   bash scripts/clean.sh --yes

set -euo pipefail

CLUSTER_DIR="${CLUSTER_DIR:-$HOME/nwc36}"
TABLESPACE_DIR_1="${TABLESPACE_DIR_1:-$HOME/sbm10}"
TABLESPACE_DIR_2="${TABLESPACE_DIR_2:-$HOME/nym69}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/tmp/archive}"

if [ "${1:-}" != "--yes" ]; then
    echo "Будет удалено:"
    echo "  $CLUSTER_DIR"
    echo "  $TABLESPACE_DIR_1"
    echo "  $TABLESPACE_DIR_2"
    echo "  $ARCHIVE_DIR"
    read -r -p "Подтвердить? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Отмена."
        exit 0
    fi
fi

pg_ctl -D "$CLUSTER_DIR" stop -m fast >/dev/null 2>&1 || true
rm -rf "$CLUSTER_DIR" "$TABLESPACE_DIR_1" "$TABLESPACE_DIR_2" "$ARCHIVE_DIR"

echo "Готово."
