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

# Initialize parameters specified from command line
while getopts ":i:g:n:l:" arg; do
	case "${arg}" in
		i)
			subscriptionId=${OPTARG}
			;;
		g)
			resourceGroupName=${OPTARG}
			;;
		n)
			deploymentName=${OPTARG}
			;;
		l)
			resourceGroupLocation=${OPTARG}
			;;
		esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$subscriptionId" ]]; then
	echo "Subscription Id:"
	read subscriptionId
	[[ "${subscriptionId:?}" ]]
fi

if [[ -z "$resourceGroupName" ]]; then
	echo "ResourceGroupName:"
	read resourceGroupName
	[[ "${resourceGroupName:?}" ]]
fi

if [[ -z "$deploymentName" ]]; then
	echo "DeploymentName:"
	read deploymentName
fi

if [[ -z "$resourceGroupLocation" ]]; then
	echo "Enter a location below to create a new resource group else skip this"
	echo "ResourceGroupLocation:"
	read resourceGroupLocation
fi

if [ -z "$subscriptionId" ] || [ -z "$resourceGroupName" ] || [ -z "$deploymentName" ]; then
	echo "Either one of subscriptionId, resourceGroupName, deploymentName is empty"
	usage
fi

#login to azure using your credentials
az account show 1> /dev/null

if [ $? != 0 ];
then
	az login
fi

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
  --name myLoadBalancer --public-ip-address myPublicIP \
  --frontend-ip-name myFrontEndPool --backend-pool-name myBackEndPool
  
az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name myLoadBalancer --name myLoadBalancerRuleSSH1 --protocol tcp \
  --frontend-port 4222 --backend-port 22 --frontend-ip-name myFrontEndPool

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name myLoadBalancer --name myLoadBalancerRuleMySQL1 --protocol tcp \
  --frontend-port 3306 --backend-port 3306 --frontend-ip-name myFrontEndPool
  
az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name myLoadBalancer --name myLoadBalancerRuleSSH2 --protocol tcp \
  --frontend-port 4223 --backend-port 22 --frontend-ip-name myFrontEndPool

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name myLoadBalancer --name myLoadBalancerRuleMySQL2 --protocol tcp \
  --frontend-port 3307 --backend-port 3306 --frontend-ip-name myFrontEndPool
  
az network nic create --resource-group  $resourceGroupName --location $resourceGroupLocation --name MySQLMasterNic1 \
  --vnet-name myVnet --subnet mySubnet \
  --lb-name myLoadBalancer --lb-address-pools myBackEndPool \
  --public-ip-address "" \
  --lb-inbound-nat-rules myLoadBalancerRuleSSH1 myLoadBalancerRuleMySQL1

az network nic create --resource-group  $resourceGroupName --location $resourceGroupLocation --name MySQLSlave1Nic1 \
  --vnet-name myVnet --subnet mySubnet \
  --lb-name myLoadBalancer --lb-address-pools myBackEndPool \
  --public-ip-address "" \
  --lb-inbound-nat-rules myLoadBalancerRuleSSH2 myLoadBalancerRuleMySQL2
  
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
	
az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $slave1name --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/dockermaster.sh"],"commandToExecute": "./dockerslave.sh '$mastername'" }'
	
)