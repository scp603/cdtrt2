@ECHO OFF

del C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\*.dll
del C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\*.bin

msbuild .\sRDI-SetPriv.sln /p:configuration=Release;Platform=x64
IF %ERRORLEVEL% NEQ 0 ( 
   goto :Fail
)
copy /Y .\x64\Release\sRDI-SetPriv.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\setpriv_x64.dll

msbuild .\sRDI-SetPriv.sln /p:configuration=Release;Platform=x86
IF %ERRORLEVEL% NEQ 0 ( 
   goto :Fail
)
copy /Y .\Release\sRDI-SetPriv.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\setpriv_x86.dll

python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\setpriv_x64.dll
python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\setpriv\setpriv_x86.dll
exit /b 0

:Fail
echo Failed to compile
exit /b 9993