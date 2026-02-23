#!/bin/bash
# Скрипт очистки кластера PostgreSQL
# Лабораторная работа №1
# ВНИМАНИЕ: Этот скрипт удаляет ВСЕ данные!

set -e

# Загрузка переменных окружения
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/env.sh" ]; then
    source "$SCRIPT_DIR/env.sh"
else
    export CLUSTER_DIR="$HOME/nwc36"
    export TABLESPACE_DIR_1="$HOME/sbm10"
    export TABLESPACE_DIR_2="$HOME/nym69"
    export ARCHIVE_DIR="/tmp/archive"
fi

echo "======================================"
echo "  ОЧИСТКА КЛАСТЕРА POSTGRESQL"
echo "======================================"
echo ""
echo "ВНИМАНИЕ! Этот скрипт удалит:"
echo "  Кластер PostgreSQL ($CLUSTER_DIR)"
echo "  Табличные пространства ($TABLESPACE_DIR_1, $TABLESPACE_DIR_2)"
echo "  Архив WAL ($ARCHIVE_DIR)"
echo ""

read -p "Вы уверены? Введите 'yes' для подтверждения: " confirm

if [ "$confirm" != "yes" ]; then
    echo "Операция отменена."
    exit 0
fi

echo ""
echo "Остановка PostgreSQL сервера..."

# Остановка сервера (если запущен)
if [ -d "$CLUSTER_DIR" ]; then
    if pg_ctl -D "$CLUSTER_DIR" status > /dev/null 2>&1; then
        pg_ctl -D "$CLUSTER_DIR" stop -m fast || true
        sleep 2
        echo "  + Сервер остановлен"
    else
        echo "  - Сервер не запущен"
    fi
fi

echo ""
echo "Удаление файлов..."

# Удаление кластера
if [ -d "$CLUSTER_DIR" ]; then
    rm -rf "$CLUSTER_DIR"
    echo "  + Удалён кластер: $CLUSTER_DIR"
else
    echo "  - Кластер не найден: $CLUSTER_DIR"
fi

# Удаление табличных пространств
if [ -d "$TABLESPACE_DIR_1" ]; then
    rm -rf "$TABLESPACE_DIR_1"
    echo "  + Удалено: $TABLESPACE_DIR_1"
else
    echo "  - Не найдено: $TABLESPACE_DIR_1"
fi

if [ -d "$TABLESPACE_DIR_2" ]; then
    rm -rf "$TABLESPACE_DIR_2"
    echo "  + Удалено: $TABLESPACE_DIR_2"
else
    echo "  - Не найдено: $TABLESPACE_DIR_2"
fi

# Удаление архива WAL
if [ -d "$ARCHIVE_DIR" ]; then
    rm -rf "$ARCHIVE_DIR"
    echo "  + Удалён архив: $ARCHIVE_DIR"
else
    echo "  - Архив не найден: $ARCHIVE_DIR"
fi

echo ""
echo "======================================"
echo "  Очистка завершена!"
echo "======================================"
echo ""
echo "Для повторной инициализации выполните:"
echo "  ./scripts/init.sh"
echo ""
