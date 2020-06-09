$DBServer = hostname

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
$log_name = "{0}_GP" -f $(get-date -Format "yyyyMMdd_HHmmss")
$log_ext = ".log"
$return_code = "0"  


$logFile = "c:\Logs\PSlog.txt"
Start-Transcript -Path $logFile -Append  

Logger "Starting the services: Function Discovery Provider Host, SSDP Discovery and UPnP Device Host"
Start-Service -DisplayName "Function Discovery Provider Host"
Start-Service -DisplayName "SSDP Discovery"
Start-Service -DisplayName "UPnP Device Host"

Logger "Creating Enterprise DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\EnterpriseValidate.sql" -ServerInstance $DBServer -QueryTimeout '500'

Start-Sleep -Seconds 900

Logger "Adding Roles to the DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\SQLLogin.sql" -ServerInstance $DBServer -QueryTimeout '500'


Stop-Transcript