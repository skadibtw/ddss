#!/bin/bash
# Переменные окружения для PostgreSQL кластера
# Лабораторная работа №1
#
# СЕРВЕРНАЯ ВЕРСИЯ - для работы на postgres0@pg125
# Домашняя директория: /var/db/postgres0
#
# Использование на сервере:
#   source scripts/env-server.sh
#   или
#   . scripts/env-server.sh

# Базовая директория на сервере (жестко задана)
export PG_BASE_DIR="/var/db/postgres0"

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