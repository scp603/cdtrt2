@ECHO OFF

del C:\Users\user\Downloads\final-group9\Server\cli\modules\mimikatz\*.dll
del C:\Users\user\Downloads\final-group9\Server\cli\modules\mimikatz\*.bin

msbuild .\mimikatz.sln /p:configuration=Simple_DLL;Platform=x64 /target:mimikatz
copy x64\mimikatz.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\mimikatz\mimikatz_x64.dll

python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\mimikatz\mimikatz_x64.dll

exit /b 0