#1. This script will check the server name and if the server name contains "web" then Install IIS on the server
#2. Once it check the server name and install the IIS (only for web server), It will check the raw disks which are not attached to the server will add them to the server.


$Domain=$args[0]
$Account=$args[1]
$ServiceAccount = $args[0]+"\"+$args[1]
$DBServer=$args[2]
$AppServer=$args[3]
$WebServer = $args[4]
$location = $args[5]
$apppassword = $args[6]
$resourceGroup = $args[7]

   $outarray = ""
   $outarray +=$DBServer+" " 
   $outarray +=$AppServer+" " 
   $outarray +=$Domain+" " 
   $outarray +=$Account+" " 
 $outarray +=$ServiceAccount+" " 
 $outarray +=$WebServer+" " 
 $outarray +=$location+" " 
 $outarray +=$apppassword+" " 
 $outarray +=$resourceGroup

$outarray | out-file -filepath C:\Support\batchlog.txt -append -width 200

# Initialize the Raw disks and added to VM
$disks = Get-Disk | Where partitionstyle -eq 'raw' | sort number
$letters = 70..89 | ForEach-Object { [char]$_ }
$count = 0
$labels = "Data Disk 1","Data Disk 2","Data Disk 3"


foreach ($disk in $disks)
{
    $driveLetter = $letters[$count].ToString()
    $disk | 
    Initialize-Disk -PartitionStyle MBR -PassThru |
    New-Partition -UseMaximumSize -DriveLetter $driveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel $labels[$count] -Confirm:$false -Force
    $count++
}
try
{
$logFile = "c:\Support\PSlog.txt"
Start-Transcript -Path $logFile -Append

    #Copy Binaries from Azure Blob storage into App Folder
    mkdir "F:\App\Enterprise"  
    
    Start-Process "cmd.exe" "/c c:\Support\CopyEnterprise.bat" 

    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    
    # Remove default htm file
    remove-item C:\inetpub\wwwroot\iisstart.htm
    
    #Add custom htm file
    Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("Hello World from Web Server")
    
    #Install URL Rewrite module 
    Start-Process -FilePath "C:\Support\rewrite_amd64.msi" -ArgumentList '/quiet' -Wait

    #Service Account "xsElmService" add to IIS_IUSRS group 
    Add-LocalGroupMember -Group "IIS_IUSRS" -Member $ServiceAccount
    
    #create app folder on data disk
    $appdir = "F:\App"
    mkdir $appdir

    #give IIS_IUSRS access to app folder Read & execute, List folder contents, Read
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\IIS_IUSRS", "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl = Get-ACL "F:\App"
    $acl.AddAccessRule($accessRule)
    Set-ACL -Path $appdir -ACLObject $acl

    #IIS - set logs to f:\logs\iis
    $logdir = "f:\logs\iis"
    mkdir $logdir 
    Import-Module WebAdministration
    Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $logdir
    

    # List the Installed Features on the server
    Get-WindowsFeature | Where-Object {$_. installstate -eq "installed"}

    # Installing the Feature HTTP Redirection 
    Install-WindowsFeature Web-Http-Redirect

    # Installing the Feature Logging Tools
    Install-WindowsFeature Web-Log-Libraries

    # Installing the Feature Request Monitor
    Install-WindowsFeature Web-Request-Monitor

    # Installing the Feature Tracing 
    Install-WindowsFeature Web-Http-Tracing

    # Installing the Feature IP and Domain Restrictions 
    Install-WindowsFeature Web-IP-Security

    # Installing the Feature URL Authorization    
    Install-WindowsFeature Web-Url-Auth

    # Installing the Feature Windows Authentication 
    Install-WindowsFeature Web-Windows-Auth

    # Installing the Feature  .NET Extensibility 4.6
    Install-WindowsFeature Web-Net-Ext45

    # Installing the Feature Application Initialization
    Install-WindowsFeature Web-AppInit

    # Installing the Feature ASP.NET 4.6
    Install-WindowsFeature Web-Asp-Net45

    # Installing the Feature ISAPI Extensions
    Install-WindowsFeature Web-ISAPI-Ext

    # Installing the Feature ISAPI Filters
    Install-WindowsFeature Web-ISAPI-Filter

    # List the Installed Features on the server
    Get-WindowsFeature | Where-Object {$_. installstate -eq "installed"}

    Add-Content -Path "F:\Install.bat" -Value "F:\App\Enterprise\builds\20180.2.0.4932\Enterprise_Installer\StartWebInstaller.bat $DBServer $AppServer $Account"

    Set-Location "F:\App\Enterprise\builds\20180.2.0.4932\Enterprise_Installer\"

    Start-Process "F:\Install.bat"

    #Start-Process "StartWebInstaller.bat $DBServer $AppServer $Account"

    #Start-Process "cmd.exe" "/c F:\App\Enterprise\builds\20180.2.0.4932\Enterprise_Installer\StartWebInstaller.bat $DBServer $AppServer $Account"

    Start-Sleep -s 150


#Installing Azure Powershell Module
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name Az -AllowClobber -Force

#connect Azure Subscription
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


    #Add a certificate to VM from Key Vault
    $certURL=(Get-AzKeyVaultSecret -VaultName $keyvaultName -Name $certName).id

    $vaultId=(Get-AzKeyVault -ResourceGroupName $vaultresourceGroup -VaultName $keyVaultName).ResourceId


    $vm=Get-AzVM -ResourceGroupName $resourceGroup -Name $WebServer

    $vm = Add-AzVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "My" -CertificateUrl $certURL
    $vm = Add-AzVMSecret -VM $vm -SourceVaultId $vaultId -CertificateStore "Root" -CertificateUrl $certURL


    Update-AzVM -ResourceGroupName $resourceGroup -VM $vm

<#
    #Specify Application pool identity userame and password
    Import-Module WebAdministration
    Set-ItemProperty IIS:\AppPools\ELM -name processModel -value @{userName=$ServiceAccount;password=$apppassword;identitytype=3}

    
    #Configure IIS to use the certificate
    New-WebBinding -Name "Default Web Site" -Protocol https -Port 443
    Get-ChildItem cert:\localmachine\My | New-Item -Path IIS:\SslBindings\!443

#>
Stop-Transcript
}
catch { }