-- check.sql
-- Проверка результата лабораторной.

\set ON_ERROR_STOP on

\if :{?db_name}
\else
\set db_name bigbluecity
\endif

\echo ''
\echo '=== SETTINGS ==='
SELECT name, setting
FROM pg_settings
WHERE name IN (
    'port',
    'max_connections',
    'shared_buffers',
    'temp_buffers',
    'work_mem',
    'checkpoint_timeout',
    'effective_cache_size',
    'fsync',
    'commit_delay',
    'log_min_messages',
    'log_connections',
    'log_disconnections'
)
ORDER BY name;

\echo ''
\echo '=== TABLESPACES ==='
SELECT
    spcname AS tablespace,
    pg_catalog.pg_get_userbyid(spcowner) AS owner,
    pg_catalog.pg_tablespace_location(oid) AS location
FROM pg_catalog.pg_tablespace
ORDER BY spcname;

\connect :db_name

\echo ''
\echo '=== OBJECTS BY TABLESPACE ==='
SELECT
    COALESCE(t.spcname, '(default)') AS tablespace,
    n.nspname AS schema,
    c.relname AS object_name,
    c.relkind AS kind
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_tablespace t ON t.oid = c.reltablespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p', 'i', 'm')
ORDER BY tablespace, kind, object_name;

\echo ''
\echo '=== ROW COUNTS ==='
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
ORDER BY table_name;

\echo ''
\echo '=== PARTITIONS USAGE ==='
SELECT tableoid::regclass AS partition_name, COUNT(*) AS rows
FROM sales
GROUP BY tableoid
ORDER BY partition_name;
