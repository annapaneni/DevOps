$rgName = 'Midlandls_Core_RG_test2'
$location= 'EastUS2'
$snetname= 'Midlandls_Core_Subnet'
$snetAddressPrefix= '10.3.1.0/24'
$vnetname= 'Midlandls_Core_VNET_Test2'
$vnetAddressPrefix= '10.3.0.0/23'
$nsgName = 'Midlandls_Core_NSG_001'

$webServerNic = 'Midlandls_Core_Web_Nic_01'

$webServerVM = "vmwebsrv001"

$webSrvDsk = "websrvdsk"

$webSrvDskSize = 100

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
function createPublicIpAddress{
    param($rgName, $name, $location, $allocationMethod)
    $publicip = New-AzPublicIpAddress -ResourceGroupName $rgName -Name $name `
                    -location $location -AllocationMethod $allocationMethod
    return $publicip
}
function createNIC{
    param($rgName, $location, $name, $publicIp, $privateIp, $nsg, $subnet, $beAddPool, $natrule)      
        $nic = New-AzNetworkInterface -ResourceGroupName $rgName -Location $location `
                -Name $name -PublicIpAddress $publicIp -PrivateIpAddress $privateIp -NetworkSecurityGroup $nsg -Subnet $subnet
        
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
                    #-CreateOption $creationOption `
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


Try
{
    #Connect-AzAccount
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    # Get the resource group.
    #$rg = Get-AzResourceGroup -Name Midlandls-Core_RG  #$rgName
    $rg = Get-AzResourceGroup -Name $rgName
    if($rg -eq $null ){
        # Create a resource group.
        New-AzResourceGroup -Name $rgName -location $location
        Write-Host "Resource Group is created $rg"
    }
     # Get virtual network.
    $vnet = Get-AzVirtualNetwork -Name $vnetname 
    Write-Host "Vnet: $vnet"     
    if($vnet -eq $null ){
        # Create a sub net.
        $subnet = creationSubNet -name $snetname -addressPrefix $snetAddressPrefix
        Write-Host "SubNet is created $subnet"
        # Create a virtual network.
        $vnet = createVNet -rgName $rgName -name $vnetname -addressPrefix $vnetAddressPrefix -location $location -subnets $subnet
        Write-Host "VNet is created $vnet"
    }
        
    $securityRules = $null

    # Create a network security group.
    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName  
    if($nsg -eq $null){
        $nsg = createNetworkSecurityGroup -rgName $RgName -location $location -name $nsgName -securityRules $securityRules
        Write-Host "Network security group is created $nsg"
         #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snetname `
            -AddressPrefix $snetAddressPrefix -NetworkSecurityGroup $nsg
        $vnet | Set-AzVirtualNetwork
    }
   
     # Create a NIC for the devops server VM.
    $nicWebSrv = Get-AzNetworkInterface -Name $webServerNic -ResourceGroupName $rgName 
    if($nicWebSrv -eq $null){
        $nicWebSrv = createNIC -rgName $rgName -location $location -name $webServerNic -publicIp $null -privateIp 10.3.1.6 -nsg $nsg -subnet $vnet.Subnets[0]

        Write-Host "Network interface for Web server is created $nicWebSrv"
    }
    # Create a Devops Server in the subnet
    $webSrvVM = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM    
    if($webSrvVM -eq $null){
        $password = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ("pncpnc123", $password)
        Write-Host "Niciwebserv id $nicWebSrv.Id"
        $vmConfig = createVMConfiguration -vmName $webServerVM -vmSize 'Standard_DS3_v2' -cmpName $webServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicWebSrv.Id
    
        if($vmConfig -ne $null){
            Write-Host "VM configuration for web Server is created $vmConfig"
            $webSrvVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
            if($webSrvVM -ne $null){
                Write-Host "Web Server is created $webSrvVM"
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize $webSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $webSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM
                #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $webSrvDsk -createOption Attach -diskId $dataDisk.Id
                #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
            }
        }
    }
}
Catch
{
   
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host "Error $_.Exception $ErrorMessage $FailedItem "
    # In case of error if you want to remove the resource group, un-comment below line.
    #Remove-AzureRmResourceGroup $rgName    
}