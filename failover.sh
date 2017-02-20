#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

declare resourceGroupName="mysql-RG"
declare mastername="MySQLMaster"
declare slave1name="MySQLSlave1"
declare loadBalancer="mySqlLB"
declare natRuleMaster="natRuleMaster"
declare natRuleSlave1="natRuleSlave1"

az network lb inbound-nat-rule delete -g $resourceGroupName --lb-name $loadBalancer -n $natRuleMaster
az network lb inbound-nat-rule delete -g $resourceGroupName --lb-name $loadBalancer -n $natRuleSlave1

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name  $natRuleSlave1 --protocol tcp \
  --frontend-port 3306 --backend-port 3306 --frontend-ip-name myFrontEndPool

az network lb inbound-nat-rule create --resource-group $resourceGroupName \
  --lb-name $loadBalancer --name $natRuleMaster  --protocol tcp \
  --frontend-port 3307 --backend-port 3306 --frontend-ip-name myFrontEndPool

az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLMasterNic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH1 $natRuleSlave1

az network nic ip-config update --resource-group $resourceGroupName \
   --nic-name MySQLSlave1Nic1 --lb-name $loadBalancer --name ipconfig1 \
   --lb-inbound-nat-rules mySQLSSH2 $natRuleMaster 
