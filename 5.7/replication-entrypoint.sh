#!/bin/bash
set -eo pipefail

cat > /etc/mysql/mysql.conf.d/repl.cnf << EOF
[mysqld]
log-bin=mysql-bin
relay-log=mysql-relay
#bind-address=0.0.0.0
#skip-name-resolve
port = 3306
binlog_cache_size=32768
binlog_cache_size=MIXED
binlog_cache_size=InnoDB
explicit_defaults_for_timestamp=1
gtid-mode=OFF
innodb_buffer_pool_size=4500000000
innodb_flush_method=O_DIRECT
innodb_log_buffer_size=8388608
innodb_log_file_size=134217728
key_buffer_size=16777216	
local_infile=TABLE
log_slave_updates=1
log_statements_unsafe_for_binlog=0
max_binlog_size=134217728
max_connections=470
performance_schema=0
read_buffer_size = 262144
read_rnd_buffer_size = 524288
relay_log_recovery=1
relay_log_info_repository=TABLE
sync_binlog=1
table_open_cache_instances=16
thread_stack=262144

EOF

# If there is a linked master use linked container information
if [ -n "$MASTER_PORT_3306_TCP_ADDR" ]; then
  export MASTER_HOST=$MASTER_PORT_3306_TCP_ADDR
  export MASTER_PORT=$MASTER_PORT_3306_TCP_PORT
fi

if [ -z "$MASTER_HOST" ]; then
  export SERVER_ID=1
  cat >/docker-entrypoint-initdb.d/init-master.sh  <<'EOF'
#!/bin/bash

echo Creating replication user ...
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "\
  GRANT \
    FILE, \
    SELECT, \
    SHOW VIEW, \
    LOCK TABLES, \
    RELOAD, \
    REPLICATION SLAVE, \
    REPLICATION CLIENT \
  ON *.* \
  TO '$REPLICATION_USER'@'%' \
  IDENTIFIED BY '$REPLICATION_PASSWORD'; \
  FLUSH PRIVILEGES; \
"
EOF
else
  # TODO: make server-id discoverable
  export SERVER_ID=2
  cp -v /init-slave.sh /docker-entrypoint-initdb.d/
  cat > /etc/mysql/mysql.conf.d/repl-slave.cnf << EOF
[mysqld]
log-slave-updates
master-info-repository=TABLE
relay-log-info-repository=TABLE
relay-log-recovery=1
read-only=1
EOF
fi

cat > /etc/mysql/mysql.conf.d/server-id.cnf << EOF
[mysqld]
server-id=$SERVER_ID
EOF

exec docker-entrypoint.sh "$@"

