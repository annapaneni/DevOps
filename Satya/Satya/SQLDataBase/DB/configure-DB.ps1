mkdir "C:\Logs"
$logFile = "c:\Logs\PSlog.txt"
New-Item $logFile
Start-Transcript -Path $logFile -Append

$user = hostname
$user = $user+"\pncpnc123" 
$pwd = ConvertTo-SecureString "pncpnc@12345" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($user, $pwd)

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
Install-AzCopy

C:\Support\azcopy.exe copy "https://storageforjson.blob.core.windows.net/dbserver" "C:\Support" --recursive=true

$args = "C:\Support\dbserver\configure-DB1.ps1"
Start-Process powershell.exe -Credential $Credential -ArgumentList ("-file C:\Support\dbserver\configure-DB1.ps1")


<#    
    Add-Content -Path "C:\Support\dbserver\Install.bat" -Value "cd C:\Support\dbserver\"

    Add-Content -Path "C:\Support\dbserver\Install.bat" -Value "powershell.exe -ExecutionPolicy Unrestricted -File configure-DB1.ps1"
   
    Set-Location "C:\Support\dbserver\"
    
    Start-Process "C:\Support\dbserver\Install.bat" -Verbose
#>

Stop-Transcript