#!/bin/bash
masterhost="$1"
apt-get update
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
apt-get update
apt-cache policy docker-engine
apt-get install -y docker-engine
docker run --name mysql-slave --link mysql-master:master \
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
