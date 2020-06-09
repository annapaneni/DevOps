 $vmName = "vmwebsrv001"
 $rgName = "Midlandls-Core_RG"
 $location = "EastUS2"
 $imageName = "WebServerImage"

 Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force
 Set-AzVm -ResourceGroupName $rgName -Name $vmName -Generalized
 $vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName
 $image = New-AzImageConfig -Location $location -SourceVirtualMachineId $vm.Id
 New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $rgName