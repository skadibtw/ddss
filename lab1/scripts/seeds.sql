-- ============================================
-- Наполнение базы данных тестовыми данными
-- Лабораторная работа №1
-- Выполнять от имени роли dbuser
-- ============================================

\echo '======================================'
\echo '  Наполнение базы данных'
\echo '======================================'
\echo ''

-- Подключение к базе bigbluecity
\connect bigbluecity

-- Начало транзакции
BEGIN;

\echo '[*] Наполнение таблицы customers...'

INSERT INTO customers (name, email, phone, city, registration_date) VALUES
    ('Иван Иванов', 'ivan.ivanov@example.com', '+7-900-111-2233', 'Москва', '2023-01-15'),
    ('Мария Петрова', 'maria.petrova@example.com', '+7-900-222-3344', 'Санкт-Петербург', '2023-02-20'),
    ('Алексей Сидоров', 'alexey.sidorov@example.com', '+7-900-333-4455', 'Новосибирск', '2023-03-10'),
    ('Елена Смирнова', 'elena.smirnova@example.com', '+7-900-444-5566', 'Екатеринбург', '2023-04-05'),
    ('Дмитрий Кузнецов', 'dmitry.kuznetsov@example.com', '+7-900-555-6677', 'Казань', '2023-05-12'),
    ('Ольга Волкова', 'olga.volkova@example.com', '+7-900-666-7788', 'Москва', '2023-06-18'),
    ('Сергей Морозов', 'sergey.morozov@example.com', '+7-900-777-8899', 'Самара', '2023-07-22'),
    ('Наталья Новикова', 'natalia.novikova@example.com', '+7-900-888-9900', 'Омск', '2023-08-30'),
    ('Андрей Козлов', 'andrey.kozlov@example.com', '+7-900-999-0011', 'Челябинск', '2023-09-14'),
    ('Татьяна Павлова', 'tatiana.pavlova@example.com', '+7-901-111-2222', 'Ростов-на-Дону', '2023-10-25'),
    ('Владимир Семенов', 'vladimir.semenov@example.com', '+7-901-222-3333', 'Уфа', '2023-11-08'),
    ('Юлия Федорова', 'yulia.fedorova@example.com', '+7-901-333-4444', 'Воронеж', '2023-12-19');

\echo '[OK] Добавлено клиентов:' 
SELECT COUNT(*) FROM customers;
\echo ''

\echo '[+] Наполнение таблицы products...'

INSERT INTO products (name, description, category, price, stock) VALUES
    ('Ноутбук Dell XPS 15', 'Профессиональный ноутбук для работы', 'Электроника', 125000.00, 15),
    ('Ноутбук HP Pavilion', 'Универсальный ноутбук для дома и офиса', 'Электроника', 75000.00, 25),
    ('Смартфон Samsung Galaxy S24', 'Флагманский смартфон', 'Электроника', 89000.00, 30),
    ('Смартфон iPhone 15', 'Смартфон Apple последнего поколения', 'Электроника', 115000.00, 20),
    ('Планшет iPad Pro', 'Профессиональный планшет', 'Электроника', 95000.00, 12),
    ('Наушники Sony WH-1000XM5', 'Беспроводные наушники с шумоподавлением', 'Аксессуары', 35000.00, 40),
    ('Клавиатура Logitech MX Keys', 'Беспроводная клавиатура для работы', 'Аксессуары', 12000.00, 50),
    ('Мышь Logitech MX Master 3', 'Эргономичная беспроводная мышь', 'Аксессуары', 8500.00, 60),
    ('Монитор LG UltraWide', 'Широкоформатный монитор 34"', 'Электроника', 55000.00, 18),
    ('Веб-камера Logitech Brio', 'Камера 4K для видеоконференций', 'Аксессуары', 18000.00, 35),
    ('Книга "PostgreSQL. Основы языка SQL"', 'Учебник по PostgreSQL', 'Книги', 2500.00, 100),
    ('Книга "Высоконагруженные приложения"', 'Проектирование надежных систем', 'Книги', 3200.00, 80),
    ('SSD диск Samsung 1TB', 'Твердотельный накопитель', 'Электроника', 9500.00, 45),
    ('Внешний HDD 2TB', 'Портативный жесткий диск', 'Электроника', 6800.00, 55),
    ('USB-C Hub', 'Многопортовый адаптер', 'Аксессуары', 4500.00, 70);

\echo '[OK] Добавлено товаров:' 
SELECT COUNT(*) FROM products;
\echo ''

\echo '[*] Наполнение таблицы stores...'

INSERT INTO stores (name, address, city, region, opened_date, manager) VALUES
    ('Магазин "Электроника на Невском"', 'Невский проспект, 100', 'Санкт-Петербург', 'Север', '2020-01-15', 'Петров П.П.'),
    ('Магазин "Техно-Центр Москва"', 'Тверская улица, 25', 'Москва', 'Центр', '2019-05-20', 'Иванова И.И.'),
    ('Магазин "Цифровой мир"', 'Ленина проспект, 50', 'Новосибирск', 'Восток', '2021-03-10', 'Сидоров С.С.'),
    ('Магазин "Гаджеты и Книги"', 'Малышева улица, 30', 'Екатеринбург', 'Восток', '2020-11-05', 'Смирнова Е.А.'),
    ('Магазин "IT Store Казань"', 'Баумана улица, 15', 'Казань', 'Центр', '2022-02-14', 'Кузнецов Д.В.');

\echo '[OK] Добавлено магазинов:' 
SELECT COUNT(*) FROM stores;
\echo ''

\echo '[*] Генерация продаж (это займет некоторое время)...'

-- Генерация продаж для распределения по партициям
INSERT INTO sales (sale_date, product_name, quantity, price, customer_name, region)
SELECT 
    -- Дата в течение 2024 года
    DATE '2024-01-01' + (random() * 364)::integer AS sale_date,
    
    -- Случайный товар из списка
    CASE (random() * 14)::integer
        WHEN 0 THEN 'Ноутбук Dell XPS 15'
        WHEN 1 THEN 'Ноутбук HP Pavilion'
        WHEN 2 THEN 'Смартфон Samsung Galaxy S24'
        WHEN 3 THEN 'Смартфон iPhone 15'
        WHEN 4 THEN 'Планшет iPad Pro'
        WHEN 5 THEN 'Наушники Sony WH-1000XM5'
        WHEN 6 THEN 'Клавиатура Logitech MX Keys'
        WHEN 7 THEN 'Мышь Logitech MX Master 3'
        WHEN 8 THEN 'Монитор LG UltraWide'
        WHEN 9 THEN 'Веб-камера Logitech Brio'
        WHEN 10 THEN 'Книга "PostgreSQL. Основы языка SQL"'
        WHEN 11 THEN 'SSD диск Samsung 1TB'
        WHEN 12 THEN 'Внешний HDD 2TB'
        ELSE 'USB-C Hub'
    END AS product_name,
    
    -- Количество от 1 до 5
    (random() * 4 + 1)::integer AS quantity,
    
    -- Цена с небольшой вариацией
    (random() * 20000 + 5000)::numeric(10,2) AS price,
    
    -- Случайное имя клиента
    CASE (random() * 11)::integer
        WHEN 0 THEN 'Иван Иванов'
        WHEN 1 THEN 'Мария Петрова'
        WHEN 2 THEN 'Алексей Сидоров'
        WHEN 3 THEN 'Елена Смирнова'
        WHEN 4 THEN 'Дмитрий Кузнецов'
        WHEN 5 THEN 'Ольга Волкова'
        WHEN 6 THEN 'Сергей Морозов'
        WHEN 7 THEN 'Наталья Новикова'
        WHEN 8 THEN 'Андрей Козлов'
        WHEN 9 THEN 'Татьяна Павлова'
        WHEN 10 THEN 'Владимир Семенов'
        ELSE 'Юлия Федорова'
    END AS customer_name,
    
    -- Регион
    CASE (random() * 3)::integer
        WHEN 0 THEN 'Север'
        WHEN 1 THEN 'Юг'
        WHEN 2 THEN 'Восток'
        ELSE 'Запад'
    END AS region
FROM generate_series(1, 10000);

\echo '[OK] Добавлено продаж:' 
SELECT COUNT(*) FROM sales;
\echo ''

\echo '[*] Обновление материализованного представления...'
REFRESH MATERIALIZED VIEW sales_summary;
\echo '[OK] Представление обновлено'
\echo ''

-- Фиксация транзакции
COMMIT;

\echo '======================================'
\echo '  Наполнение завершено!'
\echo '======================================'
\echo ''
\echo '[*] Статистика данных:'
\echo ''

SELECT 
    'customers' AS "Таблица",
    COUNT(*) AS "Количество записей"
FROM customers
UNION ALL
SELECT 
    'products' AS "Таблица",
    COUNT(*) AS "Количество записей"
FROM products
UNION ALL
SELECT 
    'stores' AS "Таблица",
    COUNT(*) AS "Количество записей"
FROM stores
UNION ALL
SELECT 
    'sales' AS "Таблица",
    COUNT(*) AS "Количество записей"
FROM sales
ORDER BY "Таблица";

\echo ''
\echo '[*] Распределение продаж по партициям:'
\echo ''

SELECT 
    'sales_2024_q1' AS "Партиция",
    COUNT(*) AS "Записей",
    MIN(sale_date) AS "С даты",
    MAX(sale_date) AS "По дату"
FROM sales_2024_q1
UNION ALL
SELECT 
    'sales_2024_q2' AS "Партиция",
    COUNT(*) AS "Записей",
    MIN(sale_date) AS "С даты",
    MAX(sale_date) AS "По дату"
FROM sales_2024_q2
UNION ALL
SELECT 
    'sales_2024_q3' AS "Партиция",
    COUNT(*) AS "Записей",
    MIN(sale_date) AS "С даты",
    MAX(sale_date) AS "По дату"
FROM sales_2024_q3
UNION ALL
SELECT 
    'sales_2024_q4' AS "Партиция",
    COUNT(*) AS "Записей",
    MIN(sale_date) AS "С даты",
    MAX(sale_date) AS "По дату"
FROM sales_2024_q4
ORDER BY "Партиция";

\echo ''
\echo '[*] Топ-5 регионов по выручке:'
\echo ''

SELECT 
    region AS "Регион",
    COUNT(*) AS "Продаж",
    SUM(price * quantity) AS "Выручка",
    ROUND(AVG(price * quantity), 2) AS "Средний чек"
FROM sales
GROUP BY region
ORDER BY SUM(price * quantity) DESC
LIMIT 5;

\echo ''
\echo 'База данных готова к использованию!'
\echo ''
