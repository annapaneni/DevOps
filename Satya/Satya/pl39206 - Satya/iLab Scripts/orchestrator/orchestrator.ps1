$path = $MyInvocation.MyCommand.Path
if (!$path) {
    $path = $psISE.CurrentFile.Fullpath
}
if ($path) {
    $path = Split-Path $path -Parent
}
Import-Module -Name "$path\operations.ps1"
Import-Module -Name "$path\inputs.ps1"
Try
{
    Connect-AzAccount

    # Create user object
    $cred = Get-Credential -Message "Enter a username and password for the virtual machine."

    # Create a resource group.
    New-AzResourceGroup -Name $rgName -Location $location

    # Create a virtual network with a front-end subnet and back-end subnet.
    $subnet1 = creationSubNet -name $subnet1Name -addressPrefix $subnet1AddressPrefix
    $subnet2 = creationSubNet -name $subnet2Name -addressPrefix $subnet2AddressPrefix
    $subnet3 = creationSubNet -name $subnet3Name -addressPrefix $subnet3AddressPrefix 
    $subnets =$subnet1, $subnet2, $subnet3
    $vnet = createVNet -rgName $rgName -name $vnetName -addressPrefix $vnetAddressPrefix -location $location -subnets $subnets


    # Create an NSG rule to allow HTTP traffic in from the Internet to the first subnet.
    $rule1 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the first subnet.
    $rule2 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    $SecurityRules = $rule1, $rule2

    # Create a network security group for the first-end subnet.
    $nsg1 = createNetworkSecurityGroup -rgName $RgName -location $location -name $nsg1Name -securityRules $SecurityRules

    # Associate the first NSG to the first subnet.
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet1Name `
      -AddressPrefix $subnet1AddressPrefix -NetworkSecurityGroup $nsg1

    # Create an NSG rule to allow HTTP traffic in from the Internet to the second subnet.
    $rule1 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the second subnet.
    $rule2 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    $SecurityRules = $rule1, $rule2

    # Create a network security group for the second subnet.
    $nsg2 = createNetworkSecurityGroup -rgName $RgName -location $location -name $nsg2Name -securityRules $SecurityRules

    # Associate the second NSG to the second subnet.
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet2Name `
      -AddressPrefix $subnet2AddressPrefix -NetworkSecurityGroup $nsg2

    # Create an NSG rule to allow SQL traffic from the front-end subnet to the third subnet.
    $rule1 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the third subnet.
    $rule2 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    $SecurityRules = $rule1, $rule2

    # Create a network security group for third subnet.
    $nsg3 = createNetworkSecurityGroup -rgName $RgName -location $location -name  $nsg3Name -securityRules $SecurityRules

    # Associate the third NSG to the third subnet
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnet3Name `
      -AddressPrefix $subnet3AddressPrefix -NetworkSecurityGroup $nsg3

    # Create a public IP address for the web server VM1.
    $publicipvm1 = createPublicIpAddress -rgName $rgName -name $publicIP1Name -location $location -allocationMethod Dynamic

    # Create a NIC for the web server VM1.
    $nic1 = createNIC -rgName $rgName -location $location -name $nic1Name -publicIp $publicipvm1 -nsg $nsg1 -subnet $vnet.Subnets[0]

    # Create a Web Server VM1 in the subnet1
    $vmConfig = createVMConfiguration -vmName $vm1Name  -vmSize 'Standard_DS2' -cmpName $vm1Name -credential $cred -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' -version latest -nicId $nic1.Id

    $vm1 = createVM -rgName $rgName -location $location -vmConfig $vmConfig

    #create datadisk
    $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize 128
    $dataDisk =createDataDisk -rgName $rgName -name $vM1diskName -diskConfig $diskConfig

    $vm = Get-AzVM -ResourceGroupName $rgName -Name $vm1Name
    $vm = addDataDiskToVM -vm $vm -diskName $vM1diskName -createOption Attach -diskId $dataDisk.Id
    Update-AzVM -ResourceGroupName $rgName -VM $vm

    # Create a public IP address for the VM2
    $publicipvm2 = createPublicIpAddress -rgName $rgName -name $publicIP2Name -location $location -allocationMethod Dynamic

    # Create a NIC for the VM2.
    $nic2 = createNIC -rgName $rgName -location $location -name $nic2Name -publicIp $publicipvm2 -nsg $nsg2 -subnet $vnet.Subnets[1]

    # Create a Web Server VM2 in the subnet2
    $vmConfig = createVMConfiguration -vmName $vm2Name -vmSize 'Standard_DS2' -cmpName $vm2Name -credential $cred -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' -version latest -nicId $nic2.Id
    $vm2 = createVM -rgName $rgName -location $location -vmConfig $vmConfig

    #credate datadisk
    $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize 128
    $dataDisk =createDataDisk -rgName $rgName -name $vM2diskName -diskConfig $diskConfig

    $vm = Get-AzVM -ResourceGroupName $rgName -Name MyVm2
    $vm = addDataDiskToVM -vm $vm -diskName $vM2diskName -createOption Attach -diskId $dataDisk.Id
    Update-AzVM -ResourceGroupName $rgName -VM $vm

    # Create a public IP address for the VM3
    $publicipvm3 = createPublicIpAddress -rgName $rgName -name $publicIP3Name -location $location -allocationMethod Dynamic

    # Create a NIC for the VM3.
    $nic3 = createNIC -rgName $rgName -location $location -name $nic3Name -publicIp $publicipvm3 -nsg $nsg3 -subnet $vnet.Subnets[2]

    # Create a Web Server VM3 in the subnet3
    $vmConfig = createVMConfiguration -vmName $vm3Name -vmSize 'Standard_DS2' -cmpName $vm3Name -credential $cred -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' -version latest -nicId $nic3.Id
    $vm3 = createVM -rgName $rgName -location $location -vmConfig $vmConfig

    # create datadisk
    $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize 128
    $dataDisk =createDataDisk -rgName $rgName -name $vM3diskName -diskConfig $diskConfig

    $vm = Get-AzVM -ResourceGroupName $rgName -Name MyVm3
    $vm = addDataDiskToVM -vm $vm -diskName $vM3diskName -createOption Attach -diskId $dataDisk.Id
    Update-AzVM -ResourceGroupName $rgName -VM $vm

}
Catch
{
    Write-Host $_.Exception.Message`n
    Remove-AzResourceGroup -Name $rgName
}