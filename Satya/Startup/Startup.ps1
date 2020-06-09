#1. This script will check the server name and if the server name contains "web" then Install IIS on the server
#2. Once it check the server name and install the IIS (only for web server), It will check the raw disks which are not attached to the server will add them to the server.

#$servername = .\HOSTNAME.EXE
#Write-Host $servername


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

$servername = ($env:computername).ToLower()

if( $servername.Contains("web") )
{
    Write-Host "This is Webserver: "$servername". IIS instalation is in progress."
    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    
    # Remove default htm file
    remove-item C:\inetpub\wwwroot\iisstart.htm
    
    #Add custom htm file
    Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("Hello World from host " + $env:computername)
    
    #Install URL Rewrite module 
    Start-Process -FilePath "C:\Support\rewrite_amd64.msi" -ArgumentList '/quiet' -Wait

    #Service Account "xsElmService" add to IIS_IUSRS group 
    Add-LocalGroupMember -Group "IIS_IUSRS" -Member "ilab-midlandls\xsElmService"
    
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


    #Copy Binaries from Azure Blob storage into App Folder
    mkdir "F:\App\Binaries"
    
    }
else
{
    Write-Host "This is not Web server, so IIS not installed."
}

if( $servername.Contains("app") )
{
    Remove-Item -Path F:\App\ -Recurse
}

    #Remove Startup files from the server
    Remove-Item -Path "C:\Support\rewrite_amd64.msi" -Force
    Remove-Item -Path "C:\Support\Startup.ps1" -Force
    Remove-Item -Path "C:\Support\azcopy.exe" -Force
    Remove-Item -Path "C:\Support\CopyBinaries.bat" -Force

<#
Import-Module WebAdministration
$LogPath = “f:\logs\iis”
foreach($site in (dir iis:\sites\*))
{
New-Item $LogPath\$($site.Name) -type directory
Set-ItemProperty IIS:\Sites\$($site.Name) -name logFile.directory -value “$LogPath\$($site.Name)”
}
#>