:: POST Deploy Actions 
:: This script is run by Harvest AFTER installation files are copied


:: ***  This is for the "SSISPackage" installer. Do NOT use for "Enterprise!"  ***


:: INSTALL_ENVR_DESCRIPTION
::		used in the installation and is used for informational purposes only
:: INSTALL_MNEMONIC
::		Mnemonic used for this installation. Used in the default values for the installation website,
::			and installation folder.
:: INSTALL_SETUP_OVERRIDE_CONFIG
::		Determines if the installation process will create and/or update the Override.Config file used by the Enterprise application
:: INSTALL_PRODUCT_VERSION_NO_BUILD_NUMBER
::		Displays the minimum information needed to determine what version of Enterprise is being installed.
::		Currently not used in the installation process, but more an informational variable
::		Example: 20152.3 would be Major Version 2015, minor Version 2, MR 3
:: INSTALL_PRODUCT_VERSION
::		Displays the full build information to determine a specific instance of a build
::		Currently not used in the installation process, but more an informational variable
::		Example: 20153.0.2.768 would be major version 2015, minor version 3, MR 0, HF2, Build 768
:: INSTALL_BUILD_BUILDNUMBER
::		Provides information specific to the build number of this instance
::		Currently not used in the installation process, but more an informational variable
::		Example: using the above example, this value would simply be 768
:: INSTALL_PRODUCT_INSTANCE
::		This is the suffix and folder structure that will be used for the installation. 
::		If set to something such as "ABC", the URL will result in "http://ServerName/EnterpriseABC" with 
::			services/message queues of eDayEndServiceABC and eTranProcServiceABC.  The folder used for installation
::			will be E:\MNEMONIC\ABC.  This folder will then contain the Enterprise, EnterpriseABC_Backup and Install folders
::		If not set or modified, no suffix will be used during the installation resulting in a URL of "http://ServerName/Enterprise" 
::			and services/message queues of eDayEndService and eTranProcService.  Installation folder will be E:\MNEMONIC\ with 
::			all associated folders (Enterprise, backup and install) existing in this folder.
::	INSTALL_CONFIG_DBNAME, INSTALL_CONFIG_DBSERVER, INSTALL_CONFIG_REPORTINGSERVICESSERVER, INSTALL_CONFIG_EXCEPTIONLOGGINGSERVER, INSTALL_CONFIG_PROTOCOL
::		Default values used to populate the MLS.Override.Config file.
::		If not set, ExceptionLoggingServer will default to ReportingServicesServer
::		If not set, ReportingServicesServer will default to the DBServer
:: INSTALL_FOLDER
::		If desired, it is possible to install the application in a non-standard folder location. 
::		This is not recommended, but by setting this folder, it will then contain the actual Enterprise code folder
::			the backup folder and the Install folder.
:: INSTALL_DELETE_OLD_BACKUPS
::		When set to TRUE, no more than one backup folder will be saved at a time. Set to false will delete no backup folders that currently exist.

::Set parameters
IF "%INSTALL_ENVR_DESCRIPTION%" == "" SET "INSTALL_ENVR_DESCRIPTION=DEFAULT"
IF "%INSTALL_MNEMONIC%" == "" SET "INSTALL_MNEMONIC=EKA"
SET "INSTALL_SETUP_OVERRIDE_CONFIG=True"
IF "%INSTALL_SETUP_WEB_CONFIG%" == "" SET "INSTALL_SETUP_WEB_CONFIG=True"
SET "INSTALL_PRODUCT_VERSION_NO_BUILD_NUMBER=20180.2"
SET "INSTALL_PRODUCT_VERSION="20180.2.0.4932"
SET "INSTALL_BUILD_BUILDNUMBER=4932"
IF "%INSTALL_PRODUCT_INSTANCE%" == "" SET "INSTALL_PRODUCT_INSTANCE=UNSET"
IF "%INSTALL_CONFIG_PROTOCOL%" == "" SET "INSTALL_CONFIG_PROTOCOL=http"
IF "%INSTALL_CONFIG_REPORTINGSERVICESSERVER%" == "" SET "INSTALL_CONFIG_REPORTINGSERVICESSERVER=wmelm000d"
IF "%INSTALL_FOLDER%" == "" SET "INSTALL_FOLDER=UNSET"
SET "INSTALL_DELETE_OLD_BACKUPS=True"
SET "INSTALL_RUN_SINGLE_EXE=True"

IF "%INSTALL_BACKUP_EXISTING%" == "" SET "INSTALL_BACKUP_EXISTING=True"
IF "%INSTALL_DAYS_TO_KEEP_BACKUPS%" == "" (
	IF "%USERDOMAIN%" == "PNCRND" SET "INSTALL_DAYS_TO_KEEP_BACKUPS=5"
	IF "%USERDOMAIN%" == "PNCUAT" SET "INSTALL_DAYS_TO_KEEP_BACKUPS=10"
	IF "%USERDOMAIN%" == "PNCQA" SET "INSTALL_DAYS_TO_KEEP_BACKUPS=90"
	IF "%USERDOMAIN%" == "PNCPROD" SET "INSTALL_DAYS_TO_KEEP_BACKUPS=180"
)

if NOT "%INSTALL_ENVR_DESCRIPTION%" == "DEFAULT" goto :install

:: COMPUTER NAME MUST BE ALL UPPER CASE TO WORK CORRECTLY

if "%COMPUTERNAME%" == "GFB_Test_Server_Name_Here" (
	SET "INSTALL_ENVR=%COMPUTERNAME%"
	::SET "INSTALL_PRODUCT_INSTANCE=%INSTALL_PRODUCT_VERSION_NO_BUILD_NUMBER%"
	SET "INSTALL_PRODUCT_INSTANCE=2015.3"
	
	SET "INSTALL_CONFIG_REPORTINGSERVICESSERVER="

	goto :install
)

::Error BAT file is not coded for this server
set ERRORTEXT=Not supported server %COMPUTERNAME% for enviroment %INSTALL_ENVR_DESCRIPTION%
@echo %ERRORTEXT%
EXIT /B 1
goto :end

:install
IF "%INSTALL_FOLDER_ROOT%" == "" SET "INSTALL_FOLDER_ROOT=E:\APPS\%INSTALL_MNEMONIC%"
IF "%INSTALL_FOLDER%" == "UNSET" IF "%INSTALL_PRODUCT_INSTANCE%" == "UNSET" (
	SET "INSTALL_FOLDER=%INSTALL_FOLDER_ROOT%\SSIS"
)
IF "%INSTALL_FOLDER%" == "UNSET" (
	SET "INSTALL_FOLDER=%INSTALL_FOLDER_ROOT%\SSIS\%INSTALL_PRODUCT_INSTANCE%"
)

IF "%INSTALL_CONFIG_PrimaryNASHostName%" == "" SET "INSTALL_CONFIG_PrimaryNASHostName=E:\NAS_Storage\%INSTALL_MNEMONIC%_share_01"
IF "%INSTALL_CONFIG_PrimaryNASHostShareName%" == "" SET "INSTALL_CONFIG_PrimaryNASHostShareName=%INSTALL_MNEMONIC%_AppRun"

@ECHO XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
@ECHO INSTALL_CONFIG_DBNAME.........:  %INSTALL_CONFIG_DBNAME%
@ECHO INSTALL_CONFIG_DBSERVER........: %INSTALL_CONFIG_DBSERVER%
@ECHO INSTALL_PRODUCT_INSTANCE.......: %INSTALL_PRODUCT_INSTANCE%
@ECHO INSTALL_FOLDER.................: %INSTALL_FOLDER%
@ECHO INSTALL_ENVR_DESCRIPTION.......: %INSTALL_ENVR_DESCRIPTION%
@ECHO XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

@ECHO Installing %INSTALL_ENVR_DESCRIPTION% server %COMPUTERNAME%  

::Start installation
if NOT "%EXECUTION_FOLDER%" == "" (
	%EXECUTION_FOLDER%\SSISPackage_Install.exe "INSTALL_PRODUCT_NAME=SSISPackage" DEBUG=False
) else (
SSISPackage_Install.exe "INSTALL_PRODUCT_NAME=SSISPackage" DEBUG=False
)

@if NOT %ERRORLEVEL% == 0 (
	@echo ERROR: Install step exited with code=%ERRORLEVEL%
	::Pass it back  to caller
	EXIT /B %ERRORLEVEL%
)    

:end