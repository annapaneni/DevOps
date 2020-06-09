use EnterpriseValidate

IF NOT EXISTS ( SELECT name from sys.syslogins where name = 'ilab-midlandls\xsELMService')  
BEGIN 

create login [ilab-midlandls\xsELMService] from windows 

exec sp_addrolemember N'db_owner', N'ilab-midlandls\xsELMService'
exec sp_addrolemember N'db_datawriter', N'ilab-midlandls\xsELMService'
exec sp_addrolemember N'db_datareader', N'ilab-midlandls\xsELMService'

END
