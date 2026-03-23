\set ON_ERROR_STOP on

\echo '=== BEFORE CHANGE ==='
SELECT 'customers' AS table_name, count(*) AS rows FROM customers
UNION ALL
SELECT 'products', count(*) FROM products
UNION ALL
SELECT 'stores', count(*) FROM stores
UNION ALL
SELECT 'sales', count(*) FROM sales
ORDER BY table_name;

INSERT INTO customers (name, email, city) VALUES
('Лаб2 Иван', 'lab2-ivan@example.com', 'Москва'),
('Лаб2 Мария', 'lab2-maria@example.com', 'Казань');

INSERT INTO products (name, category, price) VALUES
('Lab2 SSD', 'Электроника', 9900.00),
('Lab2 Mouse', 'Аксессуары', 1900.00);

INSERT INTO stores (name, city, region) VALUES
('Lab2 Store 1', 'Тверь', 'Центр'),
('Lab2 Store 2', 'Пермь', 'Урал');

INSERT INTO sales (sale_date, product_name, quantity, price, customer_name, region) VALUES
('2024-11-10', 'Lab2 SSD', 1, 9900.00, 'Лаб2 Иван', 'Центр'),
('2024-11-11', 'Lab2 Mouse', 2, 1900.00, 'Лаб2 Мария', 'Урал');

\echo '=== AFTER INSERT ==='
TABLE products;

\echo '=== RECOVERY TARGET TIME ==='
SELECT clock_timestamp() AS recovery_target_time \gset
\echo :recovery_target_time

DELETE FROM products
WHERE id IN (
  SELECT id
  FROM (
    SELECT id, row_number() OVER (ORDER BY id) AS rn
    FROM products
  ) s
  WHERE rn % 2 = 0
);

\echo '=== AFTER DELETE ==='
TABLE products;

\echo '=== FORCE WAL SWITCH ==='
SELECT pg_switch_wal();
