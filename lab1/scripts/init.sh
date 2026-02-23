#!/bin/bash
# Скрипт инициализации кластера PostgreSQL
# Лабораторная работа №1
# Параметры: директория nwc36, порт 9099, кодировка UTF8, русская локаль

set -e  # Остановка при ошибке

# Загрузка переменных окружения
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/env.sh" ]; then
    source "$SCRIPT_DIR/env.sh"
else
    # Если env.sh не найден, устанавливаем переменные вручную
    export CLUSTER_DIR="$HOME/nwc36"
    export PG_PORT=9099
    export TABLESPACE_DIR_1="$HOME/sbm10"
    export TABLESPACE_DIR_2="$HOME/nym69"
    export ARCHIVE_DIR="/tmp/archive"
    export PG_LOCALE="ru_RU.UTF-8"
    export PG_ENCODING="UTF8"
fi

echo "======================================"
echo "  Инициализация кластера PostgreSQL"
echo "======================================"
echo ""

echo "Параметры:"
echo "  Директория кластера: $CLUSTER_DIR"
echo "  Порт: $PG_PORT"
echo "  Кодировка: $PG_ENCODING"
echo "  Локаль: $PG_LOCALE"
echo ""

# Проверка существующего кластера
if [ -d "$CLUSTER_DIR" ]; then
    echo "ВНИМАНИЕ: Директория $CLUSTER_DIR уже существует!"
    read -p "Удалить и создать заново? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo "Удаление старого кластера..."
        rm -rf "$CLUSTER_DIR"
    else
        echo "Операция отменена."
        exit 1
    fi
fi

echo "Инициализация кластера..."
echo ""

# Инициализация с заданными параметрами
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
  --auth-host=scram-sha-256 \
  --pwprompt

echo ""
echo "Инициализация завершена успешно!"
echo ""
echo "Версия PostgreSQL:"
cat "$CLUSTER_DIR/PG_VERSION"
echo ""

# Копирование конфигурационных файлов
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

if [ -d "$CONFIG_DIR" ]; then
    echo "Копирование конфигурационных файлов..."
    
    if [ -f "$CONFIG_DIR/postgresql.conf" ]; then
        cp "$CONFIG_DIR/postgresql.conf" "$CLUSTER_DIR/postgresql.conf"
        echo "  + postgresql.conf скопирован"
    fi
    
    if [ -f "$CONFIG_DIR/pg_hba.conf" ]; then
        cp "$CONFIG_DIR/pg_hba.conf" "$CLUSTER_DIR/pg_hba.conf"
        echo "  + pg_hba.conf скопирован"
    fi
    echo ""
fi

# Создание директорий
echo "Создание необходимых директорий..."

# Директория для архивирования WAL
mkdir -p "$ARCHIVE_DIR"
chmod 700 "$ARCHIVE_DIR"
echo "  + $ARCHIVE_DIR"

# Директории для табличных пространств
mkdir -p "$TABLESPACE_DIR_1"
mkdir -p "$TABLESPACE_DIR_2"
chmod 700 "$TABLESPACE_DIR_1"
chmod 700 "$TABLESPACE_DIR_2"
echo "  + $TABLESPACE_DIR_1"
echo "  + $TABLESPACE_DIR_2"
echo ""

echo "======================================"
echo "  Инициализация завершена!"
echo "======================================"
echo ""
echo "Следующие шаги:"
echo "  1. Запустите сервер:"
echo "     pg_ctl -D $CLUSTER_DIR -l $CLUSTER_DIR/logfile start"
echo ""
echo "  2. Выполните конфигурацию:"
echo "     psql -p $PG_PORT -d postgres -f scripts/config.sql"
echo ""
echo "  3. Создайте табличные пространства:"
echo "     psql -p $PG_PORT -d postgres -f scripts/table_spaces.sql"
echo ""
