#!/bin/bash
masterhost="$1"
docker rm $(docker ps -a -q) -f
docker run -d \
  -v /datadisks/disk1:/var/lib/mysql \
  --name mysql_slave \
  --net=host \
  -e MASTER_HOST=$masterhost \
  -e MASTER_PORT=3306 \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_USER=my_user \
  -e MYSQL_PASSWORD=my_password \
  torosent/mysql
