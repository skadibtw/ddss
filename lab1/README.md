# Лаба 1: минимальный комплект для демонстрации

Ниже комплект из **3 shell + 3 SQL** файлов.

## Файлы

- `scripts/create.sh` - полный запуск (initdb, конфиг, старт, создание объектов, наполнение, проверка).
- `scripts/clean.sh` - полная очистка кластера и табличных пространств.
- `scripts/setup.sql` - создание БД/роли/табличных пространств, схема и данные.
- `scripts/check.sql` - проверка параметров, табличных пространств и объектов.
- `scripts/ha_pgbench_check.sh` - короткая проверка `pgbench` (порт `9099`, транзакция `24KB`, порог `1500 TPS`).
- `scripts/pgbench_24kb.sql` - SQL-нагрузка `pgbench` (одна транзакция = вставка `24KB`).

## Быстрый показ преподавателю

```bash
bash scripts/create.sh --reset
```

`create.sh` можно:
- запускать целиком;
- копировать блоками и выполнять вручную (шаги `STEP 0 ... STEP 8`).

После выполнения:

- кластер: `$HOME/nwc36`
- порт: `9099`
- БД: `bigbluecity`
- роль: `dbuser`
- tablespaces: `$HOME/sbm10`, `$HOME/nym69`

## По конфигам

- `postgresql.conf` настраивается через `ALTER SYSTEM` в `create.sh`.
- `pg_hba.conf` задаётся отдельным файлом (через `ALTER SYSTEM` это не настраивается).

## Очистка

```bash
bash scripts/clean.sh --yes
```

## Проверка TPS и размера транзакции (`pgbench`)

```bash
bash scripts/ha_pgbench_check.sh
```

Скрипт запускает тест на `localhost:9099`, проверяет `TPS >= 1500` и валидирует размер транзакции `24KB`.
Если на сервере ошибка `Resource temporarily unavailable`, уменьшайте конкуренцию:

```bash
CLIENTS=80 JOBS=4 DURATION=600 bash scripts/ha_pgbench_check.sh
```

## Подключение к учебному узлу

- Через `helios`:
  - `ssh -J sXXXXXX@helios.cs.ifmo.ru:2222 postgresY@pgZZZ`
- Из сети факультета:
  - `ssh postgresY@pgZZZ`
