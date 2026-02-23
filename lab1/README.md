# Лабораторная работа №1

## Настройка кластера PostgreSQL

### Параметры варианта

- **Директория кластера**: `$HOME/nwc36`
- **Порт**: `9099`
- **Кодировка**: `UTF8`
- **Локаль**: `ru_RU.UTF-8`
- **Табличные пространства**: `$HOME/sbm10`, `$HOME/nym69`
- **База данных**: `bigbluecity`
- **Роль**: `dbuser` (пароль: `secure_password_123`)

---

## Структура проекта

```
lab1/
├── README.md                    # Этот файл
├── REPORT.md                    # Подробный отчет
├── config/                      # Конфигурационные файлы
│   ├── postgresql.conf          # Конфигурация PostgreSQL
│   └── pg_hba.conf             # Настройки доступа
└── scripts/                     # Исполняемые скрипты
    ├── init.sh                  # 1. Инициализация кластера
    ├── config.sql               # 2. Создание БД и ролей
    ├── table_spaces.sql         # 3. Создание табличных пространств
    ├── create.sql               # 4. Создание таблиц
    ├── seeds.sql                # 5. Наполнение данными
    └── clean.sh                 # Очистка (удаление всего)
```

---

## Порядок выполнения

### Переменные окружения

Перед началом работы загрузите переменные окружения:

```bash
# Локально (для разработки)
source scripts/env.sh

# На сервере postgres0@pg125
source scripts/env-server.sh
```

Файл `env-server.sh` использует путь `/var/db/postgres0` вместо стандартного `$HOME`.

### 1. Инициализация кластера

```bash
./scripts/init.sh
```

Скрипт выполняет:

- Инициализацию кластера PostgreSQL в `$HOME/nwc36`
- Копирование конфигурационных файлов
- Создание необходимых директорий
- Установку русской локали и кодировки UTF8

### 2. Запуск сервера

```bash
pg_ctl -D $HOME/nwc36 -l $HOME/nwc36/logfile start
```

Проверка статуса:

```bash
pg_ctl -D $HOME/nwc36 status
```

**Локально:**

```bash
psql -p 9099 -d postgres -f scripts/table_spaces.sql
```

**ВАЖНО**: Перед выполнением отредактируйте файл `scripts/table_spaces.sql` и раскомментируйте строки CREATE TABLESPACE, указав полные пути.

**На сервере postgres0@pg125:**

```bash
# Используйте готовый файл с путями для сервера
psql -p 9099 -d postgres -f scripts/table_spaces-server.sql
```

Файл `table_spaces-server.sql` уже содержит правильные пути для сервера:

- `/var/db/postgres0/sbm10`
- `/var/db/postgres0/nym69

### 4. Создание табличных пространств

```bash
psql -p 9099 -d postgres -f scripts/table_spaces.sql
```

**ВАЖНО**: Перед выполнением отредактируйте файл `scripts/table_spaces.sql` и замените `:HOME` на полный путь к вашему домашнему каталогу.

Например:

```sql
CREATE TABLESPACE sbm10_space LOCATION '/home/postgres1/sbm10';
CREATE TABLESPACE nym69_space LOCATION '/home/postgres1/nym69';
```

Создаёт:

- Табличное пространство `sbm10_space`
- Табличное пространство `nym69_space`
- Предоставляет права роли `dbuser`

### 5. Создание структуры таблиц

```bash
psql -p 9099 -h localhost -U dbuser -d bigbluecity -f scripts/create.sql
```

**Пароль**: `secure_password_123`

Создаёт:

- Партицированную таблицу `sales` с 4 партициями (Q1-Q4 2024)
- Таблицу `customers` (default tablespace)
- Таблицу `products` (sbm10_space)
- Таблицу `stores` (nym69_space)
- Индексы в разных табличных пространствах
- Материализованное представление `sales_summary`
- Обычное представление `sales_analytics`

### 6. Наполнение данными

```bash
psql -p 9099 -h localhost -U dbuser -d bigbluecity -f scripts/seeds.sql
```

**Пароль**: `secure_password_123`

Добавляет:

- 12 клиентов
- 15 товаров
- 5 магазинов
- 10,000 записей о продажах (распределены по партициям)

---

## Полезные команды

### Подключение к базе данных

**Через Unix socket (peer):**

```bash
psql -p 9099 -d bigbluecity
```

**Через TCP/IP (с паролем):**

```bash
psql -p 9099 -h localhost -U dbuser -d bigbluecity
```

### Управление сервером

```bash
# Остановка
pg_ctl -D $HOME/nwc36 stop

# Перезапуск
pg_ctl -D $HOME/nwc36 restart

# Перезагрузка конфигурации без перезапуска
pg_ctl -D $HOME/nwc36 reload

# Статус
pg_ctl -D $HOME/nwc36 status
```

### Просмотр логов

```bash
# Основной лог сервера
tail -f $HOME/nwc36/logfile

# Подробные логи PostgreSQL
tail -f $HOME/nwc36/log/postgresql-*.log

# Последние 50 строк
tail -n 50 $HOME/nwc36/log/postgresql-*.log
```

### Проверка конфигурации

```bash
psql -p 9099 -d postgres -c "SHOW ALL;"
psql -p 9099 -d postgres -c "SHOW port;"
psql -p 9099 -d postgres -c "SHOW shared_buffers;"
psql -p 9099 -d postgres -c "SHOW max_connections;"
```

---

## Проверка табличных пространств

### Список всех табличных пространств

```sql
SELECT 
    spcname AS "Имя",
    pg_catalog.pg_get_userbyid(spcowner) AS "Владелец",
    pg_catalog.pg_tablespace_location(oid) AS "Расположение"
FROM pg_catalog.pg_tablespace
ORDER BY spcname;
```

### Объекты в табличных пространствах

```sql
-- Таблицы по табличным пространствам
SELECT 
    schemaname,
    tablename,
    tablespace
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablespace, tablename;

-- Индексы по табличным пространствам  
SELECT 
    schemaname,
    indexname,
    tablename,
    tablespace
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablespace, indexname;

-- Все объекты с размерами
SELECT 
    n.nspname AS "Схема",
    c.relname AS "Объект",
    CASE c.relkind
        WHEN 'r' THEN 'таблица'
        WHEN 'i' THEN 'индекс'
        WHEN 'm' THEN 'материализованное представление'
        WHEN 'p' THEN 'партицированная таблица'
        ELSE c.relkind::text
    END AS "Тип",
    COALESCE(t.spcname, '(default)') AS "Табличное пространство",
    pg_size_pretty(pg_relation_size(c.oid)) AS "Размер"
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE n.nspname = 'public'
    AND c.relkind IN ('r', 'i', 'm', 'p')
ORDER BY c.relkind, c.relname;
```

### Размеры табличных пространств

```sql
SELECT 
    spcname AS "Табличное пространство",
    pg_size_pretty(pg_tablespace_size(spcname)) AS "Размер"
FROM pg_tablespace
ORDER BY pg_tablespace_size(spcname) DESC;
```

---

## Статистика данных

### Количество записей

```sql
SELECT 
    relname AS "Таблица",
    n_live_tup AS "Записей"
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;
```

### Распределение по партициям

```sql
SELECT 
    'sales_2024_q1' AS "Партиция",
    COUNT(*) AS "Записей",
    MIN(sale_date) AS "От",
    MAX(sale_date) AS "До"
FROM sales_2024_q1
UNION ALL
SELECT 'sales_2024_q2', COUNT(*), MIN(sale_date), MAX(sale_date) FROM sales_2024_q2
UNION ALL
SELECT 'sales_2024_q3', COUNT(*), MIN(sale_date), MAX(sale_date) FROM sales_2024_q3
UNION ALL
SELECT 'sales_2024_q4', COUNT(*), MIN(sale_date), MAX(sale_date) FROM sales_2024_q4;
```

### Топ продаж по регионам

```sql
SELECT 
    region AS "Регион",
    COUNT(*) AS "Продаж",
    SUM(price * quantity) AS "Выручка",
    ROUND(AVG(price * quantity), 2) AS "Средний чек"
FROM sales
GROUP BY region
ORDER BY "Выручка" DESC;
```

---

## Очистка

**ВНИМАНИЕ**: Удаляет ВСЕ данные!

```bash
./scripts/clean.sh
```

Удаляет:

- Кластер PostgreSQL (`$HOME/nwc36`)
- Табличные пространства (`$HOME/sbm10`, `$HOME/nym69`)
- Архив WAL (`/tmp/archive`)

---

## Параметры OLTP

Конфигурация оптимизирована для OLTP-сценария:

- **1500 транзакций/сек**
- **Размер транзакции: 24KB**
- **High Availability (HA)**

Основные параметры:

- `max_connections = 200`
- `shared_buffers = 2GB`
- `work_mem = 8MB`
- `effective_cache_size = 6GB`
- `checkpoint_timeout = 10min`
- `fsync = on` (для HA)
- `commit_delay = 10`
- `wal_level = replica`
- `archive_mode = on`

---

## Способы подключения

Согласно заданию настроены 2 способа:

### 1. Unix-domain сокет (peer)

```bash
psql -p 9099 -d bigbluecity
```

Аутентификация по имени пользователя ОС.

### 2. TCP/IP localhost (scram-sha-256)

```bash
psql -p 9099 -h localhost -U dbuser -d bigbluecity
```

Аутентификация по паролю SHA-256.

**Все остальные способы подключения запрещены.**

---

## Логирование

Настроено согласно заданию:

- **Формат файлов**: `.log`
- **Уровень**: `NOTICE`
- **Дополнительно логируются**:
  - Попытки подключения (`log_connections = on`)
  - Завершение сессий (`log_disconnections = on`)

Логи находятся в: `$HOME/nwc36/log/`

---

## Troubleshooting

### Ошибка "could not connect to server"

```bash
# Проверьте, запущен ли сервер
pg_ctl -D $HOME/nwc36 status

# Запустите сервер
pg_ctl -D $HOME/nwc36 start
```

### Ошибка "tablespace location must be an absolute path"

При создании табличных пространств используйте полный путь:

```sql
CREATE TABLESPACE sbm10_space LOCATION '/home/postgres1/sbm10';
```

### Ошибка "authentication failed"

Проверьте:

1. Для Unix socket используйте команду без `-h`
2. Для TCP/IP обязательно указывайте `-h localhost`
3. Правильность пароля: `secure_password_123`

### Порт уже занят

Измените порт в конфигурации:

```bash
nano $HOME/nwc36/postgresql.conf
# Найдите строку: port = 9099
# Измените на другой порт
```

---

## Контакты

По вопросам выполнения лабораторной работы обращайтесь к преподавателю.

---

**Версия**: 1.0  
**Дата**: Февраль 2026
