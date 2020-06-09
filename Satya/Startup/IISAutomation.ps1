clear

Import-Module "WebAdministration"

#$AppPool = "DefaultAppPool"
$AppPool = "demolegacyapp"

$IISPath = "IIS:\AppPools"
cd $IISPath
if (Test-Path ".\$AppPool") { Remove-WebAppPool -Name $AppPool 
Write-Host $AppPool" Removed" }

#$WebSite = "Default Web Site" 
$WebSite = "demolegacyapp" 
$IISPath = "IIS:\Sites\"
cd $IISPath
if (Test-Path ".\$WebSite") { #Remove-IISSite -Name $WebSite
#Stop-WebSite -Name $WebSite
Remove-WebSite -Name $WebSite
Write-Host $WebSite" Removed" }


New-Item IIS:\AppPools\demolegacyapp

#New-Item iis:\Sites\demolegacyapp -bindings @{protocol="http";bindingInformation=":80:demolegacyapp"} -physicalPath F:\App\Binaries\demolegacyapp\DemoLegacyApp

New-Item iis:\Sites\demolegacyapp -bindings @{protocol="http";bindingInformation=":80:"} -physicalPath F:\App\Binaries\demolegacyapp\DemoLegacyApp

Set-ItemProperty IIS:\Sites\demolegacyapp -name applicationPool -value demolegacyapp

New-Item IIS:\Sites\demolegacyapp\VirtualDirectory -physicalPath F:\App\Binaries\demolegacyapp\DemoLegacyApp -type VirtualDirectory

<#
New-Item IIS:\Sites\demolegacyapp -physicalPath F:\App\Binaries\demolegacyapp\DemoLegacyApp -type Application

Set-ItemProperty IIS:\sites\demolegacyapp\DemoApp -name applicationPool -value demolegacyapp

#>