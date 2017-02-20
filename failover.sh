#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

declare resourceGroupName="mysql-RG"
declare mastername="MySQLMaster"
declare slave1name="MySQLSlave1"
declare loadBalancer="mySqlLB"
declare natRuleMaster="natRuleMaster"
declare natRuleSlave1="natRuleSlave1"

az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLMasterNic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH1

az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLSlave1Nic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH2 
   
az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLMasterNic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH1 $natRuleSlave1

az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLSlave1Nic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH2 $natRuleMaster 

az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $slave1name --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/dockermaster.sh"],"commandToExecute": "./dockermaster.sh"}'

az vm extension set -n CustomScript --publisher Microsoft.Azure.Extensions \
	--version 2.0 --vm-name $mastername --resource-group $resourceGroupName \
	--settings '{"fileUris": ["https://raw.githubusercontent.com/torosent/mysql-replication/master/dockerslave.sh"],"commandToExecute": "./dockerslave.sh '$slave1name'" }'
