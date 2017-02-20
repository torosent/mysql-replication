#!/bin/bash
docker rm $(docker ps -a -q) -f
docker run --name mysql-master \
   -v /datadisks/disk1:/bitnami/mysql \
   -p 3306:3306 \
   -d \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_REPLICATION_MODE=master \
  -e MYSQL_REPLICATION_USER=my_repl_user \
  -e MYSQL_REPLICATION_PASSWORD=my_repl_password \
  -e MYSQL_USER=my_user \
  -e MYSQL_PASSWORD=my_password \
  -e MYSQL_DATABASE=my_database \
  bitnami/mysql:latest
