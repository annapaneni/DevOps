$rgName = 'Midlandls-Core_RG'

$webServerNic = 'Midlandls_Core_Web_Nic_01'
$dbServerNic = 'Midlandls_Core_Db_Nic_01'
$appServerNic = 'Midlandls_Core_App_Nic_01'

$webServerVM = "vmwebsrv001"
$dbServerVM = "vmdbsrv001"
$appServerVM = "vmappsrv001"


$webSrvDsk = "websrvdsk"
$dbSrvDsk = "dbsrvdsk"
$appSrvDsk = "appsrvdsk"

az vm deallocate --resource-group $rgName --name $webServerVM
az vm deallocate --resource-group $rgName --name $dbServerVM
az vm deallocate --resource-group $rgName --name $appServerVM

az network nic delete -g $rgName -n $webServerNic
az network nic delete -g $rgName -n $dbbServerNic
az network nic delete -g $rgName -n $appServerNic

az disk delete --name $webSrvDsk --resource-group $rgName
az disk delete --name $dbSrvDsk --resource-group $rgName
az disk delete --name $appSrvDsk --resource-group $rgName

az vm delete --resource-group $rgName --name $webServerVM --yes
az vm delete --resource-group $rgName --name $dbServerVM --yes
az vm delete --resource-group $rgName --name $appServerVM --yes