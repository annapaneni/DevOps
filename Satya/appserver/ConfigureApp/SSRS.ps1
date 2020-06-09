# start the SQL RS downloader
$filepath="$folderpath\SQLServerReportingServices.exe"
if (!(Test-Path $filepath)){
write-host "Downloading SQL Server 2017 Reporting Services..." -nonewline
$URL = "https://download.microsoft.com/download/E/6/4/E6477A2A-9B58-40F7-8AD6-62BB8491EA78/SQLServerReportingServices.exe"
$clnt = New-Object System.Net.WebClient
$clnt.DownloadFile($url,$filepath)
Write-Host "done!" -ForegroundColor Green
}
 else {
write-host "found the SQL RS Installer, no need to download it..."
}
# start the SQL RS installer
write-host "about to install SQL Server 2017 Reporting Services..." -nonewline
$Parms = "  /IAcceptLicenseTerms True /Quiet /Norestart /Log SQLServerReportingServiceslog.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "done!" -ForegroundColor Green
