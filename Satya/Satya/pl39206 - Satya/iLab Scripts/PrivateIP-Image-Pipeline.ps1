$rgName = 'Midlandls-Core_RG'
$location= 'EastUS2'
$snetname= 'Midlandls_Core_Subnet'
$snetAddressPrefix= '10.1.1.0/24'
$vnetname= 'Midlandls_Core_VNET'
$vnetAddressPrefix= '10.1.0.0/23'
$feIpCnfgName= 'Midlandls_Core_Lb_Frontend_Ip'
$privateIp= '10.1.1.5'
$beAddressPoolName= 'Midlandls_Core_Lb_Backend_Addresspool'
$healthProbeName= 'HealthProbe'
$requestPath ='/'
$protocol= 'http'
$healthProbePort= 80
$healthProbeInterval= 15
$probeCount= 2
$lbruleName= 'HTTP'
$frontEndPort= 80
$backEndPort= 80
$lbName= 'Midlandls_Core_lb_001'
$nsgName = 'Midlandls_Core_NSG_001'

$webServerNic = 'Midlandls_Core_Web_Nic_01'
$dbServerNic = 'Midlandls_Core_Db_Nic_01'
$appServerNic = 'Midlandls_Core_App_Nic_01'

$availabilitySet = "Midlandls_Core_Avail"

$webServerVM = "vmwebsrv001"
$dbServerVM = "vmdbsrv001"
$appServerVM = "vmappsrv001"


$webSrvDsk = "websrvdsk"
$dbSrvDsk = "dbsrvdsk"
$appSrvDsk = "appsrvdsk"

$webSrvDskSize = 100
$dbSrvDskSize = 100
$appSrvDskSize = 100

$webServerIPAddress = '10.1.1.6'
$dbServerIPAddress = '10.1.1.7'
$appServerIPAddress = '10.1.1.8'

$adminUserName = "pncpnc123"
$adminPassword = "pncpnc@12345"

#$webServerImage = '/subscriptions/ec2027c3-4206-4cef-be4e-833cc78517f0/resourceGroups/Midlandls-Core_RG/providers/Microsoft.Compute/images/WebServerImage'
$webServerImage = Get-AzImage -ResourceGroupName $rgName -ImageName 'WebServerImage'
#$imageID = $webServerImage.Id

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
                -Name $name -PublicIpAddress $publicIp -PrivateIpAddress $privateIp -NetworkSecurityGroup $nsg -Subnet $subnet `
                -LoadBalancerBackendAddressPool $beAddPool -LoadBalancerInboundNatRule $natrule
        
    return $nic
}
<#function createVMConfiguration{
    param($vmName, $vmSize, $cmpName, $credential, $publisherName, $offer, $skus, $version, $nicId)
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
                  Set-AzVMOperatingSystem -Windows -ComputerName $cmpName -Credential $credential | `
                  Set-AzVMSourceImage -PublisherName $publisherName -Offer $offer `
                  -Skus $skus -Version $version | Add-AzVMNetworkInterface -Id $nicId
    return $vmConfig
} #>
function createVMConfiguration{
    param($vmName, $vmSize, $cmpName, $credential, $imageID, $nicId)
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize | `
                  Set-AzVMOperatingSystem -Windows -ComputerName $cmpName -Credential $credential | `
                  Set-AzVMSourceImage -id $imageID | Add-AzVMNetworkInterface -Id $nicId
    return $vmConfig
}
function createVM{
    param($rgName, $location, $vmConfig)
    $vm = New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig
    return $vm
}
function createFrontEndIpConfig{
    param($name, $privateIp, $subnetId)
    $feIpCnfg = New-AzLoadBalancerFrontendIpConfig -Name $name -PrivateIpAddress $privateIp -SubnetId $subnetId
    return $feIpCnfg
}
function createBackEndAddressPool{
    param($name)
    $beAddressPool= New-AzLoadBalancerBackendAddressPoolConfig -Name $name    
    return $beAddressPool
}
function createHealthProbe{
    param($name, $requestpath, $protocol, $port, $interval, $probecount)
    $healthProbe= New-AzLoadBalancerProbeConfig -Name $name -RequestPath $requestpath -Protocol $protocol -Port $port -IntervalInSeconds $interval -ProbeCount $probecount
    return $healthProbe
}
function createLoadBalancerRule{
    param($name, $frontendIP, $beAddressPool, $healthProbe, $protocol, $fePort, $bePort)
    $lbrule = New-AzLoadBalancerRuleConfig -Name $name -FrontendIpConfiguration $frontendIP -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol $protocol -FrontendPort $fePort -BackendPort $bePort
    return $lbrule
}
function createNATRule{
    param($name, $frontendIP, $protocol, $fePort, $bePort)
    $natrule= New-AzLoadBalancerInboundNatRuleConfig -Name $name -FrontendIpConfiguration $frontendIP -Protocol $protocol -FrontendPort $fePort -BackendPort $bePort
    return $natrule
}
function createLoadBalancer{
    param($rgName, $name, $location, $frontendIP, $natRules, $lbRule, $beAddressPool, $healthProbe)
    $nlb = New-AzLoadBalancer -ResourceGroupName $rgName -Name $name -Location $location -FrontendIpConfiguration $frontendIP -InboundNatRule $natRules -LoadBalancingRule $lbRule -BackendAddressPool $beAddressPool -Probe $healthProbe
    return $nlb 
}
function createAvailabilitySet{
    param($rgName, $name, $location, $sku, $updtDmnCount, $faultDmnCount)
    $availabilitySet = New-AzAvailabilitySet -ResourceGroupName $rgName -Name $name -Location $location `
                    -PlatformUpdateDomainCount $updtDmnCount -PlatformFaultDomainCount $faultDmnCount `
                    -Sku $sku   
    return $availabilitySet 
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


Try
{
    #Connect-AzAccount
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

    # Get virtual network.
    $vnet = Get-AzVirtualNetwork -Name $vnetname

    # Create a NIC for the Web server VM.
    $nicWebSrv = createNIC -rgName $rgName -Location $location -name $webServerNic -publicIp $null -privateIp $webServerIPAddress -nsg $nsg -subnet $vnet.Subnets[1]
    Write-Host "Network interface for Web server is created"
    
        # Create a Web Server in the subnet
        $password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)
        #Write-Host "Nic webserv id $nicWebSrv.Id"

<#        $vmConfig = createVMConfiguration -vmName $webServerVM -vmSize 'Standard_DS3_v2' -cmpName $webServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicWebSrv.Id
#>
          $vmConfig = createVMConfiguration -vmName $webServerVM -vmSize 'Standard_DS3_v2' -cmpName $webServerVM -credential $cred `
                        -nicId $nicWebSrv.Id -imageID $webServerImage.Id

            Write-Host "VM configuration for web Server is created"
            $webSrvVM = createVM -rgName $rgName -Location $location -vmConfig $vmConfig
           
                Write-Host "Web Server is created"
                
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -Location $location -creationOption Empty -diskSize $webSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $webSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM
                #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $webSrvDsk -createOption Attach -diskId $dataDisk.Id
                #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
<#
    # Create a NIC for the App server VM.
    $nicAppSrv = createNIC -rgName $rgName -location $location -name $appServerNic -publicIp $null -privateIp $appServerIPAddress -nsg $nsg -subnet $vnet.Subnets[1]
    Write-Host "Network interfacce for App Server is created"

        # Create a Build Server in the subnet
        $password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)
        #Write-Host "Nic Appserv id $nicAppSrv.Id"

        $vmConfig = createVMConfiguration -vmName $appServerVM -vmSize 'Standard_DS3_v2' -cmpName $appServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicAppSrv.Id

            Write-Host "VM configuration for App Server is created"
            $appVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
            
                Write-Host "App Server is created"
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize $appSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $appSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $appServerVM
                 #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $appSrvDsk -createOption Attach -diskId $dataDisk.Id
                 #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
     

    # Create a NIC for the database server VM.
    $nicDbSrv = createNIC -rgName $rgName -location $location -name $dbServerNic -publicIp $null -privateIp 10.1.1.7 -nsg $nsg -subnet $vnet.Subnets[1]
    Write-Host "Network interface for Db Server is created"

        # Create a DB Server in the subnet
        $password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)
        #Write-Host "Nic DBserv id $nicDbSrv.Id"
        
        $vmConfig = createVMConfiguration -vmName $dbServerVM -vmSize 'Standard_DS3_v2' -cmpName $dbServerVM -credential $cred `
                        -publisherName 'MicrosoftSQLServer' -offer 'SQL2017-WS2016' -skus 'SQLDEV' `
                        -version latest -nicId $nicDbSrv.Id

            Write-Host "VM configuration for DB Server is created"
            $dbVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig

                Write-Host "Database Server is created"
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize $dbSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $dbSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $dbServerVM
                #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $dbSrvDsk -createOption Attach -diskId $dataDisk.Id
                #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
#>                
}
Catch
{
   
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host "Error $_.Exception $ErrorMessage $FailedItem "
    # In case of error if you want to remove the resource group, un-comment below line.
    #Remove-AzureRmResourceGroup $rgName    
}