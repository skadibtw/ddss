-- setup.sql
-- Кластерные и прикладные объекты: БД, роль, табличные пространства, схема, данные.

\set ON_ERROR_STOP on

\if :{?db_name}
\else
\set db_name bigbluecity
\endif

\if :{?app_user}
\else
\set app_user dbuser
\endif

\if :{?app_password}
\else
\set app_password secure_password_123
\endif

\if :{?pg_locale}
\else
\set pg_locale ru_RU.UTF-8
\endif

\if :{?ts1_name}
\else
\set ts1_name sbm10_space
\endif

\if :{?ts2_name}
\else
\set ts2_name nym69_space
\endif

\if :{?ts1_dir}
\else
\echo 'ERROR: ts1_dir is required'
\quit 1
\endif

\if :{?ts2_dir}
\else
\echo 'ERROR: ts2_dir is required'
\quit 1
\endif

\echo '[setup] create database / role / tablespaces'

SELECT format(
    'CREATE DATABASE %I WITH TEMPLATE template0 ENCODING ''UTF8'' LC_COLLATE %L LC_CTYPE %L OWNER postgres',
    :'db_name',
    :'pg_locale',
    :'pg_locale'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_database WHERE datname = :'db_name'
)\gexec

SELECT format(
    'CREATE ROLE %I LOGIN PASSWORD %L VALID UNTIL ''infinity''',
    :'app_user',
    :'app_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = :'app_user'
)\gexec

SELECT format(
    'ALTER ROLE %I WITH LOGIN PASSWORD %L VALID UNTIL ''infinity''',
    :'app_user',
    :'app_password'
)\gexec

SELECT format('GRANT CONNECT ON DATABASE %I TO %I', :'db_name', :'app_user')\gexec
SELECT format('GRANT CONNECT ON DATABASE postgres TO %I', :'app_user')\gexec

SELECT format(
    'CREATE TABLESPACE %I OWNER postgres LOCATION %L',
    :'ts1_name',
    :'ts1_dir'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_tablespace WHERE spcname = :'ts1_name'
)\gexec

SELECT format(
    'CREATE TABLESPACE %I OWNER postgres LOCATION %L',
    :'ts2_name',
    :'ts2_dir'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_tablespace WHERE spcname = :'ts2_name'
)\gexec

SELECT format('GRANT CREATE ON TABLESPACE %I TO %I', :'ts1_name', :'app_user')\gexec
SELECT format('GRANT CREATE ON TABLESPACE %I TO %I', :'ts2_name', :'app_user')\gexec

\connect :db_name

SELECT format('GRANT USAGE, CREATE ON SCHEMA public TO %I', :'app_user')\gexec
SELECT format('SET ROLE %I', :'app_user')\gexec

\echo '[setup] create schema'

CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    city TEXT,
    registration_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT,
    price NUMERIC(10,2) CHECK (price >= 0)
) TABLESPACE :"ts1_name";

CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    city TEXT,
    region TEXT
) TABLESPACE :"ts2_name";

CREATE TABLE IF NOT EXISTS sales (
    id BIGSERIAL,
    sale_date DATE NOT NULL,
    product_name TEXT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    customer_name TEXT NOT NULL,
    region TEXT NOT NULL,
    PRIMARY KEY (id, sale_date)
) PARTITION BY RANGE (sale_date);

CREATE TABLE IF NOT EXISTS sales_2024_q1 PARTITION OF sales
FOR VALUES FROM ('2024-01-01') TO ('2024-04-01')
TABLESPACE :"ts1_name";

CREATE TABLE IF NOT EXISTS sales_2024_q2 PARTITION OF sales
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01')
TABLESPACE :"ts2_name";

CREATE TABLE IF NOT EXISTS sales_2024_q3 PARTITION OF sales
FOR VALUES FROM ('2024-07-01') TO ('2024-10-01')
TABLESPACE :"ts1_name";

CREATE TABLE IF NOT EXISTS sales_2024_q4 PARTITION OF sales
FOR VALUES FROM ('2024-10-01') TO ('2025-01-01')
TABLESPACE :"ts2_name";

CREATE INDEX IF NOT EXISTS idx_sales_date
ON sales (sale_date)
TABLESPACE :"ts2_name";

CREATE INDEX IF NOT EXISTS idx_sales_region
ON sales (region)
TABLESPACE :"ts1_name";

CREATE INDEX IF NOT EXISTS idx_products_category
ON products (category)
TABLESPACE :"ts2_name";

\echo '[setup] seed data'

TRUNCATE TABLE sales, customers, products, stores RESTART IDENTITY CASCADE;

INSERT INTO customers (name, email, city) VALUES
('Иван Иванов', 'ivan@example.com', 'Москва'),
('Мария Петрова', 'maria@example.com', 'Санкт-Петербург'),
('Алексей Сидоров', 'alex@example.com', 'Казань'),
('Елена Смирнова', 'elena@example.com', 'Самара');

INSERT INTO products (name, category, price) VALUES
('Ноутбук', 'Электроника', 120000.00),
('Смартфон', 'Электроника', 80000.00),
('Наушники', 'Аксессуары', 15000.00),
('Книга PostgreSQL', 'Книги', 2500.00);

INSERT INTO stores (name, city, region) VALUES
('Store A', 'Москва', 'Центр'),
('Store B', 'Санкт-Петербург', 'Север'),
('Store C', 'Казань', 'Восток');

INSERT INTO sales (sale_date, product_name, quantity, price, customer_name, region)
SELECT
    DATE '2024-01-01' + (random() * 364)::int,
    (ARRAY['Ноутбук','Смартфон','Наушники','Книга PostgreSQL'])[1 + (random() * 3)::int],
    1 + (random() * 4)::int,
    (1000 + random() * 120000)::numeric(10,2),
    (ARRAY['Иван Иванов','Мария Петрова','Алексей Сидоров','Елена Смирнова'])[1 + (random() * 3)::int],
    (ARRAY['Север','Юг','Восток','Запад'])[1 + (random() * 3)::int]
FROM generate_series(1, 3000);

DROP MATERIALIZED VIEW IF EXISTS sales_summary;
CREATE MATERIALIZED VIEW sales_summary
TABLESPACE :"ts2_name"
AS
SELECT
    region,
    date_trunc('month', sale_date)::date AS month,
    count(*) AS total_sales,
    sum(price * quantity) AS total_revenue
FROM sales
GROUP BY region, date_trunc('month', sale_date)
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_sales_summary_region_month
ON sales_summary (region, month)
TABLESPACE :"ts1_name";

RESET ROLE;
