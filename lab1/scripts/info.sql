-- ============================================
-- Скрипт для вывода информации о табличных пространствах
-- Лабораторная работа №1
-- ============================================

\echo '=============================================='
\echo '  ИНФОРМАЦИЯ О ТАБЛИЧНЫХ ПРОСТРАНСТВАХ'
\echo '=============================================='
\echo ''

-- Подключение к базе bigbluecity
\connect bigbluecity

\echo '[*] 1. Список всех табличных пространств кластера'
\echo '================================================'
\echo ''

SELECT 
    spcname AS "Имя табличного пространства",
    pg_catalog.pg_get_userbyid(spcowner) AS "Владелец",
    pg_catalog.pg_tablespace_location(oid) AS "Расположение",
    pg_size_pretty(pg_tablespace_size(spcname)) AS "Размер"
FROM pg_catalog.pg_tablespace
ORDER BY spcname;

\echo ''
\echo '[+] 2. Таблицы по табличным пространствам'
\echo '========================================'
\echo ''

SELECT 
    COALESCE(tablespace, '(default)') AS "Табличное пространство",
    schemaname AS "Схема",
    tablename AS "Таблица",
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS "Размер"
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablespace NULLS FIRST, tablename;

\echo ''
\echo '[i] 3. Индексы по табличным пространствам'
\echo '========================================'
\echo ''

SELECT 
    COALESCE(tablespace, '(default)') AS "Табличное пространство",
    schemaname AS "Схема",
    indexname AS "Индекс",
    tablename AS "Таблица",
    pg_size_pretty(pg_relation_size(schemaname||'.'||indexname)) AS "Размер"
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablespace NULLS FIRST, indexname;

\echo ''
\echo '[*] 4. Все объекты базы данных с табличными пространствами'
\echo '========================================================='
\echo ''

SELECT 
    n.nspname AS "Схема",
    c.relname AS "Объект",
    CASE c.relkind
        WHEN 'r' THEN 'таблица'
        WHEN 'i' THEN 'индекс'
        WHEN 'S' THEN 'последовательность'
        WHEN 'v' THEN 'представление'
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
    AND c.relkind IN ('r', 'i', 'S', 'v', 'm', 'p')
ORDER BY 
    CASE c.relkind
        WHEN 'r' THEN 1
        WHEN 'p' THEN 2
        WHEN 'i' THEN 3
        WHEN 'm' THEN 4
        WHEN 'v' THEN 5
        ELSE 6
    END,
    c.relname;

\echo ''
\echo '[*] 5. Размер табличных пространств'
\echo '=================================='
\echo ''

SELECT 
    spcname AS "Табличное пространство",
    pg_size_pretty(pg_tablespace_size(spcname)) AS "Размер",
    ROUND(pg_tablespace_size(spcname) * 100.0 / 
        NULLIF(SUM(pg_tablespace_size(spcname)) OVER (), 0), 2) AS "Процент"
FROM pg_tablespace
ORDER BY pg_tablespace_size(spcname) DESC;

\echo ''
\echo '[*] 6. Детальное распределение объектов по табличным пространствам'
\echo '================================================================='
\echo ''

WITH tablespace_objects AS (
    SELECT 
        COALESCE(t.spcname, '(default)') AS tablespace_name,
        CASE c.relkind
            WHEN 'r' THEN 'Обычные таблицы'
            WHEN 'i' THEN 'Индексы'
            WHEN 'm' THEN 'Материализованные представления'
            WHEN 'p' THEN 'Партицированные таблицы'
            ELSE 'Другое'
        END AS object_type,
        COUNT(*) AS object_count,
        pg_size_pretty(SUM(pg_relation_size(c.oid))) AS total_size,
        SUM(pg_relation_size(c.oid)) AS size_bytes
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
    WHERE n.nspname = 'public'
        AND c.relkind IN ('r', 'i', 'm', 'p')
    GROUP BY tablespace_name, object_type
)
SELECT 
    tablespace_name AS "Табличное пространство",
    object_type AS "Тип объекта",
    object_count AS "Количество",
    total_size AS "Общий размер"
FROM tablespace_objects
ORDER BY 
    tablespace_name,
    CASE object_type
        WHEN 'Партицированные таблицы' THEN 1
        WHEN 'Обычные таблицы' THEN 2
        WHEN 'Материализованные представления' THEN 3
        WHEN 'Индексы' THEN 4
        ELSE 5
    END;

\echo ''
\echo '[*] 7. Статистика по партициям таблицы sales'
\echo '==========================================='
\echo ''

SELECT 
    c.relname AS "Партиция",
    COALESCE(t.spcname, '(default)') AS "Табличное пространство",
    pg_size_pretty(pg_relation_size(c.oid)) AS "Размер таблицы",
    pg_size_pretty(pg_indexes_size(c.oid)) AS "Размер индексов",
    pg_size_pretty(pg_total_relation_size(c.oid)) AS "Общий размер",
    (SELECT COUNT(*) FROM sales WHERE tableoid = c.oid) AS "Записей"
FROM pg_class c
LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE c.relname LIKE 'sales_2024_%'
ORDER BY c.relname;

\echo ''
\echo '=============================================='
\echo '  КОНЕЦ ОТЧЁТА'
\echo '=============================================='
\echo ''
