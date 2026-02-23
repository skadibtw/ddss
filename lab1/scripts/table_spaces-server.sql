-- ============================================
-- Создание табличных пространств
-- Лабораторная работа №1
-- ВЕРСИЯ ДЛЯ СЕРВЕРА postgres0@pg125
-- ============================================

\echo '======================================'
\echo '  Создание табличных пространств'
\echo '  Сервер: postgres0@pg125'
\echo '======================================'
\echo ''

-- Проверка существования директорий
\! echo "[*] Проверка существования директорий..."
\! test -d /var/db/postgres0/sbm10 && echo "   + /var/db/postgres0/sbm10 существует" || echo "   - /var/db/postgres0/sbm10 НЕ существует!"
\! test -d /var/db/postgres0/nym69 && echo "   + /var/db/postgres0/nym69 существует" || echo "   - /var/db/postgres0/nym69 НЕ существует!"
\echo ''

\! echo "[i] Информация о путях:"
\! echo "USER: $USER, HOME: $HOME"
\! ls -ld /var/db/postgres0/sbm10 /var/db/postgres0/nym69 2>/dev/null || echo "Директории не найдены!"
\echo ''

-- Создание табличного пространства sbm10_space
\echo '[+] Создание табличного пространства sbm10_space...'
CREATE TABLESPACE sbm10_space 
    OWNER postgres
    LOCATION '/var/db/postgres0/sbm10';

\echo '[OK] Табличное пространство sbm10_space создано'
\echo ''

-- Создание табличного пространства nym69_space
\echo '[+] Создание табличного пространства nym69_space...'
CREATE TABLESPACE nym69_space 
    OWNER postgres
    LOCATION '/var/db/postgres0/nym69';

\echo '[OK] Табличное пространство nym69_space создано'
\echo ''

-- Предоставление прав роли dbuser
\echo '[*] Предоставление прав на табличные пространства...'
GRANT CREATE ON TABLESPACE sbm10_space TO dbuser;
GRANT CREATE ON TABLESPACE nym69_space TO dbuser;

\echo '[OK] Права предоставлены'
\echo ''

-- Вывод списка табличных пространств
\echo '======================================'
\echo '  Созданные табличные пространства'
\echo '======================================'
\echo ''

SELECT 
    spcname AS "Имя",
    pg_catalog.pg_get_userbyid(spcowner) AS "Владелец",
    pg_catalog.pg_tablespace_location(oid) AS "Расположение",
    pg_size_pretty(pg_tablespace_size(spcname)) AS "Размер"
FROM pg_catalog.pg_tablespace
WHERE spcname IN ('sbm10_space', 'nym69_space')
ORDER BY spcname;

\echo ''
\echo 'Следующий шаг:'
\echo '  PGPASSWORD="secure_password_123" psql -p 9099 -h localhost -U dbuser -d bigbluecity -f scripts/create.sql'
\echo ''
