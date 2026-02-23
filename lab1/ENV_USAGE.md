# Использование переменных окружения

Все скрипты теперь используют переменные окружения, которые экспортируются через `export`, что позволяет использовать их как в скриптах, так и в командной строке.

## Файл переменных: scripts/env.sh

Содержит все основные параметры конфигурации:

```bash
export CLUSTER_DIR="$HOME/nwc36"
export PG_PORT=9099
export PG_DATABASE="bigbluecity"
export PG_USER="dbuser"
export PG_PASSWORD="secure_password_123"
export TABLESPACE_DIR_1="$HOME/sbm10"
export TABLESPACE_DIR_2="$HOME/nym69"
export TABLESPACE_NAME_1="sbm10_space"
export TABLESPACE_NAME_2="nym69_space"
export ARCHIVE_DIR="/tmp/archive"
export PG_LOCALE="ru_RU.UTF-8"
export PG_ENCODING="UTF8"
```

## Использование

### 1. Загрузка переменных в текущую сессию

```bash
# Загрузить переменные в текущую оболочку
source scripts/env.sh

# Или короткая форма
. scripts/env.sh

# Теперь переменные доступны
echo $CLUSTER_DIR
echo $PG_PORT
```

### 2. Использование в командной строке

После загрузки переменных можно использовать их в командах:

```bash
# Загрузка переменных
source scripts/env.sh

# Использование переменных
pg_ctl -D $CLUSTER_DIR status
psql -p $PG_PORT -d $PG_DATABASE
psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE

# С паролем
PGPASSWORD="$PG_PASSWORD" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE
```

### 3. Использование в скриптах

Все скрипты автоматически загружают переменные из `env.sh`:

```bash
./scripts/init.sh       # Автоматически загружает переменные
./scripts/status.sh     # Автоматически загружает переменные
./scripts/setup_all.sh  # Автоматически загружает переменные
```

### 4. Переопределение переменных

Можно переопределить любую переменную перед запуском:

```bash
# Переопределить порт
export PG_PORT=5432
./scripts/status.sh

# Или в одной строке
PG_PORT=5432 ./scripts/status.sh
```

### 5. Добавить в .bashrc или .zshrc

Для автоматической загрузки при каждом входе:

```bash
# Добавить в ~/.bashrc или ~/.zshrc
echo "source ~/ddss/lab1/scripts/env.sh" >> ~/.bashrc

# Или с условием
cat >> ~/.bashrc << 'EOF'
if [ -f ~/ddss/lab1/scripts/env.sh ]; then
    source ~/ddss/lab1/scripts/env.sh
fi
EOF
```

## Полный список переменных

| Переменная | Значение по умолчанию | Описание |
|------------|----------------------|----------|
| `CLUSTER_DIR` | `$HOME/nwc36` | Директория кластера PostgreSQL |
| `PG_PORT` | `9099` | Порт PostgreSQL |
| `PG_DATABASE` | `bigbluecity` | Имя базы данных |
| `PG_USER` | `dbuser` | Имя пользователя |
| `PG_PASSWORD` | `secure_password_123` | Пароль пользователя |
| `TABLESPACE_DIR_1` | `$HOME/sbm10` | Директория 1-го табличного пространства |
| `TABLESPACE_DIR_2` | `$HOME/nym69` | Директория 2-го табличного пространства |
| `TABLESPACE_NAME_1` | `sbm10_space` | Имя 1-го табличного пространства |
| `TABLESPACE_NAME_2` | `nym69_space` | Имя 2-го табличного пространства |
| `ARCHIVE_DIR` | `/tmp/archive` | Директория архива WAL |
| `PG_LOCALE` | `ru_RU.UTF-8` | Локаль PostgreSQL |
| `PG_ENCODING` | `UTF8` | Кодировка PostgreSQL |
| `PGDATA` | `$CLUSTER_DIR` | Алиас для совместимости |
| `PGPORT` | `$PG_PORT` | Алиас для совместимости |

## Примеры команд с переменными

```bash
# Загрузить переменные
source scripts/env.sh

# Запуск сервера
pg_ctl -D $CLUSTER_DIR -l $CLUSTER_DIR/logfile start

# Остановка сервера
pg_ctl -D $CLUSTER_DIR stop

# Подключение через Unix socket
psql -p $PG_PORT -d $PG_DATABASE

# Подключение через TCP/IP
psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE

# С паролем через переменную окружения
PGPASSWORD="$PG_PASSWORD" psql -p $PG_PORT -h localhost -U $PG_USER -d $PG_DATABASE

# Выполнение SQL файла
psql -p $PG_PORT -d postgres -f scripts/config.sql

# Просмотр логов
tail -f $CLUSTER_DIR/logfile

# Размер кластера
du -sh $CLUSTER_DIR

# Размер табличных пространств
du -sh $TABLESPACE_DIR_1 $TABLESPACE_DIR_2
```

## Изменения в существующих скриптах

Все скрипты были обновлены:

- Эмодзи удалены из всех выводов
- Переменные экспортируются через `export`
- Автоматическая загрузка `env.sh` при запуске
- Fallback на значения по умолчанию, если `env.sh` не найден

## Использование на сервере postgres0@pg125

На сервере домашний каталог находится по нестандартному пути `/var/db/postgres0`.

### Вариант 1: Использовать env-server.sh

```bash
# Загрузить серверные переменные
source scripts/env-server.sh

# Теперь PG_BASE_DIR=/var/db/postgres0
echo $PG_BASE_DIR

# Запустить установку
./scripts/init.sh
psql -p $PG_PORT -h localhost postgres -f scripts/config.sql
```

### Вариант 2: Использовать готовый SQL для сервера

Для табличных пространств на сервере используйте `table_spaces-server.sql` вместо `table_spaces.sql`:

```bash
# На сервере (postgres0@pg125)
source scripts/env-server.sh
psql -p $PG_PORT -h localhost postgres -f scripts/table_spaces-server.sql
```

Файл `table_spaces-server.sql` содержит жёстко прописанные пути:

- `/var/db/postgres0/sbm10`
- `/var/db/postgres0/nym69`

Это необходимо, так как на сервере домашний каталог находится не в стандартном месте.
