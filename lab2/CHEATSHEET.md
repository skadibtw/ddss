# Lab2 Cheatsheet

## 0. Подключение

```bash
ssh -J s413099@helios.cs.ifmo.ru:2222 postgres0@pg125
ssh -J s413099@helios.cs.ifmo.ru:2222 postgres2@pg132
```

## 1. Один раз на standby

```bash
mkdir -p ${HOME}/archive ${HOME}/failover_pgdata ${HOME}/transfer
chmod 700 ${HOME}/archive ${HOME}/failover_pgdata ${HOME}/transfer
```

## 2. Этап 1: backup

На `primary`:

```bash
cd /Users/skadibtw/ddss/lab2
bash scripts/stage1_backup.sh
bash scripts/calc_backup_size.sh
```

Проверка:

```bash
psql -v ON_ERROR_STOP=1 -p 9099 -d postgres -c 'SHOW archive_mode; SHOW archive_command; SHOW wal_level;'
```

На `standby`:

```bash
ls -lah ${HOME}/backup ${HOME}/archive
```

## 3. Этап 2: failover

На `standby`:

```bash
cd /Users/skadibtw/ddss/lab2
bash scripts/stage2_failover.sh
psql -v ON_ERROR_STOP=1 -h localhost -p 9099 -d bigbluecity -c 'SELECT pg_is_in_recovery(), count(*) FROM sales;'
```

## 4. Этап 3: потеря tablespace и restore primary

На `primary`:

```bash
rm -rf "$HOME/sbm10"
psql -v ON_ERROR_STOP=0 -p 9099 -d bigbluecity -c 'SELECT count(*) FROM products;'
pg_ctl -D "$HOME/nwc36" restart -m fast
cd /Users/skadibtw/ddss/lab2
bash scripts/stage3_restore_primary.sh
psql -v ON_ERROR_STOP=1 -h localhost -p 9099 -d bigbluecity -c 'SELECT pg_is_in_recovery(), count(*) FROM sales;'
psql -p 9099 -d postgres -c 'SELECT spcname, pg_tablespace_location(oid) FROM pg_tablespace ORDER BY spcname;'
```

## 5. Этап 4: logical recovery

На `primary`:

```bash
cd /Users/skadibtw/ddss/lab2
psql -v ON_ERROR_STOP=1 -p 9099 -d bigbluecity -f scripts/stage4_prepare.sql
```

Сохрани время из блока `RECOVERY TARGET TIME`.

На `standby`:

```bash
cd /Users/skadibtw/ddss/lab2
TARGET_TIME='YYYY-MM-DD HH24:MI:SS.US+TZ' bash scripts/stage4_restore_from_reserve.sh
scp ${HOME}/transfer/products_before_delete.dump postgres0@pg125:${HOME}/transfer/products_before_delete.dump
```

На `primary`:

```bash
mkdir -p ${HOME}/transfer
pg_restore --clean --if-exists --no-owner --no-privileges -h localhost -p 9099 -d bigbluecity -t public.products ${HOME}/transfer/products_before_delete.dump
psql -v ON_ERROR_STOP=1 -h localhost -p 9099 -d bigbluecity -c 'TABLE products;'
```
