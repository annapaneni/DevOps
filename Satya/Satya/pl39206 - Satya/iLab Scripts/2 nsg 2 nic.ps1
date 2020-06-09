
$rgName = 'rg-midlandls-enterprise-0011'
$location= 'EastUS2'
$snetname= 'snet-midlandls-enterprise-0011'
$snetAddressPrefix= '10.7.1.0/24'
$vnetname= 'vnet-midlandls-enterprise-0011'
$vnetAddressPrefix= '10.7.0.0/23'

$webServerNic = 'nic-01-web-midlandls-enterprise-0011'
$dbServerNic = 'nic-01-db-midlandls-enterprise-0011'
$appServerNic = 'nic-01-app-midlandls-enterprise-0011'

$nsgName1='nsg-midlandls-enterprise-web'
$nsgName2='nsg-midlandls-enterprise-app'

$webServerVM = "vmwebsrv0011"
$dbServerVM = "vmdbsrv0011"
$appServerVM = "vmappsrv0011"

$webSrvDsk = "websrv001dsk0011"
$dbSrvDsk = "dbsrv001dsk0011"
$appSrvDsk = "appsrv001dsk0011"

$webSrvDskSize = 100
$dbSrvDskSize = 100
$appSrvDskSize = 100

$webServerIPAddress = '10.7.1.6'
$dbServerIPAddress = '10.7.1.7'
$appServerIPAddress = '10.7.1.8'

$adminUserName = "pncpnc123"
$adminPassword = "pncpnc@12345"

function creationSubNet{
    param($name, $addressPrefix)
    $subnet = New-AzVirtualNetworkSubnetConfig -Name $name -AddressPrefix $addressPrefix
    return $subnet
}
function createVNet{
    param($rgName,$name, $addressPrefix, $location, $subnets)
    $vnet = New-AzVirtualNetwork -ResourceGroupName $rgName -Name $name -AddressPrefix $addressPrefix `
            -Location $location -Subnet $subnets
    return $vnet
}
function createSecurityRule{
    param($name, $description, $access, $protocol, $direction, $priority, 
    $sourceAddressPrefix, $sourcePortRange, $destinationAddressPrefix, $destinationPortRange)
    
    $rule = New-AzNetworkSecurityRuleConfig -Name $name -Description $description `
              -Access $access -Protocol $protocol -Direction $direction -Priority $priority `
              -SourceAddressPrefix $sourceAddressPrefix -SourcePortRange $SourcePortRange `
              -DestinationAddressPrefix $destinationAddressPrefix -DestinationPortRange $destinationPortRange
    return $rule
}
function createNetworkSecurityGroup{
    param($rgName, $location, $name, $securityRules)
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rgName -Location $location `
                -Name $name -SecurityRules $securityRules
    return $nsg
}
function createNIC{
    param($rgName, $location, $name, $publicIp, $privateIp, $nsg, $subnet, $beAddPool, $natrule)      
        $nic = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
                -Name $name -PublicIpAddress $publicIp -PrivateIpAddress $privateIp -NetworkSecurityGroup $nsg -Subnet $subnet `
                -LoadBalancerBackendAddressPool $beAddPool -LoadBalancerInboundNatRule $natrule
        
    return $nic
}
function createVMConfiguration{
    param($vmName, $vmSize, $cmpName, $credential, $publisherName, $offer, $skus, $version, $nicId)
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
                  Set-AzVMOperatingSystem -Windows -ComputerName $cmpName -Credential $credential | `
                  Set-AzVMSourceImage -PublisherName $publisherName -Offer $offer `
                  -Skus $skus -Version $version | Add-AzVMNetworkInterface -Id $nicId
    return $vmConfig
}
function createVM{
    param($rgName, $location, $vmConfig)
    $vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
    return $vm
}
function createDataDiskConfig{
    param($location, $creationOption, $diskSize)
    $diskConfig = New-AzDiskConfig `
                    -Location $location `
                    -CreateOption $creationOption `
                    -DiskSizeGB $diskSize
    return $diskConfig
}
function createDataDisk{
    param($rgName, $name, $diskConfig)
    $dataDisk = New-AzDisk `
                -ResourceGroupName $rgName `
                -DiskName $name `
                -Disk $diskConfig
    return $dataDisk
}
function addDataDiskToVM{
    param($vm, $diskName, $createOption, $diskId)
    $vm = Add-AzVMDataDisk `
            -VM $vm `
            -Name $diskName `
            -CreateOption $createOption `
            -ManagedDiskId $diskId `
            -Lun 1
    return $vm
}


    #Connect-AzAccount
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    # Get the resource group.
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if($rg -eq $null){
        # Create a resource group.
        New-AzResourceGroup -Name $rgName -location $location
        Write-Host  "Resource Group is created" $rgName
    }
    else
    {
    Write-Host $rg.ResourceGroupName "Resource Group already exists."
    }

    # Get virtual network.
    $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $rgName -ErrorAction SilentlyContinue

    if($vnet -eq $null ){
        # Create a sub net.
        $subnet = creationSubNet -name $snetname -addressPrefix $snetAddressPrefix
        Write-Host "SubNet is created" $subnet.Name
        # Create a virtual network.
        $vnet = createVNet -rgName $rgName -name $vnetname -addressPrefix $vnetAddressPrefix -location $location -subnets $subnet
        Write-Host "VNet is created" $vnet.Name
    }
    else
    {
    Write-Host $vnet.Name "vnet already exists."
    }
    # Create an NSG rule to allow HTTP traffic in from the Internet to the first subnet.
    
    $rule1 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the first subnet.
    $rule2 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    # Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
    $rule3 = createSecurityRule -name 'Deny-Internet-All' -description "Deny all Internet" -Access Allow -Protocol Tcp -Direction Outbound -Priority 101 `
    -SourceAddressPrefix * -SourcePortRange * ` -DestinationAddressPrefix Internet -DestinationPortRange *

    $securityRules1 = $rule1, $rule2, $rule3
    $securityRules2 = $rule1, $rule2

    # Create a network security group.
    $nsg1 = Get-AzNetworkSecurityGroup -Name $nsgName1 -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    $nsg2 = Get-AzNetworkSecurityGroup -Name $nsgName2 -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nsg1 -eq $null){
        $nsg1 = createNetworkSecurityGroup -rgName $rgName -location $location -name $nsgName1 -securityRules $securityRules1
        Write-Host "Network security group is created" 
         #update virtual network with network security group
        #Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snetname -AddressPrefix $snetAddressPrefix -NetworkSecurityGroup $nsg #-InformationAction SilentlyContinue

        #$vnet | Set-AzVirtualNetwork #-InformationAction SilentlyContinue
     }
     if($nsg2 -eq $null){
        $nsg2 = createNetworkSecurityGroup -rgName $rgName -location $location -name $nsgName2 -securityRules $securityRules2
        Write-Host "Network security group is created" 
         #update virtual network with network security group
        #Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snetname -AddressPrefix $snetAddressPrefix -NetworkSecurityGroup $nsg #-InformationAction SilentlyContinue

        #$vnet | Set-AzVirtualNetwork #-InformationAction SilentlyContinue
     }
     else
    {
    Write-Host $nsg.Name "nsg already exists."
    }
 
    $nicWebSrv = Get-AzNetworkInterface -Name $webServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue 
    if($nicWebSrv -eq $null){
    # Create a NIC for the Web server VM.
    $nicWebSrv = createNIC -rgName $rgName -location $location -name $webServerNic -publicIp $null -privateIp $webServerIPAddress -nsg $nsg1 -subnet $vnet.Subnets[0]
    Write-Host "Network interface for Web server is created"
    }
    $nicAppSrv = Get-AzNetworkInterface -Name $appServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nicAppSrv -eq $null){
    # Create a NIC for the App server VM.
    $nicAppSrv = createNIC -rgName $rgName -location $location -name $appServerNic -publicIp $null -privateIp $appServerIPAddress -nsg $nsg2 -subnet $vnet.Subnets[0]
    Write-Host "Network interfacce for App Server is created"
    }