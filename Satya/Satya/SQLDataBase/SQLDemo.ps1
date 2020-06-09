clear
$servername = vm-db-iLAB

Invoke-Sqlcmd -InputFile "/SQLDataBase/EnterpriseValidate.sql" -ServerInstance $Servername -QueryTimeout '500'

Invoke-Sqlcmd -InputFile "/SQLDataBase/SQLLogin.sql" -ServerInstance $Servername -QueryTimeout '500'