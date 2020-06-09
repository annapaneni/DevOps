

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


$logFile = "c:\Logs\PSlog.txt"
Start-Transcript -Path $logFile -Append


$strScriptUser = "vm-db-ARM2\pncpnc123"
$strPass = "pncpnc@12345"
$PSS = ConvertTo-SecureString $strPass -AsPlainText -Force
$cred = new-object system.management.automation.PSCredential $strScriptUser,$PSS

#Logger "Change user log:$strScriptUser"

Start-Job -ScriptBlock {
Logger "Creating Enterprise DataBase"
Invoke-Sqlcmd -InputFile "C:\Support\dbserver\EnterpriseValidate.sql" -ServerInstance "vm-db-ARM2" -QueryTimeout '500'
} -Credential $cred 

Stop-Transcript