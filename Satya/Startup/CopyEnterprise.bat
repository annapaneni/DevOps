cd\
cd "Support\"
.\azcopy.exe copy https://midlandstor.blob.core.windows.net/builds "F:\App\Enterprise" --recursive

cd\
F:
cd "F:\App\Enterprise\builds\20180.2.0.4932\Enterprise Installer"

timeout /t 30
StartWebInstaller.bat