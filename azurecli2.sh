#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

usage() { echo "Usage: $0 -i <subscriptionId> -g <resourceGroupName> -n <deploymentName> -l <resourceGroupLocation>" 1>&2; exit 1; }

declare subscriptionId=""
declare adminpassword=""
declare resourceGroupName="mysql-RG"
declare deploymentName="mysqlreplication"
declare resourceGroupLocation="westeurope"
declare adminuser="azureuser"
declare vmsize="Standard_DS2_V2"
declare disksize=1000
declare vnetprefix=192.168.0.0/16
declare subnetprefix=192.168.1.0/24
declare mastername="MySQLMaster"
declare slave1name="MySQLSlave1"
declare loadBalancer="mySqlLB"
declare natRuleMaster="natRuleMaster"
declare natRuleSlave1="natRuleSlave1"

#set the default subscription id
az account set --subscription $subscriptionId

set +e

#Check for existing RG
az group show --name $resourceGroupName 1> /dev/null

if [ $? != 0 ]; then
	echo "Resource group with name" $resourceGroupName "could not be found. Creating new resource group.."
	set -e
	(
		set -x
		az group create --name $resourceGroupName --location $resourceGroupLocation
	)
	else
	echo "Using existing resource group..."
fi

#Start deployment
echo "Starting deployment..."
(

az network vnet create --resource-group $resourceGroupName --location $resourceGroupLocation --name myVnet \
  --address-prefix $vnetprefix  --subnet-name mySubnet --subnet-prefix $subnetprefix
  
az vm availability-set create --resource-group $resourceGroupName --location $resourceGroupLocation --name mySqlAvailabilitySet --platform-fault-domain-count 3
  
az network lb create --resource-group $resourceGroupName --location $resourceGroupLocation \
  --name $loadBalancer --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool
  
az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name mySQLSSH1 --protocol tcp \
  --frontend-port 4222 --backend-port 22 --frontend-ip-name myFrontEndPool

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name $natRuleMaster --protocol tcp \
  --frontend-port 3306 --backend-port 3306 --frontend-ip-name myFrontEndPool
  
az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name mySQLSSH2 --protocol tcp \
  --frontend-port 4223 --backend-port 22 --frontend-ip-name myFrontEndPool

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name $natRuleSlave1 --protocol tcp \
  --frontend-port 3307 --backend-port 3306 --frontend-ip-name myFrontEndPool
  
az network nic create --resource-group  $resourceGroupName --location $resourceGroupLocation --name MySQLMasterNic1 \
  --vnet-name myVnet --subnet mySubnet \
  --lb-name $loadBalancer --lb-address-pools myBackEndPool \
  --public-ip-address "" \
  --lb-inbound-nat-rules mySQLSSH1 $natRuleMaster

az network nic create --resource-group  $resourceGroupName --location $resourceGroupLocation --name MySQLSlave1Nic1 \
  --vnet-name myVnet --subnet mySubnet \
  --lb-name $loadBalancer --lb-address-pools myBackEndPool \
  --public-ip-address "" \
  --lb-inbound-nat-rules mySQLSSH2 $natRuleSlave1
  
az vm create \
    --resource-group $resourceGroupName \
    --name $mastername \
    --location $resourceGroupLocation \
    --availability-set mySqlAvailabilitySet \
    --nics MySQLMasterNic1 \
    --image canonical:ubuntuserver:16.04.0-LTS:16.04.201611150 \
	--data-disk-sizes-gb $disksize \
	--size $vmsize \
	--public-ip-address "" \
    --admin-password $adminpassword \
	--authentication-type password \
	--storage-sku Premium_LRS \
    --admin-username $adminuser

az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $mastername --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/initattacheddisk.sh"],"commandToExecute": "./initattacheddisk.sh"}'

az vm extension set -n DockerExtension --publisher Microsoft.Azure.Extensions \
   --vm-name $mastername --resource-group $resourceGroupName \
   --settings '{"docker":{"options": ["--dns=168.63.129.16"]}}'
   
az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $mastername --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/dockermaster.sh"],"commandToExecute": "./dockermaster.sh"}'

az vm create \
    --resource-group $resourceGroupName \
    --name $slave1name \
    --location $resourceGroupLocation \
    --availability-set mySqlAvailabilitySet \
    --nics MySQLSlave1Nic1 \
    --image canonical:ubuntuserver:16.04.0-LTS:16.04.201611150 \
	--data-disk-sizes-gb $disksize \
	--size $vmsize \
	--public-ip-address "" \
    --admin-password $adminpassword \
	--authentication-type password \
	--storage-sku Premium_LRS \
    --admin-username $adminuser
	
az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $slave1name --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/initattacheddisk.sh"],"commandToExecute": "./initattacheddisk.sh"}'

az vm extension set -n DockerExtension --publisher Microsoft.Azure.Extensions \
   --vm-name $slave1name --resource-group $resourceGroupName \
   --settings '{"docker":{"options": ["--dns=168.63.129.16"]}}'
   
az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $slave1name --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/dockerslave.sh"],"commandToExecute": "./dockerslave.sh '$mastername'" }'
	
)
