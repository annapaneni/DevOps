
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

<#
Stop-AzVM -ResourceGroupName $rgName -Name $webServerVM
Stop-AzVM -ResourceGroupName $rgName -Name $dbServerVM
Stop-AzVM -ResourceGroupName $rgName -Name $appServerVM
#>

Remove-AzNetworkInterface -Name $webServerNic -ResourceGroupName $rgName -Force
Remove-AzNetworkInterface -Name $appServerNic -ResourceGroupName $rgName -Force
Remove-AzNetworkInterface -Name $dbServerNic -ResourceGroupName $rgName -Force

Remove-AzDisk -ResourceGroupName $rgName -DiskName $webSrvDsk -Force
Remove-AzDisk -ResourceGroupName $rgName -DiskName $dbSrvDsk -Force
Remove-AzDisk -ResourceGroupName $rgName -DiskName $appSrvDsk -Force

Remove-AzVM -ResourceGroupName $rgName -Name $webServerVM
Remove-AzVM -ResourceGroupName $rgName -Name $dbServerVM
Remove-AzVM -ResourceGroupName $rgName -Name $appServerVM
