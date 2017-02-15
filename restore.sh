#!/bin/bash

cat backup.sql | docker exec -i mysql-master /opt/bitnami/mysql/bin/mysql -P 3306 -h 127.0.0.1 -u root --password=root_password my_database
