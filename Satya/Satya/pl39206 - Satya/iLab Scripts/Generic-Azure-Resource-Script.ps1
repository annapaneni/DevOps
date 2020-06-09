$rgName = 'Midlands_Core_RG'
$location= 'EastUS'
$snetname= 'Midlands_Core_Subnet'
$snetAddressPrefix= '10.1.2.0/24'
$vnetname= 'Midlands_Core_VNETCONN'
$vnetAddressPrefix= '10.1.0.0/23'
$feIpCnfgName= 'Midlands_Core_Lb_Frontend_Ip'
$privateIp= '10.1.2.1'
$beAddressPoolName= 'Midlands_Core_Lb_Backend_Addresspool'
$healthProbeName= 'HealthProbe'
$requestPath ='/'
$protocol= 'http'
$healthProbePort= 80
$healthProbeInterval= 15
$probeCount= 2
$lbruleName= 'HTTP'
$frontEndPort= 80
$backEndPort= 80
$lbName= 'Midlands_Core_lb_001'
$nsgName = 'Midlands_Core_NSG_001'

$webServerNic = 'Midlands_Core_Web_Nic_01'
$dbServerNic = 'Midlands_Core_Db_Nic_01'
$appServerNic = 'Midlands_Core_App_Nic_01'

$availabilitySet = "Midlands_Core_Avail"

$webServerVM = "vmwebsrv001"
$dbServerVM = "vmdbserver001"
$appServerVM = "vmappsrv001"


$webSrvDsk = "websrvdsk"
$dbSrvDsk = "dbsrvdsk"
$appSrvDsk = "appsrvdsk"
function createSubNet{
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
    $availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $name -Location $location `
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
    Connect-AzAccount
    Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
    # Get the resource group.
    $rg = Get-AzResourceGroup -Name $rgName
    if($rg -eq $null ){
        # Create a resource group.
        New-AzResourceGroup -Name $rgName -location $location
        Write-Host "Resource Group is created $rg"
    }
     # Get virtual network.    
    $subnets = New-Object System.Collections.Generic.List[System.Object]
    $vnetname = Read-Host "Please enter virtual network name..";
    $vnet = Get-AzVirtualNetwork -Name $vnetname      
    if($vnet -eq $null ){
        # Create a sub net.
        $noOfSubnet = Read-Host "How many subnets do you want to create ?";
        
        if($noOfSubnet -gt 0){
            for($i=0;$i-lt $noOfSubnet; $i++){
                $snetAddressPrefix = Read-Host "Please enter subnet address prefix for subnet.."
                $snetname = Read-Host "Please enter subnet name.."
                $subnet = createSubNet -name $snetname -addressPrefix $snetAddressPrefix                
                $subnets.Add($subnet);
            }
        }        
        
        # Create a virtual network.    
        $vnetAddressPrefix = Read-Host "Please enter address prefix for virtual network..";
        $vnet = createVNet -rgName $rgName -name $vnetname -addressPrefix $vnetAddressPrefix -location $location -subnets $subnets
        Write-Host "VNet is created $vnet"
    } else {
        $noOfSubnet = Read-Host "How many subnets do you want to create ?";
        
        if($noOfSubnet -gt 0){
            for($i=0;$i-lt $noOfSubnet; $i++){
                $snetAddressPrefix = Read-Host "Please enter subnet address prefix for subnet.."
                $snetname = Read-Host "Please enter subnet name.."
                Add-AzureRmVirtualNetworkSubnetConfig -Name $snetname -VirtualNetwork $vnet -AddressPrefix $snetAddressPrefix `
                | Set-AzureRmVirtualNetwork
                $subnets.Add($subnet);
            }
        }
    }
     # Get an availability set.
    $availSet = Get-AzureRmAvailabilitySet -ResourceGroupName $rgName -Name $availabilitySet
    if(!$availSet){
        # Create an availability set.
        $availSet = createAvailabilitySet -rgName $rgName -name $availabilitySet `
                        -location $location -sku Aligned -updtDmnCount 3 -faultDmnCount 3
        Write-Host "Availability set is created $availSet"
    }
    $nlbs = New-Object System.Collections.Generic.List[System.Object];
    for($i=0;i - lt $vnet.Subnets.length;$i++){
        Write-Host "Subnet: $vnet.Subnets[$i]"
        $lbName = Read-Host "Please enter load balancer name..";
        # Get load balancer.
        $nlb= Get-AzureRmLoadBalancer -ResourceGroupName $rgName -Name $lbName 
        if($nlb -eq $null){
            # Create a front-end IP configuration for the website (for the incoming traffic).
        
            $feIpCnfgName = Read-Host "Please enter front end IP configuration name..";
            $privateIp = Read-Host "Please enter private IP address which will be used to divert network tracffic to available vm..";
            #$subnetname = Read-Host "Please enter subnet name for which you want to create this load balancer..";
            #$lbsubnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet
            $frontendIP = createFrontEndIpConfig -name $feIpCnfgName -privateIp $privateIp -subnetId $vnet.Subnets[$i].Id
            if($frontendIP -ne $null){
                Write-Host "Front end ip config is created $frontendIP"
            }
            # Create a back-end address pool to receive incoming traffic from the front-end IP pool.
            # Because of back-end address pool, network interfaces receive the load-balanced traffic from the front-end IP address.
        
            $beAddressPoolName = Read-Host "Please enter back end address pool name..";
            $beAddressPool= createBackEndAddressPool -name $beAddressPoolName
            if($beAddressPool -ne $null){
                Write-Host "Back end address pool is created $beAddressPool"
            }
            # Creates a load balancer probe on port 80.
            # To allow the Load Balancer to monitor the status of your app, you use a health probe. 
            # The health probe dynamically adds or removes VMs from the Load Balancer rotation based on their response to health checks. 
            # Create a health probe HealthProbe to monitor the health of the VMs.
        
            $healthProbeName = Read-Host "Please enter health probe name.."
            #$protocol = Read-Host "Please enter protocol name.."

            $healthProbe = createHealthProbe -name $healthProbeName -requestpath $requestPath -protocol $protocol -port $healthProbePort -interval $healthProbeInterval -probecount $probeCount
            if($healthProbe -ne $null){
                Write-Host "Health probe is created $healthProbe"
            }
            # Creates a load balancer rule for defining how traffic is distributed to VMs 
            # in the back-end address pool.
            $lbruleName = Read-Host "Please load balancer rule name which distributes the traffic."
            $lbRule= createLoadBalancerRule -name $lbruleName -frontendIP $frontendIP -beAddressPool $beAddressPool -healthProbe $healthProbe -protocol Tcp -fePort $frontEndPort -bePort $backEndPort
            if($lbRule -ne $null){
                Write-Host "Load balancer rule is created $lbRule"
            }        
            Write-Host "Getting Load balancer $nlb"
            #Create a load balancer
            $nlb= createLoadBalancer -rgName $rgName -name $lbName -location $location -frontendIP $frontendIP -natRules $null -lbRule $lbRule -beAddressPool $beAddressPool -healthProbe $healthProbe
            $nlbs.Add($nlb);
            Write-Host "Load balancer is created $nlb"
        
        }
    
        
        $securityRules = $null

        # Create a network security group.
        $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName   
        if($nsg -eq $null){
            $nsg = createNetworkSecurityGroup -rgName $RgName -location $location -name $nsgName -securityRules $securityRules
            Write-Host "Network security group is created $nsg"
        }
        #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnet.Subnets[$i].Name `
            -AddressPrefix $vnet.Subnets[$i].AddressPrefix -NetworkSecurityGroup $nsg
        $vnet | Set-AzVirtualNetwork

        $noofVM = Read-Host "How many servers need to be created ?"
        if($noofVM -gt 0){
            for($j=0;$j -lt $noofVM; $j++){
                $nicName = Read-Host "Please enter network interface card name.."
                $privateIP = Read-Host "Please enter private IP address for network interface card.."    
                $nic = createNIC -rgName $rgName -location $location -name $nicName -publicIp $null -privateIp $privateIP `
                                        -nsg $nsg -subnet $vnet.Subnets[$i] -beAddPool $nlbs[$i].BackendAddressPools[0] -natrule $null
                Write-Host "Network interface is created $nic"

                # Create a Server in the subnet
                $serverName = Read-Host "Please enter server name.."
                $server = Get-AzureRmVM -ResourceGroupName $rgName -Name $serverName    
                $isDbSrv = Read-Host "Is it sql database server ? Please enter Y or N"
                if($server -eq $null){
                    $password = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
                    $cred = New-Object System.Management.Automation.PSCredential ("pncpnc123", $password)

                    if($isDbSrv -eq 'Y'){
                        $vmConfig = createVMConfiguration -vmName $serverName -vmSize 'Standard_B1s' -cmpName $serverName -credential $cred `
                            -publisherName 'MicrosoftSQLServer' -offer 'SQL2017-WS2016' -skus 'SQLDEV' `
                            -version latest -nicId $nic.Id -availabilitySetId $availSet.Id
                    }else{
                        $vmConfig = createVMConfiguration -vmName $serverName -vmSize 'Standard_B1s' -cmpName $serverName -credential $cred `
                                    -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                                    -version latest -nicId $nic.Id -availabilitySetId $availSet.Id
                    }                    

                    if($vmConfig -ne $null){
                        Write-Host "VM configuration for Server is created $vmConfig"
                        $srvVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
                        if($srvVM -ne $null){
                            Write-Host "Web Server is created $srvVM"
                            $diskSize = Read-Host "Please enter disk size.."
                            $diskName = Read-Host "Please enter disk name.."
                            #Create additional disk configuration
                            $diskConfig = createDataDiskConfig -location $location -creationOption Empty -diskSize [int]$diskSize
                            #Create a data disk
                            $dataDisk =createDataDisk -rgName $rgName -name $diskName -diskConfig $diskConfig

                            $vm = Get-AzVM -ResourceGroupName $rgName -Name $serverName
                            #Add newly created datadisk to VM
                            $vm = addDataDiskToVM -vm $vm -diskName $diskName -createOption Attach -diskId $dataDisk.Id
                            #Update VM with newly added disk
                            Update-AzVM -ResourceGroupName $rgName -VM $vm
                        }
                    }
                } 

            }
        }  
    }
}
Catch
{
    $Error= $_.Exception
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host "Error $Error $ErrorMessage $FailedItem "
    # In case of error if you want to remove the resource group, un-comment below line.
    #Remove-AzureRmResourceGroup $rgName    
}