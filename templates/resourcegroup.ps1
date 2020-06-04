$resource = "Satya"

Set-Content -Path "C:\Support\ResourceGroup.txt" -Value $resource

$resourcegroup = Get-Content -Path "C:\Support\ResourceGroup.txt"

$resourcegroup

