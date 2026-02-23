#!/bin/bash
# Скрипт автоматической установки PostgreSQL кластера
# Лабораторная работа №1
# Выполняет все этапы последовательно

set -e

# Переход в директорию скриптов
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Загрузка переменных окружения
if [ -f "$SCRIPT_DIR/env.sh" ]; then
    source "$SCRIPT_DIR/env.sh"
else
    export CLUSTER_DIR="$HOME/nwc36"
    export PG_PORT=9099
    export PG_DATABASE="bigbluecity"
    export PG_USER="dbuser"
    export PG_PASSWORD="secure_password_123"
fi


read -p "Продолжить? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Установка отменена."
    exit 0
fi

echo ""
echo "  ЭТАП 1: Инициализация кластера"
echo ""

./init.sh

echo "" 
echo "  ЭТАП 2: Запуск сервера"
echo ""

echo "Запуск PostgreSQL сервера..."
pg_ctl -D "$CLUSTER_DIR" -l "$CLUSTER_DIR/logfile" start

echo "Ожидание готовности сервера..."
sleep 3

# Проверка запуска
if pg_ctl -D "$CLUSTER_DIR" status > /dev/null 2>&1; then
    echo "Сервер запущен успешно"
else
    echo "ОШИБКА: Сервер не запустился!"
    exit 1
fi

echo ""
echo "  ЭТАП 3: Создание базы данных и ролей"
echo ""

psql -p $PG_PORT -d postgres -f config.sql

echo ""
echo "=============================================="
echo ""

echo "ВАЖНО: Скрипт table_spaces.sql нужно отредактировать!"
echo "Замените :HOME на полный путь к домашнему каталогу"
echo ""
read -p "Табличные пространства уже настроены? (yes/skip): " ts_ready

if [ "$ts_ready" = "yes" ]; then
    psql -p $PG_PORT -d postgres -f table_spaces.sql
else
    echo "Пропуск создания табличных пространств"
    echo "Выполните вручную после редактирования:"
    echo "  psql -p $PG_PORT -d postgres -f scripts/table_spaces.sql"
    exit 0
fi

echo ""
echo "=============================================="
echo "  ЭТАП 5: Создание структуры таблиц"
echo "=============================================="
echo ""

echo "Подключение от имени роли $PG_USER (пароль: $PG_PASSWORD)"
PGPASSWORD="$PG_PASSWORD" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE -f create.sql

echo ""
echo "=============================================="
echo "  ЭТАП 6: Наполнение данными"
echo "=============================================="
echo ""

echo "Добавление тестовых данных..."
PGPASSWORD="$PG_PASSWORD" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE -f seeds.sql

echo ""
echo "=============================================="
echo "  ЭТАП 7: Информация о табличных пространствах"
echo "=============================================="
echo ""

PGPASSWORD="$PG_PASSWORD" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE -f info.sql

echo ""
echo "=============================================="
echo "  УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "=============================================="
echo ""
echo "Информация о кластере:"
echo "  Директория: $CLUSTER_DIR"
echo "  Порт: $PG_PORT"
echo "  База данных: $PG_DATABASE"
echo "  Роль: $PG_USER"
echo "  Пароль: $PG_PASSWORD"
echo ""
echo "Полезные команды:"
echo "  Подключение (peer):"
echo "    psql -p $PG_PORT -d $PG_DATABASE"
echo ""
echo "  Подключение (TCP/IP):"
echo "    psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE"
echo ""
echo "  Остановка сервера:"
echo "    pg_ctl -D $CLUSTER_DIR stop"
echo ""
echo "  Просмотр логов:"
echo "    tail -f $CLUSTER_DIR/logfile"
echo ""
echo "  Информация о табличных пространствах:"
echo "    psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE -f scripts/info.sql"
echo ""
