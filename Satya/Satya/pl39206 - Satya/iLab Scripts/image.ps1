$adminUserName = "pncpnc123"
$adminPassword = "pncpnc@12345"

$password = ConvertTo-SecureString $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($adminUserName, $password)

$rgName = 'Midlandls-Core_RG'
$location= 'EastUS2'
$webServerNic = 'Midlandls_Core_Web_Nic_02'
$webServerIPAddress = '10.1.1.10'
$snetname= 'Midlandls_Core_Subnet'
$vnetname= 'Midlandls_Core_VNET'
$webServerVM = "vmwebsrv002"
$vmImageName = 'WebServerImage'
$nsgName = 'Midlandls_Core_NSG_001'
$size = 'Standard_DS3_v2'

    # Create a Web Server in the subnet
    $webSrvVM = Get-AzVM -ResourceGroupName $rgName -Name $webServerVM -ErrorAction SilentlyContinue   
    if($webSrvVM -eq $null)
    {
        $vm = New-AzVM -ResourceGroupName $rgName -Location $location -ImageName $vmImageName -Name $webServerVM `
             -Size $size -Credential $cred -VirtualNetworkName $vnetname -SubnetName $snetname -SecurityGroupName $nsgName -PublicIpAddressName $null
        Write-Host $vm
    }
    else
    {
    Write-Host("Webserver already created")
    }