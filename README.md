# What is MySQL?

> MySQL is a fast, reliable, scalable, and easy to use open-source relational database system. MySQL Server is intended for mission-critical, heavy-load production systems as well as for embedding into mass-deployed software.

[https://mysql.com/](https://mysql.com/)

# MySQL Replication Cluster Master - Slave

A **zero downtime** MySQL master-slave [replication](https://dev.mysql.com/doc/refman/5.0/en/replication-howto.html) cluster can easily be setup with the MySQL Docker image using the following environment variables:

# What these scripts are doing?
azurecli.sh will create 2 VM's in Azure with managed disks and a loadbalancer. 
The script will install docker images of MySQL in Master Slave configuration
# How to run 
- `Install Azure CLI 2.0`
- `Edit the parameters in azurecli.sh`
- `bash azurecli.sh`
