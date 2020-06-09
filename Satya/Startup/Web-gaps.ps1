
    #Install URL Rewrite module 
    Start-Process -FilePath "C:\Support\rewrite_amd64.msi" -ArgumentList '/quiet' -Wait

    #Service Account "xsElmService" add to IIS_IUSRS group 
    Add-LocalGroupMember -Group "IIS_IUSRS" -Member "ilab-midlandls\xsElmService"

    #create app folder on data disk
    $appdir = "F:\App"
    mkdir $appdir

    #give IIS_IUSRS access to app folder Read & execute, List folder contents, Read
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("BUILTIN\IIS_IUSRS", "ReadAndExecute", "Synchronize", "Allow")
    $acl = Get-ACL "F:\App"
    $acl.AddAccessRule($accessRule)
    Set-ACL -Path $appdir -ACLObject $acl

    #IIS - set logs to f:\logs\iis
    $logdir = "f:\logs\iis"
    mkdir $logdir 
    Import-Module WebAdministration
    Set-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory -value $logdir