#!/bin/bash

masterhost="$1"
docker network create app-tier --driver bridge
docker run --name mysql-master \
  --network app-tier \
   -p 3306:3306 \
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
