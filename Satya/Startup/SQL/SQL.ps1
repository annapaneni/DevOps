Import-Module "sqlps" -DisableNameChecking  

cls

$SQLServer = "vm-db-RND.ilab.midlandls.com"
$SQLDBName = "tempdb"
$uid ="pncpnc123"
$pwd = "pncpnc@12345"
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True; User ID = $uid; Password = $pwd;"

$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlQuery = "SELECT * from TestTable;"
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)

$DataSet.Tables[0] | out-file "H:\Satya.csv"

create login ilab-midlandls\pl39260 from windows
Go
sp_addrolemember @rolename='db_datawriter', @membername='ilab-midlandls\pl39260'