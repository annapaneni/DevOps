use EnterpriseValidate

declare @serviceAccount nvarchar(50) = N'ilab-midlandls\xsELMService';
declare @cmd nvarchar(200);

IF NOT EXISTS ( SELECT name from sys.syslogins where name = @serviceAccount)  
BEGIN 

	set @cmd = N'create login [' + @serviceAccount + '] from windows'
	PRINT @cmd

	exec sp_executesql @cmd

END

exec sp_addrolemember N'db_owner', @serviceAccount
exec sp_addrolemember N'db_datawriter', @serviceAccount
exec sp_addrolemember N'db_datareader', @serviceAccount

GO