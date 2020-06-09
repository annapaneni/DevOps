$path = $MyInvocation.MyCommand.Path
if (!$path) {
    $path = $psISE.CurrentFile.Fullpath
}
if ($path) {
    $path = Split-Path $path -Parent
}
Import-Module -Name "$path\operations1.ps1"
Import-Module -Name "$path\inputs1.ps1"
Try
{
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
        $subnet1 = creationSubNet -name $snet1name -addressPrefix $snet1AddressPrefix
        $subnet2 = creationSubNet -name $snet2name -addressPrefix $snet2AddressPrefix
        $subnet3 = creationSubNet -name $snet3name -addressPrefix $snet3AddressPrefix

        $subnets =  $subnet1 , $subnet2 , $subnet3
        Write-Host "SubNet is created" 
        # Create a virtual network.
        $vnet = createVNet -rgName $rgName -name $vnetname -addressPrefix $vnetAddressPrefix -location $location -subnets $subnets
        Write-Host "VNet is created" $vnet.Name
    }
    else
    {
    Write-Host $vnet.Name "vnet already exists."
    }

    # Create a network security group.
    $nsg1 = Get-AzNetworkSecurityGroup -Name $nsg1Name -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nsg1 -eq $null){
    
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

        $nsg1 = createNetworkSecurityGroup -rgName $rgName -location $location -name $nsg1Name -securityRules $securityRules1
        Write-Host "Network security group1 is created" 
         #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snet1name -AddressPrefix $snet1AddressPrefix -NetworkSecurityGroup $nsg1 #-InformationAction SilentlyContinue
        
       # $vnet | Set-AzVirtualNetwork
       
     }
     else
    {
    Write-Host $nsg1.Name "nsg already exists."
    }
     $nsg2 = Get-AzNetworkSecurityGroup -Name $nsg2Name -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nsg2 -eq $null){
    

    $rule4 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the first subnet.
    $rule5 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    # Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
    $rule6 = createSecurityRule -name 'Deny-Internet-All' -description "Deny all Internet" -Access Allow -Protocol Tcp -Direction Outbound -Priority 101 `
    -SourceAddressPrefix * -SourcePortRange * ` -DestinationAddressPrefix Internet -DestinationPortRange *

    $securityRules2 = $rule4, $rule5, $rule6

        $nsg2 = createNetworkSecurityGroup -rgName $rgName -location $location -name $nsg2Name -securityRules $securityRules2
        Write-Host "Network security group2 is created" 
         #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snet2name -AddressPrefix $snet2AddressPrefix -NetworkSecurityGroup $nsg2 #-InformationAction SilentlyContinue
        
        $vnet | Set-AzVirtualNetwork
       
     }
     else
    {
    Write-Host $nsg2.Name "nsg already exists."
    }

     $nsg3 = Get-AzNetworkSecurityGroup -Name $nsg3Name -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nsg3 -eq $null){
    
    

    $rule7 = createSecurityRule -name 'Allow-HTTP-All' -description 'Allow HTTP' -access Allow -protocol Tcp -direction Inbound -priority 100 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 80

    # Create an NSG rule to allow RDP traffic from the Internet to the first subnet.
    $rule8 = createSecurityRule -name 'Allow-RDP-All' -description 'Allow RDP' -access Allow -protocol Tcp -direction Inbound -priority 200 `
    -sourceAddressPrefix Internet -sourcePortRange * -destinationAddressPrefix * -destinationPortRange 3389

    # Create an NSG rule to block all outbound traffic from the back-end subnet to the Internet (inbound blocked by default).
    $rule9 = createSecurityRule -name 'Deny-Internet-All' -description "Deny all Internet" -Access Allow -Protocol Tcp -Direction Outbound -Priority 101 `
    -SourceAddressPrefix * -SourcePortRange * ` -DestinationAddressPrefix Internet -DestinationPortRange *

    $securityRules3 = $rule7, $rule8, $rule9
        $nsg3 = createNetworkSecurityGroup -rgName $rgName -location $location -name $nsg3Name -securityRules $securityRules3
        Write-Host "Network security group3 is created" 
         #update virtual network with network security group
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $snet3name -AddressPrefix $snet3AddressPrefix -NetworkSecurityGroup $nsg3 #-InformationAction SilentlyContinue

       
        $vnet | Set-AzVirtualNetwork
     }
     else
    {
    Write-Host $nsg3.Name "nsg already exists."
    }
     
    $nicWebSrv = Get-AzNetworkInterface -Name $webServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue 
    if($nicWebSrv -eq $null){
    # Create a NIC for the Web server VM.
    $nicWebSrv = createNIC -rgName $rgName -location $location -name $webServerNic -publicIp $null -privateIp $webServerIPAddress -nsg $nsg1 -subnet $vnet.Subnets[0]
    Write-Host "Network interface for Web server is created"
    }
        
    $webSrvVM = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM -ErrorAction SilentlyContinue   
    if($webSrvVM -eq $null){
        # Create a Web Server in the subnet
        $password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)
        #Write-Host "Nic webserv id $nicWebSrv.Id"

        $vmConfig = createVMConfiguration -vmName $webServerVM -vmSize 'Standard_DS3_v2' -cmpName $webServerVM -credential $cred `
                        -publisherName 'MicrosoftWindowsServer' -offer 'WindowsServer' -skus '2016-Datacenter' `
                        -version latest -nicId $nicWebSrv.Id
    
            Write-Host "VM configuration for web Server is created"
            $webSrvVM = createVM -rgName $rgName -location $location -vmConfig $vmConfig
            
                Write-Host "Web Server is created"
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
    else
    {
    Write-Host  "web server already exists."
    }
    
     $nicAppSrv = Get-AzNetworkInterface -Name $appServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue  
    if($nicAppSrv -eq $null){
    # Create a NIC for the App server VM.
    $nicAppSrv = createNIC -rgName $rgName -location $location -name $appServerNic -publicIp $null -privateIp $appServerIPAddress -nsg $nsg2 -subnet $vnet.Subnets[1]
    Write-Host "Network interfacce for App Server is created"
    }

    $appVM = Get-AzVM -ResourceGroupName $rgName -Name $appServerVM -ErrorAction SilentlyContinue    
    if($appVM -eq $null){
        # Create a app Server in the subnet
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
     
    }
    else
    {
    Write-Host  "app server already exists."
    }
    
    $nicDbSrv = Get-AzNetworkInterface -Name $dbServerNic -ResourceGroupName $rgName -ErrorAction SilentlyContinue
    if($nicDbSrv -eq $null){
    # Create a NIC for the database server VM.
    $nicDbSrv = createNIC -rgName $rgName -location $location -name $dbServerNic -publicIp $null -privateIp $dbServerIPAddress -nsg $nsg3 -subnet $vnet.Subnets[2]
    Write-Host "Network interface for Db Server is created"
    }
    $dbVM = Get-AzVM -ResourceGroupName $rgName -Name $dbServerVM -ErrorAction SilentlyContinue 
    if($dbVM -eq $null){
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
    }
    
        else
    {
    Write-Host "db server already exists."
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