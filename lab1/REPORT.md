# Отчет по лабораторной работе №1

## Настройка кластера PostgreSQL

**Параметры варианта:**

- Директория кластера: `$HOME/nwc36`
- Порт: `9099`
- Табличные пространства: `$HOME/sbm10`, `$HOME/nym69`
- База данных: `bigbluecity`
- Сценарий: OLTP (1500 транзакций/сек, 24KB, High Availability)

---

## Этап 1. Инициализация кластера БД

### Команда инициализации

```bash
initdb -D $HOME/nwc36 \
  --encoding=UTF8 \
  --locale=ru_RU.UTF-8 \
  --lc-collate=ru_RU.UTF-8 \
  --lc-ctype=ru_RU.UTF-8 \
  --lc-messages=ru_RU.UTF-8 \
  --lc-monetary=ru_RU.UTF-8 \
  --lc-numeric=ru_RU.UTF-8 \
  --lc-time=ru_RU.UTF-8 \
  --data-checksums \
  --auth=peer \
  --auth-host=scram-sha-256 \
  --pwprompt
```

**Параметры:**

- `-D $HOME/nwc36` - директория кластера
- `--encoding=UTF8` - кодировка UTF8
- `--locale=ru_RU.UTF-8` - русская локаль
- `--data-checksums` - контрольные суммы для обеспечения целостности данных
- `--auth=peer` - аутентификация через Unix-domain сокет
- `--auth-host=scram-sha-256` - аутентификация TCP/IP по паролю SHA-256
- `--pwprompt` - запрос пароля суперпользователя

### Проверка инициализации

```bash
ls -la $HOME/nwc36
cat $HOME/nwc36/PG_VERSION
```

---

## Этап 2. Конфигурация и запуск сервера БД

### 2.1 Настройка postgresql.conf

**Файл:** `$HOME/nwc36/postgresql.conf`

**Изменяемые параметры:**

#### Параметры подключения

```conf
# Порт и прослушивание
port = 9099
listen_addresses = 'localhost'
unix_socket_directories = '/tmp'

# Максимум подключений
max_connections = 200
```

#### Параметры памяти (OLTP сценарий)

```conf
# Разделяемая память (25% от RAM, примерно 2GB для типичного сервера)
shared_buffers = 2GB

# Временные буферы для сессии
temp_buffers = 32MB

# Память для операций сортировки/join (для OLTP меньше)
work_mem = 8MB

# Эффективный размер кеша (50-75% RAM, примерно 6GB)
effective_cache_size = 6GB
```

#### Параметры WAL и контрольных точек (High Availability)

```conf
# WAL директория (по умолчанию $PGDATA/pg_wal)
# Для HA рекомендуется на отдельном диске, но по заданию оставляем в $PGDATA/pg_wal

# Включить fsync для надежности данных (важно для HA)
fsync = on

# Интервал контрольных точек (для OLTP 5-10 минут)
checkpoint_timeout = 10min

# Минимальный размер сегмента WAL
min_wal_size = 1GB
max_wal_size = 4GB

# Задержка коммита (для OLTP можно добавить небольшую задержку для группировки)
commit_delay = 10
commit_siblings = 5

# Синхронный коммит (для HA обязательно on)
synchronous_commit = on

# Уровень WAL (для репликации нужен replica или выше)
wal_level = replica

# Архивирование WAL (для HA)
archive_mode = on
archive_command = 'test ! -f /tmp/archive/%f && cp %p /tmp/archive/%f'
```

#### Параметры логирования

```conf
# Директория логов
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB

# Уровень сообщений
log_min_messages = notice
log_min_error_statement = error

# Логирование подключений и завершений сессий
log_connections = on
log_disconnections = on

# Дополнительная информация
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_timezone = 'Europe/Moscow'
```

#### Параметры производительности для OLTP

```conf
# Параллельные операции
max_worker_processes = 8
max_parallel_workers = 8
max_parallel_workers_per_gather = 2

# Статистика
shared_preload_libraries = 'pg_stat_statements'
```

### 2.2 Настройка pg_hba.conf

**Файл:** `$HOME/nwc36/pg_hba.conf`

**Содержимое:**

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Unix domain socket connections (peer)
local   all             all                                     peer

# TCP/IP connections from localhost only (scram-sha-256)
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Запретить все остальные подключения
# (удалить все другие строки из файла)
```

**Объяснение настроек:**

- `local ... peer` - Unix-domain сокет с аутентификацией peer
- `host ... 127.0.0.1/32 scram-sha-256` - TCP/IP только с localhost, аутентификация SHA-256
- `host ... ::1/128 scram-sha-256` - То же для IPv6

### 2.3 Создание архивной директории

```bash
mkdir -p /tmp/archive
chmod 700 /tmp/archive
```

### 2.4 Запуск сервера

```bash
# Запуск
pg_ctl -D $HOME/nwc36 -l $HOME/nwc36/logfile start

# Проверка статуса
pg_ctl -D $HOME/nwc36 status

# Проверка подключения
psql -p 9099 -d postgres -c "SELECT version();"
```

### 2.5 Остановка и перезапуск

```bash
# Остановка
pg_ctl -D $HOME/nwc36 stop

# Перезапуск
pg_ctl -D $HOME/nwc36 restart

# Перезагрузка конфигурации без перезапуска
pg_ctl -D $HOME/nwc36 reload
```

---

## Этап 3. Табличные пространства и наполнение базы

### 3.1 Создание директорий для табличных пространств

```bash
# Создать директории
mkdir -p $HOME/sbm10
mkdir -p $HOME/nym69

# Установить права
chmod 700 $HOME/sbm10
chmod 700 $HOME/nym69
```

### 3.2 Создание табличных пространств

```sql
-- Подключиться к PostgreSQL
psql -p 9099 -d postgres

-- Создать табличные пространства
CREATE TABLESPACE sbm10_space 
    LOCATION '/home/postgresY/sbm10';

CREATE TABLESPACE nym69_space 
    LOCATION '/home/postgresY/nym69';
    
-- Примечание: замените /home/postgresY на ваш фактический $HOME путь
-- Можно использовать: CREATE TABLESPACE sbm10_space LOCATION '/полный/путь/к/sbm10';
```

### 3.3 Создание базы данных

```sql
-- Создать базу на основе template0
CREATE DATABASE bigbluecity 
    WITH TEMPLATE = template0
    ENCODING = 'UTF8'
    LC_COLLATE = 'ru_RU.UTF-8'
    LC_CTYPE = 'ru_RU.UTF-8'
    OWNER = postgres;

-- Проверить создание
\l bigbluecity
```

### 3.4 Создание новой роли

```sql
-- Создать роль с правом входа
CREATE ROLE dbuser WITH LOGIN PASSWORD 'secure_password_123';

-- Предоставить права на базу данных
GRANT CONNECT ON DATABASE bigbluecity TO dbuser;
GRANT USAGE ON SCHEMA public TO dbuser;
GRANT CREATE ON SCHEMA public TO dbuser;

-- Предоставить права на табличные пространства
GRANT CREATE ON TABLESPACE sbm10_space TO dbuser;
GRANT CREATE ON TABLESPACE nym69_space TO dbuser;

-- Проверить роль
\du dbuser
```

### 3.5 Наполнение базы данных

**Подключение от имени новой роли:**

```bash
psql -p 9099 -h localhost -U dbuser -d bigbluecity
# Введите пароль: secure_password_123
```

**SQL скрипт для создания партицированной таблицы и наполнения:**

```sql
-- Создать основную партицированную таблицу
CREATE TABLE sales (
    id SERIAL,
    sale_date DATE NOT NULL,
    product_name VARCHAR(100),
    quantity INTEGER,
    price NUMERIC(10,2),
    customer_name VARCHAR(100),
    region VARCHAR(50)
) PARTITION BY RANGE (sale_date);

-- Создать партиции в разных табличных пространствах
CREATE TABLE sales_2024_q1 PARTITION OF sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01')
    TABLESPACE sbm10_space;

CREATE TABLE sales_2024_q2 PARTITION OF sales
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01')
    TABLESPACE nym69_space;

CREATE TABLE sales_2024_q3 PARTITION OF sales
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01')
    TABLESPACE sbm10_space;

CREATE TABLE sales_2024_q4 PARTITION OF sales
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01')
    TABLESPACE nym69_space;

-- Создать таблицу в дефолтном табличном пространстве
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    registration_date DATE DEFAULT CURRENT_DATE
);

-- Создать таблицу в sbm10_space
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    price NUMERIC(10,2)
) TABLESPACE sbm10_space;

-- Создать индексы в разных табличных пространствах
CREATE INDEX idx_sales_date ON sales(sale_date) TABLESPACE nym69_space;
CREATE INDEX idx_customers_email ON customers(email) TABLESPACE sbm10_space;

-- Наполнить данными
INSERT INTO customers (name, email, phone) VALUES
    ('Иван Иванов', 'ivan@example.com', '+7-900-111-2233'),
    ('Мария Петрова', 'maria@example.com', '+7-900-222-3344'),
    ('Алексей Сидоров', 'alexey@example.com', '+7-900-333-4455'),
    ('Елена Смирнова', 'elena@example.com', '+7-900-444-5566'),
    ('Дмитрий Кузнецов', 'dmitry@example.com', '+7-900-555-6677');

INSERT INTO products (name, description, category, price) VALUES
    ('Ноутбук Dell', 'Ноутбук для работы', 'Электроника', 75000.00),
    ('Смартфон Samsung', 'Современный смартфон', 'Электроника', 45000.00),
    ('Книга "PostgreSQL"', 'Учебник по базам данных', 'Книги', 1500.00),
    ('Клавиатура Logitech', 'Беспроводная клавиатура', 'Аксессуары', 3500.00),
    ('Мышь Razer', 'Игровая мышь', 'Аксессуары', 5000.00);

-- Наполнить партицированную таблицу
INSERT INTO sales (sale_date, product_name, quantity, price, customer_name, region)
SELECT 
    DATE '2024-01-01' + (random() * 364)::integer as sale_date,
    'Product-' || (random() * 100)::integer as product_name,
    (random() * 10 + 1)::integer as quantity,
    (random() * 10000 + 100)::numeric(10,2) as price,
    'Customer-' || (random() * 100)::integer as customer_name,
    CASE (random() * 4)::integer
        WHEN 0 THEN 'Север'
        WHEN 1 THEN 'Юг'
        WHEN 2 THEN 'Восток'
        ELSE 'Запад'
    END as region
FROM generate_series(1, 10000);

-- Создать материализованное представление в nym69_space
CREATE MATERIALIZED VIEW sales_summary
TABLESPACE nym69_space
AS
SELECT 
    region,
    DATE_TRUNC('month', sale_date) as month,
    COUNT(*) as total_sales,
    SUM(price * quantity) as total_revenue
FROM sales
GROUP BY region, DATE_TRUNC('month', sale_date);
```

### 3.6 Вывод списка табличных пространств и объектов

```sql
-- Список всех табличных пространств
SELECT 
    spcname as "Имя табличного пространства",
    pg_catalog.pg_get_userbyid(spcowner) as "Владелец",
    pg_catalog.pg_tablespace_location(oid) as "Расположение"
FROM pg_catalog.pg_tablespace
ORDER BY spcname;

-- Объекты в табличном пространстве sbm10_space
SELECT 
    schemaname as "Схема",
    tablename as "Таблица",
    tablespace as "Табличное пространство"
FROM pg_tables
WHERE tablespace = 'sbm10_space'
ORDER BY schemaname, tablename;

-- Объекты в табличном пространстве nym69_space
SELECT 
    schemaname as "Схема",
    tablename as "Таблица",
    tablespace as "Табличное пространство"
FROM pg_tables
WHERE tablespace = 'nym69_space'
ORDER BY schemaname, tablename;

-- Индексы по табличным пространствам
SELECT 
    schemaname as "Схема",
    indexname as "Индекс",
    tablename as "Таблица",
    tablespace as "Табличное пространство"
FROM pg_indexes
WHERE tablespace IN ('sbm10_space', 'nym69_space')
ORDER BY tablespace, schemaname, indexname;

-- Все объекты базы данных с табличными пространствами
SELECT 
    n.nspname as "Схема",
    c.relname as "Объект",
    CASE c.relkind
        WHEN 'r' THEN 'таблица'
        WHEN 'i' THEN 'индекс'
        WHEN 'S' THEN 'последовательность'
        WHEN 'v' THEN 'представление'
        WHEN 'm' THEN 'материализованное представление'
        WHEN 'p' THEN 'партицированная таблица'
        ELSE c.relkind::text
    END as "Тип",
    t.spcname as "Табличное пространство",
    pg_size_pretty(pg_relation_size(c.oid)) as "Размер"
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE n.nspname = 'public'
ORDER BY c.relkind, c.relname;

-- Размер табличных пространств
SELECT 
    spcname as "Табличное пространство",
    pg_size_pretty(pg_tablespace_size(spcname)) as "Размер"
FROM pg_tablespace
ORDER BY spcname;
```

---

## Проверка конфигурации

### Проверка параметров сервера

```sql
-- Подключиться к базе
psql -p 9099 -d postgres

-- Проверить основные параметры
SHOW port;
SHOW listen_addresses;
SHOW max_connections;
SHOW shared_buffers;
SHOW work_mem;
SHOW checkpoint_timeout;
SHOW effective_cache_size;
SHOW fsync;
SHOW commit_delay;
SHOW log_min_messages;
SHOW log_connections;
SHOW log_disconnections;

-- Проверить все параметры
SELECT name, setting, unit, source 
FROM pg_settings 
WHERE source != 'default' 
ORDER BY name;
```

### Проверка подключений

```bash
# Unix-domain socket (peer)
psql -p 9099 -d postgres

# TCP/IP localhost (должен запросить пароль)
psql -h localhost -p 9099 -U postgres -d postgres

# От имени новой роли
psql -h localhost -p 9099 -U dbuser -d bigbluecity
```

### Проверка логов

```bash
# Просмотреть последний лог
tail -f $HOME/nwc36/log/postgresql-*.log

# Проверить подключения в логе
grep "connection" $HOME/nwc36/log/postgresql-*.log
```

---

## Дополнительные команды

### Резервное копирование

```bash
# Логическое резервное копирование
pg_dump -p 9099 -U postgres -Fc bigbluecity > bigbluecity_backup.dump

# Физическое резервное копирование (базовое)
pg_basebackup -D $HOME/backup -Ft -z -P -p 9099
```

### Восстановление

```bash
# Восстановление из логического бэкапа
pg_restore -p 9099 -U postgres -d bigbluecity bigbluecity_backup.dump
```

### Мониторинг

```sql
-- Текущие подключения
SELECT * FROM pg_stat_activity;

-- Размер баз данных
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Статистика таблиц
SELECT * FROM pg_stat_user_tables;
```

---

## Итоговая структура кластера

```
$HOME/nwc36/              # Основной кластер PGDATA
├── postgresql.conf       # Конфигурация сервера
├── pg_hba.conf          # Конфигурация доступа
├── pg_wal/              # WAL файлы
└── log/                 # Логи сервера

$HOME/sbm10/             # Табличное пространство sbm10_space
└── PG_16_*/             # Файлы таблиц и индексов

$HOME/nym69/             # Табличное пространство nym69_space
└── PG_16_*/             # Файлы таблиц и индексов

/tmp/archive/            # Архив WAL файлов
```

---

## Заключение

В ходе выполнения лабораторной работы были выполнены следующие задачи:

1. ✅ Инициализирован кластер PostgreSQL с кодировкой UTF8 и русской локалью
2. ✅ Настроены параметры сервера для OLTP сценария с обеспечением High Availability
3. ✅ Сконфигурированы способы подключения: Unix-domain сокет (peer) и TCP/IP localhost (scram-sha-256)
4. ✅ Созданы дополнительные табличные пространства sbm10 и nym69
5. ✅ Создана база данных bigbluecity на основе template0
6. ✅ Создана новая роль dbuser с необходимыми правами
7. ✅ Произведено наполнение базы данных с использованием всех табличных пространств
8. ✅ Выведен список всех табличных пространств и содержащихся в них объектов

Все параметры настроены в соответствии с требованиями задания для обеспечения высокой производительности OLTP-системы и высокой доступности данных.
