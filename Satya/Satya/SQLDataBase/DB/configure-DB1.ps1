$logFile = "c:\Support\PSlog1.txt"
Start-Transcript -Path $logFile -Append

$DBServer = hostname

clear

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
$log_name = "{0}_PowerShell1" -f $(get-date -Format "yyyyMMdd_HHmmss")
$log_ext = ".log"
$return_code = "0"  


Start-Sleep -Seconds 60

$DBServer | out-file -filepath C:\Support\batchlog.txt -append -width 200

Start-Sleep -Seconds 60

Logger "Creating Enterprise DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\EnterpriseValidate.sql" -ServerInstance $DBServer -QueryTimeout '500'

Start-Sleep -Seconds 900

Logger "Adding Roles to the DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\SQLLogin.sql" -ServerInstance $DBServer -QueryTimeout '500'


Stop-Transcript