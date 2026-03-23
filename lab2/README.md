# Лаба 2: резервное копирование и восстановление PostgreSQL

Материалы рассчитаны на кластер из `lab1`:

- основной узел: `PGDATA=$HOME/nwc36`, порт `9099`
- БД: `bigbluecity`
- табличные пространства: `$HOME/sbm10`, `$HOME/nym69`

## Файлы

- `scripts/env.sh.example` - шаблон переменных окружения для обоих узлов.
- `scripts/stage1_backup.sh` - включает архивирование WAL, готовит `pg_basebackup`, копирует резервную копию на резервный узел.
- `scripts/calc_backup_size.sh` - оценивает месячный объём хранения резервных копий.
- `scripts/stage2_failover.sh` - поднимает СУБД на резервном узле из базовой копии и архива WAL.
- `scripts/stage3_restore_primary.sh` - полностью восстанавливает основной узел в новом `PGDATA`.
- `scripts/stage4_prepare.sql` - добавляет строки и симулирует логическую ошибку.
- `scripts/stage4_restore_from_reserve.sh` - восстанавливает таблицу `products` через `pg_dump` с резервного узла.
- `REPORT.md` - готовый каркас отчёта с командами, расчётами и ответами на вопросы.

## Подготовка

1. Файл `scripts/env.sh` уже заполнен под ваши узлы:

```bash
PRIMARY:  postgres0@pg125
STANDBY:  postgres2@pg132
JUMP:     s413099@helios.cs.ifmo.ru:2222
```

2. При необходимости скорректируйте `scripts/env.sh`.

3. Настройте вход по SSH-ключу с основного узла на резервный, иначе `scp` в `archive_command` не сработает. Пароли в скрипты не вшиваются.

## Порядок запуска

```bash
bash scripts/stage1_backup.sh
bash scripts/calc_backup_size.sh
bash scripts/stage2_failover.sh
bash scripts/stage3_restore_primary.sh
psql -v ON_ERROR_STOP=1 -p 9099 -d bigbluecity -f scripts/stage4_prepare.sql
TARGET_TIME='YYYY-MM-DD HH24:MI:SS.US+TZ' bash scripts/stage4_restore_from_reserve.sh
```

`TARGET_TIME` для этапа 4 берётся из вывода `stage4_prepare.sql`: это момент перед `DELETE`.
