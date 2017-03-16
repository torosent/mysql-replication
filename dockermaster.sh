#!/bin/bash
docker rm $(docker ps -a -q) -f
docker run -d \
  -v /datadisks/disk1/db:/var/lib/mysql \
  --name mysql_master \
  --net=host \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -e MYSQL_USER=my_user \
  -e MYSQL_PASSWORD=my_password \
  torosent/mysql
