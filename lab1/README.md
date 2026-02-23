# Лаба 1: минимальный комплект для демонстрации

Ниже комплект из **2 shell + 2 SQL** файлов.

## Файлы

- `scripts/create.sh` - полный запуск (initdb, конфиг, старт, создание объектов, наполнение, проверка).
- `scripts/clean.sh` - полная очистка кластера и табличных пространств.
- `scripts/setup.sql` - создание БД/роли/табличных пространств, схема и данные.
- `scripts/check.sql` - проверка параметров, табличных пространств и объектов.

## Быстрый показ преподавателю

```bash
bash scripts/create.sh --reset
```

После выполнения:

- кластер: `$HOME/nwc36`
- порт: `9099`
- БД: `bigbluecity`
- роль: `dbuser`
- tablespaces: `$HOME/sbm10`, `$HOME/nym69`

## Очистка

```bash
bash scripts/clean.sh --yes
```

## Переменные (опционально)

Можно переопределять перед запуском:

```bash
export CLUSTER_DIR="$HOME/nwc36"
export PG_PORT=9099
export PG_DATABASE=bigbluecity
export PG_USER=dbuser
export PG_PASSWORD=secure_password_123
export TABLESPACE_DIR_1="$HOME/sbm10"
export TABLESPACE_DIR_2="$HOME/nym69"
bash scripts/create.sh --reset
```

## Подключение к учебному узлу

- Через `helios`:
  - `ssh -J sXXXXXX@helios.cs.ifmo.ru:2222 postgresY@pgZZZ`
- Из сети факультета:
  - `ssh postgresY@pgZZZ`
