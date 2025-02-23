@echo off

REM Remove any existing files in the 'web' folder
rmdir /s /q web

REM Create the 'web' folder again
mkdir web

REM Copy contents from 'build/web' to 'web'
xcopy /e /i /h /r /y build\web\* web\

echo Build and copy process completed.
pause
