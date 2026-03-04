@ECHO OFF

del C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\*.dll
del C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\*.bin

msbuild .\sRDI-ListPrivs.sln /p:configuration=Release;Platform=x64
IF %ERRORLEVEL% NEQ 0 ( 
   goto :Fail
)
copy /Y .\x64\Release\sRDI-ListPrivs.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\listprivs_x64.dll

msbuild .\sRDI-ListPrivs.sln /p:configuration=Release;Platform=x86
IF %ERRORLEVEL% NEQ 0 ( 
   goto :Fail
)
copy /Y .\Release\sRDI-ListPrivs.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\listprivs_x86.dll

python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\listprivs_x64.dll
python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\listprivs\listprivs_x86.dll
exit /b 0

:Fail
echo Failed to compile
exit /b 0