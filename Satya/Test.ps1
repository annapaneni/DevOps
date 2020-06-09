$DBServer=$args[0]
$AppServer=$args[1]
$Domain=$args[2]
$Account=$args[3]
$ServiceAccount = $args[2]+"\"+$args[3]

   $outarray = ""
   $outarray +=$DBServer+" " 
   $outarray +=$AppServer+" " 
   $outarray +=$Domain+" " 
   $outarray +=$Account+" " 
 $outarray +=$ServiceAccount

#$outarray | out-file -filepath C:\MyTextFile.txt -append -width 200

Set-Content -Path "C:\Support\MyTextFile.txt" -Value $outarray -Force