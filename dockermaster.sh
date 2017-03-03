#!/bin/bash
docker rm $(docker ps -a -q) -f
docker run -d -p 3306:3306 \
  -v /datadisks/disk1:/var/lib/mysql \
  --name mysql_master \
  --dns 168.63.129.16 \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_USER=my_user \
  -e MYSQL_PASSWORD=my_password \
  torosent/mysql
