-- setup.sql
-- Самодостаточный SQL для создания БД/роли/табличных пространств и данных.
-- Запуск:
--   psql -v ON_ERROR_STOP=1 -p 9099 -d postgres -f scripts/setup.sql

\set ON_ERROR_STOP on
\set db_name bigbluecity
\set app_user dbuser
\set app_password secure_password_123
\set ts1_name sbm10_space
\set ts2_name nym69_space
\getenv home_dir HOME

\echo '[setup] create db/role/tablespaces'

SELECT format(
  'CREATE DATABASE bigbluecity WITH TEMPLATE template0 ENCODING ''UTF8'' LC_COLLATE ''ru_RU.UTF-8'' LC_CTYPE ''ru_RU.UTF-8'' OWNER %I',
  current_user
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_database WHERE datname = 'bigbluecity'
)\gexec

SELECT
  'CREATE ROLE dbuser LOGIN PASSWORD ''secure_password_123'' VALID UNTIL ''infinity'''
WHERE NOT EXISTS (
  SELECT 1 FROM pg_roles WHERE rolname = 'dbuser'
)\gexec

ALTER ROLE dbuser WITH LOGIN PASSWORD 'secure_password_123' VALID UNTIL 'infinity';

GRANT CONNECT ON DATABASE bigbluecity TO dbuser;
GRANT CONNECT ON DATABASE postgres TO dbuser;

SELECT format(
  'CREATE TABLESPACE sbm10_space OWNER %I LOCATION %L',
  current_user,
  :'home_dir' || '/sbm10'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_tablespace WHERE spcname = 'sbm10_space'
)\gexec

SELECT format(
  'CREATE TABLESPACE nym69_space OWNER %I LOCATION %L',
  current_user,
  :'home_dir' || '/nym69'
)
WHERE NOT EXISTS (
  SELECT 1 FROM pg_tablespace WHERE spcname = 'nym69_space'
)\gexec

GRANT CREATE ON TABLESPACE sbm10_space TO dbuser;
GRANT CREATE ON TABLESPACE nym69_space TO dbuser;

\connect bigbluecity

GRANT USAGE, CREATE ON SCHEMA public TO dbuser;
SET ROLE dbuser;

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
) TABLESPACE sbm10_space;

CREATE TABLE IF NOT EXISTS stores (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  city TEXT,
  region TEXT
) TABLESPACE nym69_space;

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
TABLESPACE sbm10_space;

CREATE TABLE IF NOT EXISTS sales_2024_q2 PARTITION OF sales
FOR VALUES FROM ('2024-04-01') TO ('2024-07-01')
TABLESPACE nym69_space;

CREATE TABLE IF NOT EXISTS sales_2024_q3 PARTITION OF sales
FOR VALUES FROM ('2024-07-01') TO ('2024-10-01')
TABLESPACE sbm10_space;

CREATE TABLE IF NOT EXISTS sales_2024_q4 PARTITION OF sales
FOR VALUES FROM ('2024-10-01') TO ('2025-01-01')
TABLESPACE nym69_space;

CREATE INDEX IF NOT EXISTS idx_sales_date
ON sales (sale_date)
TABLESPACE nym69_space;

CREATE INDEX IF NOT EXISTS idx_sales_region
ON sales (region)
TABLESPACE sbm10_space;

CREATE INDEX IF NOT EXISTS idx_products_category
ON products (category)
TABLESPACE nym69_space;

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
TABLESPACE nym69_space
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
TABLESPACE sbm10_space;

RESET ROLE;
