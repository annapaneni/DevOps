

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


Logger "Creating Enterprise DataBase"
$username = 'vm-db-ARM2\pncpnc123'
$Password = 'pncpnc@12345' | ConvertTo-SecureString -Force -AsPlainText
$credential = New-Object System.Management.Automation.PsCredential($username, $Password) 
Start-Process powershell -argumentlist '-executionpolicy','bypass','-file','"C:\Support\dbserver\configure-DB2.ps1"' -Credential $credential  


Stop-Transcript