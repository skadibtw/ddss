-- ============================================
-- Создание структуры базы данных
-- Лабораторная работа №1
-- Выполнять от имени роли dbuser
-- ============================================

\echo '======================================'
\echo '  Создание структуры базы данных'
\echo '======================================'
\echo ''

-- Установка формата вывода
\x auto

-- Подключение к базе bigbluecity
\connect bigbluecity

\echo '[*] Создание партицированной таблицы sales...'

-- Создание основной партицированной таблицы для продаж
CREATE TABLE IF NOT EXISTS sales (
    id SERIAL,
    sale_date DATE NOT NULL,
    product_name VARCHAR(100),
    quantity INTEGER CHECK (quantity > 0),
    price NUMERIC(10,2) CHECK (price >= 0),
    customer_name VARCHAR(100),
    region VARCHAR(50),
    PRIMARY KEY (id, sale_date)
) PARTITION BY RANGE (sale_date);

\echo '[OK] Таблица sales создана'
\echo ''

\echo '[+] Создание партиций в разных табличных пространствах...'

-- Q1 2024 в sbm10_space
CREATE TABLE IF NOT EXISTS sales_2024_q1 PARTITION OF sales
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01')
    TABLESPACE sbm10_space;

\echo '   ✓ sales_2024_q1 (sbm10_space)'

-- Q2 2024 в nym69_space
CREATE TABLE IF NOT EXISTS sales_2024_q2 PARTITION OF sales
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01')
    TABLESPACE nym69_space;

\echo '   ✓ sales_2024_q2 (nym69_space)'

-- Q3 2024 в sbm10_space
CREATE TABLE IF NOT EXISTS sales_2024_q3 PARTITION OF sales
    FOR VALUES FROM ('2024-07-01') TO ('2024-10-01')
    TABLESPACE sbm10_space;

\echo '   ✓ sales_2024_q3 (sbm10_space)'

-- Q4 2024 в nym69_space
CREATE TABLE IF NOT EXISTS sales_2024_q4 PARTITION OF sales
    FOR VALUES FROM ('2024-10-01') TO ('2025-01-01')
    TABLESPACE nym69_space;

\echo '   ✓ sales_2024_q4 (nym69_space)'
\echo ''

\echo '[*] Создание таблицы customers...'

-- Таблица клиентов в дефолтном табличном пространстве
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    registration_date DATE DEFAULT CURRENT_DATE,
    city VARCHAR(50),
    CONSTRAINT valid_email CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

\echo '[OK] Таблица customers создана (default tablespace)'
\echo ''

\echo '[+] Создание таблицы products...'

-- Таблица товаров в sbm10_space
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    price NUMERIC(10,2) CHECK (price >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) TABLESPACE sbm10_space;

\echo '[OK] Таблица products создана (sbm10_space)'
\echo ''

\echo '[*] Создание таблицы stores...'

-- Таблица магазинов в nym69_space
CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    city VARCHAR(50),
    region VARCHAR(50),
    opened_date DATE,
    manager VARCHAR(100)
) TABLESPACE nym69_space;

\echo '[OK] Таблица stores создана (nym69_space)'
\echo ''

\echo '[i] Создание индексов...'

-- Индексы в разных табличных пространствах
CREATE INDEX IF NOT EXISTS idx_sales_date 
    ON sales(sale_date) 
    TABLESPACE nym69_space;

CREATE INDEX IF NOT EXISTS idx_sales_region 
    ON sales(region) 
    TABLESPACE sbm10_space;

CREATE INDEX IF NOT EXISTS idx_customers_email 
    ON customers(email) 
    TABLESPACE sbm10_space;

CREATE INDEX IF NOT EXISTS idx_customers_city 
    ON customers(city) 
    TABLESPACE nym69_space;

CREATE INDEX IF NOT EXISTS idx_products_category 
    ON products(category) 
    TABLESPACE nym69_space;

CREATE INDEX IF NOT EXISTS idx_stores_city 
    ON stores(city) 
    TABLESPACE sbm10_space;

\echo '[OK] Индексы созданы'
\echo ''

\echo '[*] Создание материализованного представления...'

-- Материализованное представление в nym69_space
CREATE MATERIALIZED VIEW IF NOT EXISTS sales_summary
TABLESPACE nym69_space
AS
SELECT 
    region,
    DATE_TRUNC('month', sale_date) AS month,
    COUNT(*) AS total_sales,
    SUM(price * quantity) AS total_revenue,
    AVG(price * quantity) AS avg_revenue,
    COUNT(DISTINCT customer_name) AS unique_customers
FROM sales
GROUP BY region, DATE_TRUNC('month', sale_date)
WITH DATA;

-- Индекс для материализованного представления
CREATE UNIQUE INDEX IF NOT EXISTS idx_sales_summary_region_month 
    ON sales_summary(region, month)
    TABLESPACE sbm10_space;

\echo '[OK] Материализованное представление sales_summary создано (nym69_space)'
\echo ''

\echo '[*] Создание обычного представления...'

-- Обычное представление для аналитики
CREATE OR REPLACE VIEW sales_analytics AS
SELECT 
    s.sale_date,
    s.product_name,
    s.quantity,
    s.price,
    s.customer_name,
    s.region,
    p.category AS product_category,
    c.city AS customer_city
FROM sales s
LEFT JOIN products p ON s.product_name = p.name
LEFT JOIN customers c ON s.customer_name = c.name;

\echo '[OK] Представление sales_analytics создано'
\echo ''

\echo '======================================'
\echo '  Структура базы данных создана!'
\echo '======================================'
\echo ''
\echo 'Созданные объекты:'
\echo '  [*] Таблицы:'
\echo '     • sales (партицированная)'
\echo '     • sales_2024_q1, q2, q3, q4 (партиции)'
\echo '     • customers (default tablespace)'
\echo '     • products (sbm10_space)'
\echo '     • stores (nym69_space)'
\echo ''
\echo '  [i] Индексы:'
\echo '     • idx_sales_date (nym69_space)'
\echo '     • idx_sales_region (sbm10_space)'
\echo '     • idx_customers_email (sbm10_space)'
\echo '     • idx_customers_city (nym69_space)'
\echo '     • idx_products_category (nym69_space)'
\echo '     • idx_stores_city (sbm10_space)'
\echo ''
\echo '  [*] Представления:'
\echo '     • sales_summary (материализованное, nym69_space)'
\echo '     • sales_analytics (обычное)'
\echo ''
\echo 'Список таблиц:'

\dt+

\echo ''
\echo 'Следующий шаг:'
\echo '  psql -p 9099 -h localhost -U dbuser -d bigbluecity -f scripts/seeds.sql'
\echo ''
