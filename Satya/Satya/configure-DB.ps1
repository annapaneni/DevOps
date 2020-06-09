#1. This script will check the server name and if the server name contains "web" then Install IIS on the server
#2. Once it check the server name and install the IIS (only for web server), It will check the raw disks which are not attached to the server will add them to the server.


$Domain=$args[0]
$Account=$args[1]
$ServiceAccount = $args[0]+"\"+$args[1]
$DBServer=$args[2]
$role1=$args[3]
$role2 = $args[4]

   $outarray = ""
   $outarray +=$DBServer+" "  
   $outarray +=$Domain+" " 
   $outarray +=$Account+" " 
 $outarray +=$ServiceAccount+" " 
 $outarray +=$role1+" " 
 $outarray +=$role2+" " 


clear


Function Install-AzCopy {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$InstallPath = 'C:\Support'
    )

    # Cleanup Destination
    if (Test-Path $InstallPath) {
        Get-ChildItem $InstallPath | Remove-Item -Confirm:$false -Force
    }

    # Zip Destination
    $zip = "$InstallPath\AzCopy.Zip"

    # Create the installation folder (eg. C:\Support)
    $null = New-Item -Type Directory -Path $InstallPath -Force

    # Download AzCopy zip for Windows
    Start-BitsTransfer -Source "https://aka.ms/downloadazcopy-v10-windows" -Destination $zip

    # Expand the Zip file
    Expand-Archive $zip $InstallPath -Force

    # Move to $InstallPath
    Get-ChildItem "$($InstallPath)\*\*" | Move-Item -Destination "$($InstallPath)\" -Force

    #Cleanup - delete ZIP and old folder
    Remove-Item $zip -Force -Confirm:$false
    Get-ChildItem "$($InstallPath)\*" -Directory | ForEach-Object { Remove-Item $_.FullName -Recurse -Force -Confirm:$false }

    # Add InstallPath to the System Path if it does not exist
    if ($env:PATH -notcontains $InstallPath) {
        $path = ($env:PATH -split ";")
        if (!($path -contains $InstallPath)) {
            $path += $InstallPath
            $env:PATH = ($path -join ";")
            $env:PATH = $env:PATH -replace ';;',';'
        }
        [Environment]::SetEnvironmentVariable("Path", ($env:path), [System.EnvironmentVariableTarget]::Machine)
    }
}


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
$log_name = "{0}_PowerShell" -f $(get-date -Format "yyyyMMdd_HHmmss")
$log_ext = ".log"
$return_code = "0"  


$logFile = "c:\Support\PSlog.txt"
Start-Transcript -Path $logFile -Append

Logger "Downloading AZCopy to C:\Support\ folder"
Install-AzCopy

Start-Sleep -Seconds 60

$outarray | out-file -filepath C:\Support\batchlog.txt -append -width 200

Logger "Downloading .sql database files to C:\Support\ folder"
C:\Support\azcopy.exe copy "https://storageforjson.blob.core.windows.net/dbserver" "C:\Support" --recursive=true

Start-Sleep -Seconds 60

Logger "Creating Enterprise DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\EnterpriseValidate.sql" -ServerInstance $DBServer -QueryTimeout '500'

Start-Sleep -Seconds 900

Logger "Adding Roles to the DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\SQLLogin.sql" -ServerInstance $DBServer -QueryTimeout '500'


Stop-Transcript