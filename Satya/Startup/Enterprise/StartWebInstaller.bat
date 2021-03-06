SET "INSTALL_TARGETSERVER=%COMPUTERNAME%"
SET "INSTALL_CONFIG_EXTERNALNATCOMPUTERNAME=%COMPUTERNAME%"
SET "INSTALL_MNEMONIC=ELM"
SET "INSTALL_FOLDER_ROOT=f:\app\%INSTALL_MNEMONIC%"
::SET "INSTALL_ROOTWEBSITE=%INSTALL_MNEMONIC%"
SET "INSTALL_ROOTWEBSITE=Default Web Site"

SET "INSTALL_SETUP_WINDOWS_SERVICES=False"
SET "INSTALL_SETUP_ESFAUTH=False"

SET "INSTALL_ENVR_DESCRIPTION=Azure"
SET "INSTALL_CONFIG_DBNAME=EnterpriseValidate"
SET "INSTALL_CONFIG_DBSERVER=vm-db-rnd"
SET "INSTALL_PRODUCT_INSTANCE=ELM"
::SET "INSTALL_COMPONENT_SUFFIX=elmaz"

SET "INSTALL_CONFIG_REPORTINGSERVICESSERVER=vm-app-rnd"
SET "INSTALL_CONFIG_EXCEPTIONLOGGINGDBNAME=ExceptionLogging"
SET "INSTALL_CONFIG_EXCEPTIONLOGGINGSERVER=vm-db-rnd"
SET "INSTALL_CLIENT_NAME="
SET "INSTALL_CONFIG_NASUsedForIO=False"
SET "INSTALL_CONFIG_SMTP_SERVER=Your_SMTP_EMail_Server"
SET "INSTALL_CONFIG_SMTP_ENABLEEMAIL=False

SET "INSTALL_CONFIG_CSS=pnc-theme-greetingsfeline.css"
SET "INSTALL_CONFIG_DayEndSendQueueName=elmaz"
SET "INSTALL_CONFIG_DayEndSendQueueServer=mySQLVM"
SET "INSTALL_CONFIG_DayEndService_QueueName=elm"
SET "INSTALL_CONFIG_eDayEndService_QueueServer=mySQLVM"
SET "INSTALL_CONFIG_ENABLEDBSERVERTEXTBOX=True"
SET "INSTALL_CONFIG_USERGROUP=ilab-midlandls\Users"
SET "INSTALL_SHORT_DATE_FORMAT=M/d/yyyy"
SET "INSTALL_SVC_ACCT_NAME=xsELMService"

PostDeploy.bat