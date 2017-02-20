#!/bin/bash
masterhost="$1"
docker rm $(docker ps -a -q) -f
docker run --name mysql-slave \
   -p 3306:3306 \
   --dns 168.63.129.16 \
   -d \
   -v /datadisks/disk1:/bitnami/mysql \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_REPLICATION_MODE=slave \
  -e MYSQL_REPLICATION_USER=my_repl_user \
  -e MYSQL_REPLICATION_PASSWORD=my_repl_password \
  -e MYSQL_MASTER_HOST=$masterhost \
  -e MYSQL_MASTER_USER=my_user \
  -e MYSQL_MASTER_PASSWORD=my_password \
  -e MYSQL_USER=my_user \
  -e MYSQL_PASSWORD=my_password \
  -e MYSQL_DATABASE=my_database \
  bitnami/mysql:latest
