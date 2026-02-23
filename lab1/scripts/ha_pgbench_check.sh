createdb -h localhost -p 9099 pgbench_db -U dbuser
pgbench -h localhost -p 9099 -U dbuser -i -s 100 pgbench_db

pgbench -h localhost -p 9099 -U dbuser \
  -c 200 -j 8 -T 600 -M prepared -r -P 1 \
  -S -s 100 -f pgbench_24kb.sql pgbench_db
