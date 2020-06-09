#"Adding this sever to the domain: ilab.Midlandls.com"

$servername = $env:computername

Write-Host "Adding this sever to the domain: ilab.Midlandls.com"

Set-DnsClientServerAddress -InterfaceIndex 2 -ServerAddresses ("10.1.1.6")
Set-DnsClientServerAddress -InterfaceIndex 3 -ServerAddresses ("10.1.1.6")

Add-Computer -ComputerName $servername -DomainName "ilab.Midlandls.com" -Credential "ilab-Midlandls\PL39260" -Restart -Force