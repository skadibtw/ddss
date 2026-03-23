# Лаба 2: резервное копирование и восстановление PostgreSQL

Материалы рассчитаны на кластер из `lab1` и упрощены под ручной запуск: вы сами подключаетесь по `ssh` на нужный узел и запускаете команды локально на нем.

- основной узел: `PGDATA=$HOME/nwc36`, порт `9099`
- БД: `bigbluecity`
- табличные пространства: `$HOME/sbm10`, `$HOME/nym69`

## Файлы

- `scripts/stage1_backup.sh` - запускается на основном узле: включает архивирование WAL, готовит `pg_basebackup`, копирует резервную копию на резервный узел.
- `scripts/calc_backup_size.sh` - оценивает месячный объём хранения резервных копий.
- `scripts/stage2_failover.sh` - запускается на резервном узле: поднимает СУБД из базовой копии и архива WAL.
- `scripts/stage3_restore_primary.sh` - запускается на основном узле: полностью восстанавливает основной узел в новом `PGDATA`.
- `scripts/stage4_prepare.sql` - добавляет строки и симулирует логическую ошибку.
- `scripts/stage4_restore_from_reserve.sh` - запускается на резервном узле: делает PITR и готовит дамп `products` для ручного переноса на основной узел.
- `CHEATSHEET.md` - короткая шпаргалка по всем этапам запуска.
- `REPORT.md` - готовый каркас отчёта с командами, расчётами и ответами на вопросы.

## Подготовка

1. Все команды в скриптах уже прописаны с реальными путями и портами. Вы можете просто выделять нужные команды, копировать их и выполнять в терминале построчно.
2. При необходимости скорректируйте пути (например, `${HOME}/backup`) или порты (например, `9099`) напрямую в тексте нужного скрипта перед копированием.

3. Настройте вход по SSH-ключу с основного узла на резервный, иначе `scp` в `archive_command` не сработает. Пароли в скрипты не вшиваются.
4. На резервном узле заранее создайте служебные каталоги:

```bash
mkdir -p ${HOME}/archive ${HOME}/failover_pgdata ${HOME}/transfer
chmod 700 ${HOME}/archive ${HOME}/failover_pgdata ${HOME}/transfer
```

## Порядок запуска

```bash
[primary] bash scripts/stage1_backup.sh
[primary] bash scripts/calc_backup_size.sh
[standby] bash scripts/stage2_failover.sh
[primary] bash scripts/stage3_restore_primary.sh
[primary] psql -v ON_ERROR_STOP=1 -p 9099 -d bigbluecity -f scripts/stage4_prepare.sql
[standby] TARGET_TIME='YYYY-MM-DD HH24:MI:SS.US+TZ' bash scripts/stage4_restore_from_reserve.sh
[standby->primary] scp ${HOME}/transfer/products_before_delete.dump postgres0@pg125:${HOME}/transfer/products_before_delete.dump
[primary] pg_restore --clean --if-exists --no-owner --no-privileges -h localhost -p 9099 -d bigbluecity -t public.products ${HOME}/transfer/products_before_delete.dump
```

`TARGET_TIME` для этапа 4 берётся из вывода `stage4_prepare.sql`: это момент перед `DELETE`.
