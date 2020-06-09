#$servername = .\HOSTNAME.EXE
#Write-Host $servername


$servername = $env:computername


if( $servername.Contains("web") )
{
    Write-Host "This is Webserver: "$servername". IIS instalation is in progress."
    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    
    # Remove default htm file
    remove-item C:\inetpub\wwwroot\iisstart.htm
    
    #Add custom htm file
    Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("Hello World from host " + $env:computername)
    }
else
{
    Write-Host "This is not Web server, so IIS not installed."
}

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