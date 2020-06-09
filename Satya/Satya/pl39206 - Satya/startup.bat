PowerShell -Command "Set-ExecutionPolicy Unrestricted" >> "%TEMP%\StartupLog.txt" 2>&1
PowerShell C:\Support\test.ps1 >> "%TEMP%\StartupLog.txt" 2>&1