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
function createVMConfiguration{
    param($vmName, $vmSize, $cmpName, $credential, $publisherName, $offer, $skus, $version, $nicId, $availabilitySetId)
    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $availabilitySetId | `
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
    # Get the resource group.
    $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
    if($rg -eq $null){
        # Create a resource group.
        New-AzResourceGroup -Name $rgName -location $location
        Write-Host "Resource Group is created $rg"
    }
    else
    {
    Write-Host "Resource Group $rgName already exists."
    }

     # Get virtual network.
    $vnet = Get-AzVirtualNetwork -Name $vnetname -ErrorAction SilentlyContinue
    Write-Host "Vnet: $vnet"     
    if($vnet -eq $null ){
        # Create a sub net.
        $subnet = creationSubNet -name $snetname -addressPrefix $snetAddressPrefix
        Write-Host "SubNet is created $subnet"
        # Create a virtual network.
        $vnet = createVNet -rgName $rgName -name $vnetname -addressPrefix $vnetAddressPrefix -location $location -subnets $subnet
        Write-Host "VNet is created $vnet"
    }
    else
    {
    Write-Host "vnet $vnet already exists."
    }

    # Get load balancer.
    $nlb= Get-AzLoadBalancer -ResourceGroupName $rgName -Name $lbName -ErrorAction SilentlyContinue 
    if($nlb -eq $null){
        # Create a front-end IP configuration for the website (for the incoming traffic).
        $frontendIP = createFrontEndIpConfig -name $feIpCnfgName -privateIp $privateIp -subnetId $vnet.subnets[1].Id
        if($frontendIP -ne $null){
            Write-Host "Front end ip config is created $frontendIP"
        }
        # Create a back-end address pool to receive incoming traffic from the front-end IP pool.
        # Because of back-end address pool, network interfaces receive the load-balanced traffic from the front-end IP address.
        $beAddressPool= createBackEndAddressPool -name $beAddressPoolName
        if($beAddressPool -ne $null){
            Write-Host "Back end address pool is created $beAddressPool"
        }
        # Creates a load balancer probe on port 80.
        # To allow the Load Balancer to monitor the status of your app, you use a health probe. 
        # The health probe dynamically adds or removes VMs from the Load Balancer rotation based on their response to health checks. 
        # Create a health probe HealthProbe to monitor the health of the VMs.
        $healthProbe = createHealthProbe -name $healthProbeName -requestpath $requestPath -protocol $protocol -port $healthProbePort -interval $healthProbeInterval -probecount $probeCount
        if($healthProbe -ne $null){
            Write-Host "Health probe is created $healthProbe"
        }
        # Creates a load balancer rule for defining how traffic is distributed to VMs 
        # in the back-end address pool.
        $lbRule= createLoadBalancerRule -name $lbruleName -frontendIP $frontendIP -beAddressPool $beAddressPool -healthProbe $healthProbe -protocol Tcp -fePort $frontEndPort -bePort $backEndPort
        if($lbRule -ne $null){
            Write-Host "Load balancer rule is created $lbRule"
        }        
        Write-Host "Getting Load balancer $nlb"
        #Create a load balancer
        $nlb= createLoadBalancer -rgName $rgName -name $lbName -location $location -frontendIP $frontendIP -natRules $null -lbRule $lbRule -beAddressPool $beAddressPool -healthProbe $healthProbe
        Write-Host "Load balancer is created $nlb"
        
    } 
    else
    {
    Write-Host "lb $nlb already exists."
    }
       
    $securityRules = $null

    # Create a network security group.
    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nsg -eq $null){
        $nsg = createNetworkSecurityGroup -rgName $RgName -location $location -name $nsgName -securityRules $securityRules
        Write-Host "Network security group is created $nsg"
         #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snetname `
            -AddressPrefix $snetAddressPrefix -NetworkSecurityGroup $nsg
        $vnet | Set-AzVirtualNetwork
    }
     else
    {
    Write-Host "nsg $nsg already exists."
    }
   
     # Create a NIC for the devops server VM.
    $nicWebSrv = Get-AzNetworkInterface -Name $webServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue 
    if($nicWebSrv -eq $null){
        $nicWebSrv = createNIC -rgName $rgName -location $location -name $webServerNic -publicIp $null -privateIp 10.1.1.6 -nsg $nsg -subnet $vnet.Subnets[1] `
                                    -beAddPool $nlb.BackendAddressPools[0] -natrule $null
        Write-Host "Network interface for Web server is created $nicWebSrv"
    }    
    # Create a NIC for the database server VM.
    $nicDbSrv = Get-AzNetworkInterface -Name $dbServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue
    if($nicDbSrv -eq $null){
        $nicDbSrv = createNIC -rgName $rgName -location $location -name $dbServerNic -publicIp $null -privateIp 10.1.1.7 -nsg $nsg -subnet $vnet.Subnets[1] `
                               -beAddPool $nlb.BackendAddressPools[0] -natrule $null
        Write-Host "Network interface for Db Server is created $nicDbSrv"
    }
     # Create a NIC for the build server VM.
    $nicAppSrv = Get-AzNetworkInterface -Name $appServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nicAppSrv -eq $null){
        $nicAppSrv = createNIC -rgName $rgName -location $location -name $appServerNic -publicIp $null -privateIp 10.1.1.8 -nsg $nsg -subnet $vnet.Subnets[1] `
                                    -beAddPool $nlb.BackendAddressPools[0] -natrule $null
        Write-Host "Network interfacce for App Server is created $nicAppSrv"
    }
     
    # Get an availability set.
    $availSet = Get-AzAvailabilitySet -ResourceGroupName $rgName -Name $availabilitySet -ErrorAction SilentlyContinue
    if(!$availSet){
        # Create an availability set.
        $availSet = createAvailabilitySet -rgName $rgName -name $availabilitySet `
                        -location $location -sku Aligned -updtDmnCount 3 -faultDmnCount 3
        Write-Host "Availability set is created $availSet"
    }
     else
    {
    Write-Host "availset $availset already exists."
    }

    # Create a Devops Server in the subnet
    $webSrvVM = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM -ErrorAction SilentlyContinue   
    if($webSrvVM -eq $null){
        $password = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ("pncpnc123", $password)
        Write-Host "Niciwebserv id $nicWebSrv.Id"
        Write-Host "availability set id: $availSet.Id"
        $vmConfig = createVMConfiguration -vmName $webServerVM -vmSize 'Standard_DS3_v2' -cmpName $webServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicWebSrv.Id -availabilitySetId $availSet.Id
    
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
    else
    {
    Write-Host "devops server already exists."
    }    
    $dbVM = Get-AzVM -ResourceGroupName $rgName -Name $dbServerVM -ErrorAction SilentlyContinue 
    if($dbVM -eq $null){
        # Create a DB Server in the subnet
        $password = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ("pncpnc123", $password)
        
        $vmConfig = createVMConfiguration -vmName $dbServerVM -vmSize 'Standard_DS3_v2' -cmpName $dbServerVM -credential $cred `
                        -publisherName 'MicrosoftSQLServer' -offer 'SQL2017-WS2016' -skus 'SQLDEV' `
                        -version latest -nicId $nicDbSrv.Id -availabilitySetId $availSet.Id

        if($vmConfig -ne $null){
            Write-Host "VM configuration for DB Server is created $vmConfig"
            $dbVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
            if($dbVM -ne $null){
                Write-Host "Database Server is created $dbVM"
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize $dbSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $dbSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $dbServerVM
                #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $dbSrvDsk -createOption Attach -diskId $dataDisk.Id
                #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
            }
        }
    }
     else
    {
    Write-Host "db server already exists."
    }

    $appVM = Get-AzVM -ResourceGroupName $rgName -Name $appServerVM -ErrorAction SilentlyContinue    
    if($appVM -eq $null){
        # Create a Build Server in the subnet
        $password = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ("pncpnc123", $password)

        $vmConfig = createVMConfiguration -vmName $appServerVM -vmSize 'Standard_DS3_v2' -cmpName $appServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicAppSrv.Id -availabilitySetId $availSet.Id
        if($vmConfig -ne $null){
            Write-Host "VM configuration for App Server is created $vmConfig"
            $appVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
            if($appVM -ne $null){
                Write-Host "App Server is created $appVM"
                #Create additional disk configuration
                $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize $appSrvDskSize
                #Create a data disk
                $dataDisk =createDataDisk -rgName $rgName -name $appSrvDsk -diskConfig $diskConfig

                $vm = Get-AzVM -ResourceGroupName $rgName -Name $appServerVM
                 #Add newly created datadisk to VM
                $vm = addDataDiskToVM -vm $vm -diskName $appSrvDsk -createOption Attach -diskId $dataDisk.Id
                 #Update VM with newly added disk
                Update-AzVM -ResourceGroupName $rgName -VM $vm
            }
        }
    }
     else
    {
    Write-Host "app server already exists."
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