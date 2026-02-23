#!/bin/bash
# clean.sh
# Удаляет кластер и каталоги табличных пространств.
#
# Запуск:
#   bash scripts/clean.sh
#   bash scripts/clean.sh --yes

set -euo pipefail

if [ "${1:-}" != "--yes" ]; then
    echo "Будет удалено:"
    echo "  $HOME/nwc36"
    echo "  $HOME/sbm10"
    echo "  $HOME/nym69"
    echo "  /tmp/archive"
    read -r -p "Подтвердить? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Отмена."
        exit 0
    fi
fi

pg_ctl -D "$HOME/nwc36" stop -m fast >/dev/null 2>&1 || true
rm -rf "$HOME/nwc36" "$HOME/sbm10" "$HOME/nym69" /tmp/archive

echo "Готово."
