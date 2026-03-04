@ECHO OFF

del C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\*.dll
del C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\*.bin

msbuild .\GDI-ScreenShot.sln /p:configuration=Release;Platform=x64
copy C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\proj\x64\Release\GDI-Screenshot.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\screenshot_x64.dll

msbuild .\GDI-ScreenShot.sln /p:configuration=Release;Platform=x86
copy C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\proj\Release\GDI-Screenshot.dll C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\screenshot_x86.dll

python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\screenshot_x64.dll
python C:\Users\user\Downloads\final-group9\Server\cli\modules\Python\ConvertToShellcode.py C:\Users\user\Downloads\final-group9\Server\cli\modules\screenshot\screenshot_x86.dll
exit /b 0