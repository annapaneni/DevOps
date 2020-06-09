#1. This script will add this server to the domain: ilab.Midlandls.com". you need to provide the password for the pncpnc123 username
#2. If you want to join this server in to another domain, you need to chnage the domain name and change the credentials

Add-Computer -ComputerName $servername -DomainName "ilab.Midlandls.com" -Credential "ilab-Midlandls\pncpnc123" -Restart -Force