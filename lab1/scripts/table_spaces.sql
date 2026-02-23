-- ============================================
-- Создание табличных пространств
-- Лабораторная работа №1
-- ============================================

\echo '======================================'
\echo '  Создание табличных пространств'
\echo '======================================'
\echo ''

-- Проверка существования директорий
\! echo "[*] Проверка существования директорий..."
\! test -d $HOME/sbm10 && echo "   + $HOME/sbm10 существует" || echo "   - $HOME/sbm10 НЕ существует!"
\! test -d $HOME/nym69 && echo "   + $HOME/nym69 существует" || echo "   - $HOME/nym69 НЕ существует!"
\echo ''

\! echo "[i] Текущий пользователь и HOME:"
\! echo "USER: $USER, HOME: $HOME"
\echo ''

-- ВАЖНО: Для создания табличных пространств используйте ПОЛНЫЕ ПУТИ
-- На сервере postgres0@pg125: /var/db/postgres0/sbm10 и /var/db/postgres0/nym69
-- Локально (для тестирования): замените на ваш путь

-- Создание табличного пространства sbm10_space
\echo '[+] Создание табличного пространства sbm10_space...'
-- ЗАМЕНИТЕ ПУТЬ НИЖЕ НА ВАШ:
-- Для сервера: CREATE TABLESPACE sbm10_space OWNER postgres LOCATION '/var/db/postgres0/sbm10';
-- Для локального тестирования: CREATE TABLESPACE sbm10_space OWNER postgres LOCATION '/your/path/sbm10';

-- CREATE TABLESPACE sbm10_space 
--     OWNER postgres
--     LOCATION '/var/db/postgres0/sbm10';

\echo '[!] ВНИМАНИЕ: Раскомментируйте и исправьте путь в строках выше!'
\echo ''

-- Создание табличного пространства nym69_space
\echo '[+] Создание табличного пространства nym69_space...'
-- ЗАМЕНИТЕ ПУТЬ НИЖЕ НА ВАШ:
-- Для сервера: CREATE TABLESPACE nym69_space OWNER postgres LOCATION '/var/db/postgres0/nym69';

-- CREATE TABLESPACE nym69_space 
--     OWNER postgres
--     LOCATION '/var/db/postgres0/nym69';

\echo '[!] ВНИМАНИЕ: Раскомментируйте и исправьте путь в файле!'
\echo ''

-- Предоставление прав роли dbuser (выполните после создания табличных пространств)
\echo '[*] Предоставление прав на табличные пространства...'
-- GRANT CREATE ON TABLESPACE sbm10_space TO dbuser;
-- GRANT CREATE ON TABLESPACE nym69_space TO dbuser;

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
    pg_catalog.pg_tablespace_location(oid) AS "Расположение"
FROM pg_catalog.pg_tablespace
ORDER BY spcname;

\echo ''
\echo 'Следующий шаг:'
\echo '  psql -p 9099 -h localhost -U dbuser -d bigbluecity -f scripts/create.sql'
\echo ''
