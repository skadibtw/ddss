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

## Подключение к учебному узлу

- Через `helios`:
  - `ssh -J sXXXXXX@helios.cs.ifmo.ru:2222 postgresY@pgZZZ`
- Из сети факультета:
  - `ssh postgresY@pgZZZ`
