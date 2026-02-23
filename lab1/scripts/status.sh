#!/bin/bash
# Скрипт проверки состояния PostgreSQL кластера
# Лабораторная работа №1

# Загрузка переменных окружения
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/env.sh" ]; then
    source "$SCRIPT_DIR/env.sh"
else
    export CLUSTER_DIR="$HOME/nwc36"
    export PG_PORT=9099
    export PG_DATABASE="bigbluecity"
    export PG_USER="dbuser"
    export TABLESPACE_DIR_1="$HOME/sbm10"
    export TABLESPACE_DIR_2="$HOME/nym69"
    export ARCHIVE_DIR="/tmp/archive"
fi

echo "=============================================="
echo "  ПРОВЕРКА СОСТОЯНИЯ POSTGRESQL"
echo "=============================================="
echo ""

# Проверка существования кластера
if [ ! -d "$CLUSTER_DIR" ]; then
    echo "Кластер не инициализирован"
    echo "   Директория $CLUSTER_DIR не существует"
    echo ""
    echo "Для инициализации выполните:"
    echo "  ./scripts/init.sh"
    exit 1
fi

echo "OK: Кластер существует: $CLUSTER_DIR"
echo ""

# Проверка статуса сервера
echo "Проверка статуса сервера..."
if pg_ctl -D "$CLUSTER_DIR" status > /dev/null 2>&1; then
    echo "OK: Сервер запущен"
    pg_ctl -D "$CLUSTER_DIR" status
else
    echo "ОШИБКА: Сервер не запущен"
    echo ""
    echo "Для запуска выполните:"
    ecВерсия PostgreSQL:"
cat "$CLUSTER_DIR/PG_VERSION"
echo ""

# Проверка подключения
echo "Проверка подключения..."
if psql -p $PG_PORT -d postgres -c "SELECT version();" > /dev/null 2>&1; then
    echo "OK: Подключение успешно (Unix socket)"
else
    echo "ОШИБКА: Не удалось подключиться"
fi
echo ""

# Список баз данных
echo "Базы данных:"
psql -p $PG_PORT -d postgres -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) as size FROM pg_database WHERE datname NOT LIKE 'template%' ORDER BY datname;" 2>/dev/null || echo "Не удалось получить список баз"
echo ""

# Проверка роли
echo "Проверка роли $PG_USER:"
if psql -p $PG_PORT -d postgres -c "\\du $PG_USER" 2>/dev/null | grep -q $PG_USER; then
    echo "OK: Роль $PG_USER существует"
else
    echo "ОШИБКА: Роль $PG_USER не найдена"
fi
echo ""

# Проверка табличных пространств
echo "Табличные пространства:"
psql -p $PG_PORT -d postgres -c "SELECT spcname, pg_tablespace_location(oid) FROM pg_tablespace WHERE spcname NOT LIKE 'pg_%';" 2>/dev/null || echo "Не удалось получить информацию"
echo ""

# Проверка директорий
echo "Проверка директорий:"
for dir in "$TABLESPACE_DIR_1" "$TABLESPACE_DIR_2" "$ARCHIVE_DIR"; do
    if [ -d "$dir" ]; then
        echo "  OK: $dir"
    else
        echo "  ОШИБКА: $dir (не существует)"
    fi
done
echo ""

# Размер кластера
echo "Размер кластера:"
du -sh "$CLUSTER_DIR" 2>/dev/null || echo "Не удалось определить размер"
echo ""

# Последние строки логов
echo "Последние строки лога:"
if [ -f "$CLUSTER_DIR/logfile" ]; then
    tail -5 "$CLUSTER_DIR/logfile"
else
    echo "Лог-файл не найден"
fi
echo ""

# Подключения
echo "Активные подключения:"
psql -p $PG_PORT -d postgres -c "SELECT datname, usename, application_name, client_addr, state FROM pg_stat_activity WHERE datname IS NOT NULL;" 2>/dev/null || echo "Не удалось получить информацию"
echo ""

echo "=============================================="
echo "  Полезные команды:"
echo "=============================================="
echo ""
echo "Подключение:"
echo "  psql -p $PG_PORT -d $PG_DATABASE"
echo "  psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE"
echo ""
echo "Управление сервером:"
echo "  pg_ctl -D $CLUSTER_DIR stop"
echo "  pg_ctl -D $CLUSTER_DIR restart"
echo "  pg_ctl -D $CLUSTER_DIR reload"
echo ""
echo "Просмотр логов:"
echo "  tail -f $CLUSTER_DIR/logfile"
echo "  tail -f $CLUSTER_DIR/log/postgresql-*.log"
echo ""
echo "Информация о табличных пространствах:"
echo "  psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE
echo "Управление сервером:"
echo "  pg_ctl -D $CLUSTER_DIR stop"
echo "  pg_ctl -D $CLUSTER_DIR restart"
echo "  pg_ctl -D $CLUSTER_DIR reload"
echo ""
echo "Просмотр логов:"
echo "  tail -f $CLUSTER_DIR/logfile"
echo "  tail -f $CLUSTER_DIR/log/postgresql-*.log"
echo ""
echo "Информация о табличных пространствах:"
echo "  psql -p $PORT -h localhost -U dbuser -d bigbluecity -f scripts/info.sql"
echo ""
