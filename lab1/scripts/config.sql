-- ============================================
-- Конфигурация базы данных и ролей
-- Лабораторная работа №1
-- ============================================

\echo '======================================'
\echo '  Конфигурация базы данных и ролей'
\echo '======================================'
\echo ''

-- Создание базы данных на основе template0
\echo '[*] Создание базы данных bigbluecity...'
CREATE DATABASE bigbluecity 
    WITH TEMPLATE = template0
    ENCODING = 'UTF8'
    LC_COLLATE = 'ru_RU.UTF-8'
    LC_CTYPE = 'ru_RU.UTF-8'
    OWNER = postgres;

\echo '[OK] База данных bigbluecity создана'
\echo ''

-- Создание новой роли
\echo '👤 Создание роли dbuser...'
CREATE ROLE dbuser WITH 
    LOGIN 
    PASSWORD 'secure_password_123'
    VALID UNTIL 'infinity';

\echo '[OK] Роль dbuser создана'
\echo ''

-- Предоставление прав на базу данных
\echo '🔐 Предоставление прав на базу данных...'
GRANT CONNECT ON DATABASE bigbluecity TO dbuser;
GRANT CONNECT ON DATABASE postgres TO dbuser;

\echo '[OK] Права предоставлены'
\echo ''

-- Подключение к базе bigbluecity для настройки схемы
\connect bigbluecity

\echo '📝 Настройка схемы public...'
GRANT USAGE ON SCHEMA public TO dbuser;
GRANT CREATE ON SCHEMA public TO dbuser;
GRANT ALL PRIVILEGES ON SCHEMA public TO dbuser;

\echo '[OK] Права на схему предоставлены'
\echo ''

-- Установка search_path по умолчанию для роли
ALTER ROLE dbuser SET search_path TO public;

\echo '======================================'
\echo '  Конфигурация завершена!'
\echo '======================================'
\echo ''
\echo 'Созданные объекты:'
\echo '  • База данных: bigbluecity'
\echo '  • Роль: dbuser'
\echo '  • Пароль: secure_password_123'
\echo ''
\echo 'Проверка созданных объектов...'
\echo ''

-- Список баз данных
\echo '[*] Базы данных:'
\l bigbluecity

\echo ''
\echo '[*] Роли:'
\du dbuser

\echo ''
\echo 'Следующий шаг:'
\echo '  psql -p 9099 -d postgres -f scripts/table_spaces.sql'
\echo ''
