$Username = '10.1.1.6\pncpnc123'
$Password = 'pncpnc@12345'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

Invoke-Command -ComputerName vmwebsrv001 -Credential $Cred -ScriptBlock { Install-WindowsFeature -name Web-Server -IncludeManagementTools }