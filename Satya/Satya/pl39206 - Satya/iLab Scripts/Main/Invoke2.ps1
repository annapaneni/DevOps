#Store the password in credential#
Read-host -assecurestring | convertfrom-securestring | out-file C:\cred.txt
$password = get-content C:\cred.txt | convertto-securestring
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist "10.1.1.6\pncpnc123",$pass
#Use invoke-command to execute the operation#
Invoke-command –computername vmwebsrv001 -credential $credential –scriptblock { Install-WindowsFeature -name Web-Server -IncludeManagementTools }