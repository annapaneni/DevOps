$RgName = "Midlandls-Core_RG"
$Location = "EastUS2"
$snetname= 'Midlandls_Core_Subnet'
$snetAddressPrefix= '10.1.1.0/24'
$vnetname= 'Midlandls_Core_VNET'
$vnetAddressPrefix= '10.1.0.0/23'
$webServerNic = 'Midlandls_Core_Web_Nic_03'
$webServerIPAddress = '10.1.1.8'
$webServerVM = "vmwebsrv003"
$adminUserName = "pncpnc123"
$adminPassword = "pncpnc@12345"
$vmImageName = 'WebServerImage'

$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)


Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

New-AzResourceGroup -Name $RgName -Location $Location
Write-Host $RgName
# Create a subnet configuration
$SubnetConfig = New-AzVirtualNetworkSubnetConfig `
-Name $snetname `
-AddressPrefix $snetAddressPrefix
Write-Host $SubnetConfig.Name
# Create a virtual network
$VNet = New-AzVirtualNetwork `
-ResourceGroupName $RgName `
-Location $Location `
-Name $vnetname `
-AddressPrefix $vnetAddressPrefix `
-Subnet $subnetConfig
Write-Host $VNet.Name
# Get the subnet object for use in a later step.
$Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetConfig.Name -VirtualNetwork $VNet
Write-Host $Subnet.Name
$IpConfigName1 = "IPConfig-1"
$IpConfig1     = New-AzNetworkInterfaceIpConfig `
  -Name $IpConfigName1 `
  -Subnet $Subnet `
  -PrivateIpAddress $webServerIPAddress `
  -Primary

$NIC = New-AzNetworkInterface `
  -Name $webServerNic `
  -ResourceGroupName $RgName `
  -Location $Location `
  -IpConfiguration $IpConfig1
Write-Host $NIC.Name
$VirtualMachine = New-AzVMConfig -VMName $webServerVM -VMSize "Standard_DS3_v2"
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $webServerVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine  -id "/subscriptions/ec2027c3-4206-4cef-be4e-833cc78517f0/resourceGroups/Midlandls-Core_RG/providers/Microsoft.Compute/images/WebServerImage"
#$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest
Write-Host $VirtualMachine.Name
New-AzVM -ResourceGroupName $RgName -Location $Location -VM $VirtualMachine -Verbose