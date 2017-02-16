# What is MySQL?

> MySQL is a fast, reliable, scalable, and easy to use open-source relational database system. MySQL Server is intended for mission-critical, heavy-load production systems as well as for embedding into mass-deployed software.

[https://mysql.com/](https://mysql.com/)

# MySQL Replication Cluster Master - Slave

A **zero downtime** MySQL master-slave [replication](https://dev.mysql.com/doc/refman/5.0/en/replication-howto.html) cluster can easily be setup with the Bitnami MySQL Docker image using the following environment variables:

 - `MYSQL_REPLICATION_MODE`: The replication mode. Possible values `master`/`slave`. No defaults.
 - `MYSQL_REPLICATION_USER`: The replication user created on the master on first run. No defaults.
 - `MYSQL_REPLICATION_PASSWORD`: The replication users password. No defaults.
 - `MYSQL_MASTER_HOST`: Hostname/IP of replication master (slave parameter). No defaults.
 - `MYSQL_MASTER_PORT`: Server port of the replication master (slave parameter). Defaults to `3306`.
 - `MYSQL_MASTER_USER`: User on replication master with access to `MYSQL_DATABASE` (slave parameter). Defaults to `root`
 - `MYSQL_MASTER_PASSWORD`: Password of user on replication master with access to `MYSQL_DATABASE` (slave parameter). No defaults.

In a replication cluster you can have one master and zero or more slaves. When replication is enabled the master node is in read-write mode, while the slaves are in read-only mode. For best performance its advisable to limit the reads to the slaves.

# What these scripts are doing?
azurecli.sh will create 2 VM's in Azure with managed disks and a loadbalancer. 
The script will install docker images of MySQL in Master Slave configuration
# How to run 
- `Install Azure CLI 2.0`
- `Edit the parameters in azurecli.sh`
- `bash azurecli.sh`
