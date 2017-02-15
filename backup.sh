#!/bin/bash

docker exec mysql-master /opt/bitnami/mysql/bin/mysqldump -P 3306 -h 127.0.0.1 -u root --password=root_password my_database > backup.sql
