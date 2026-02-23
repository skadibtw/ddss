#!/bin/bash
# Переменные окружения для PostgreSQL кластера
# Лабораторная работа №1
#
# ЛОКАЛЬНАЯ ВЕРСИЯ - для разработки/тестирования
# Для работы на сервере используйте: source scripts/env-server.sh
#
# Использование:
#   source scripts/env.sh
#   или
#   . scripts/env.sh

# Определение базовой директории (автоопределение или явное указание)
# На сервере postgres0@pg125: /var/db/postgres0
# Локально: $HOME
if [ -z "$PG_BASE_DIR" ]; then
    export PG_BASE_DIR="$HOME"
fi

# Основные параметры кластера
export CLUSTER_DIR="$PG_BASE_DIR/nwc36"
export PG_PORT=9099
export PG_DATABASE="bigbluecity"
export PG_USER="dbuser"
export PG_PASSWORD="secure_password_123"

# Директории табличных пространств
export TABLESPACE_DIR_1="$PG_BASE_DIR/sbm10"
export TABLESPACE_DIR_2="$PG_BASE_DIR/nym69"
export TABLESPACE_NAME_1="sbm10_space"
export TABLESPACE_NAME_2="nym69_space"

# Директория для архивирования WAL
export ARCHIVE_DIR="/tmp/archive"

# Параметры локали
export PG_LOCALE="ru_RU.UTF-8"
export PG_ENCODING="UTF8"

# Служебные переменные
export PGDATA="$CLUSTER_DIR"
export PGPORT="$PG_PORT"

echo "Переменные окружения PostgreSQL загружены:"
echo "  PG_BASE_DIR     = $PG_BASE_DIR"
echo "  CLUSTER_DIR     = $CLUSTER_DIR"
echo "  PG_PORT         = $PG_PORT"
echo "  PG_DATABASE     = $PG_DATABASE"
echo "  PG_USER         = $PG_USER"
echo "  TABLESPACE_DIR_1 = $TABLESPACE_DIR_1"
echo "  TABLESPACE_DIR_2 = $TABLESPACE_DIR_2"
echo "  ARCHIVE_DIR     = $ARCHIVE_DIR"
