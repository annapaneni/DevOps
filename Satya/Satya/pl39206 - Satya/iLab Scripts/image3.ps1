$adminUserName = "pncpnc123"
$adminPassword = "pncpnc@12345"

$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)

$vnet = Get-AzVirtualNetwork -Name 'Midlandls_Core_VNET' -ResourceGroupName 'Midlandls-Core_RG'
$SubnetConfig = Get-AzVirtualNetworkSubnetConfig -Name 'Midlandls_Core_Subnet' -VirtualNetwork $vnet #'Midlandls_Core_VNET'

# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $vnet

$IpConfigName1 = "IPConfig-1"
$IpConfig1     = New-AzNetworkInterfaceIpConfig `
  -Name $IpConfigName1 `
  -Subnet $Subnet `
  -PrivateIpAddress '10.1.1.9' `
  -Primary

$NIC = New-AzNetworkInterface `
  -Name 'Midlandls_Core_Web_Nic_02' `
  -ResourceGroupName 'Midlandls-Core_RG' `
  -Location 'EastUS2' `
  -IpConfiguration $IpConfig1
Write-Host $NIC.Name

New-AzVm `
    -ResourceGroupName "Midlandls-Core_RG" `
    -Name "vmweb002" `
	-ImageName "WebServerImage" `
    -Location "EastUS2" `
    -VirtualNetworkName "Midlandls_Core_VNET" `
    -SubnetName "Midlandls_Core_Subnet" `
    -SecurityGroupName "Midlandls_Core_NSG_001" `
    -Credential $cred `
    -Size 'Standard_DS3_v2' | Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id