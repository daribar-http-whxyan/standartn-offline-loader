@echo off
chcp 65001 >nul
set BRANCH=%~1
if "%BRANCH%"=="" set BRANCH=main
set DIR=C:\Daribar\standartn-offline
set REPO=https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader
taskkill /f /im standartn-offline.exe >nul 2>&1
ping -n 6 127.0.0.1 >nul
for /d %%i in ("%TEMP%\_MEI*") do rd /s /q "%%i" >nul 2>&1
curl.exe -Lo "%DIR%\standartn-offline.exe" "%REPO%/%BRANCH%/standartn-offline.exe"
if %errorlevel% neq 0 (
  echo ERROR: download failed
  exit /b 1
)
(
  echo @echo off
  echo ping -n 4 127.0.0.1 ^>nul
  echo start "" "%DIR%\standartn-offline.exe"
  echo ping -n 3 127.0.0.1 ^>nul
  echo del "%%~f0"
) > "%DIR%\launcher.bat"
start /min "" "%DIR%\launcher.bat"
(goto) 2>nul & del "%~f0"
