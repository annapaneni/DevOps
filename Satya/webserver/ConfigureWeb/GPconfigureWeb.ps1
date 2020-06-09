
#Function logger enters the information into the log file and output#
function Logger ($msg, $logFile= $log_path+$log_name+$log_ext){
    $msg = $msg -replace "`r","" -replace "`n",", " 
    $log_msg="$(get-date -Format "MM-dd-yyyy HH:mm:ss") : $msg"
	Add-Content -Path $logFile -Value $log_msg
	Write-host $log_msg
    
}  

$folderName = "C:\Logs\"

 If (-not (Test-Path -Path $folderName)){
            New-Item $folderName -ItemType directory
        }  

$log_path = $folderName
$log_name = "{0}_WebGP" -f $(get-date -Format "yyyyMMdd_HHmmss")
$log_ext = ".log"
$return_code = "0"  

Logger "Starting the services: Function Discovery Provider Host, SSDP Discovery and UPnP Device Host"
Start-Service -DisplayName "Function Discovery Provider Host"
Start-Service -DisplayName "SSDP Discovery"
Start-Service -DisplayName "UPnP Device Host"

Logger "connecting Azure Subscription"
$User = "satyaprasad.annapaneni@pncilab.com"
$PWord = ConvertTo-SecureString -String "Annik@123" -AsPlainText -Force
$tenant = "1da782d1-e930-491b-8135-2fb047851e47"
$subscription = "ec2027c3-4206-4cef-be4e-833cc78517f0"
$Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User,$PWord
Connect-AzAccount -Credential $Credential -Tenant $tenant -Subscription $subscription


#Create an Azure Key Vault
$vaultresourceGroup = "rg-hub"
$keyvaultName = "MidlandlsCertKeyVault"
$certName = "MidlandlsWebCert"

    Logger "Adding the certificate to VM from Key Vault"
    $certURL=(Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $certName).id

    $vaultId=(Get-AzKeyVault -ResourceGroupName $vaultresourceGroup -VaultName $keyVaultName).ResourceId


    $vm=Get-AzVM -ResourceGroupName $resourceGroup -Name $WebServer

    $vm = Add-AzVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL
    $vm = Add-AzVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "Root" -CertificateUrl $certURL


    Update-AzVM -ResourceGroupName $resourceGroup -VM $vm

    Logger "Try - Configure IIS to use the certificate"
    New-WebBinding -Name "Default Web Site" -Protocol https -Port 443
    Get-ChildItem cert:\localmachine\My | New-Item -Path IIS:\SslBindings\!443