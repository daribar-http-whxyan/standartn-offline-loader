@echo off                                                                                                                                                                                     
chcp 65001 >nul
set BRANCH=%~1                                                                                                                                                                                
if "%BRANCH%"=="" set BRANCH=main
set DIR=C:\Daribar\standartn-offline                                                                                                                                                          
set REPO=https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader
timeout /t 3 /nobreak >nul
curl.exe -Lo "%DIR%\standartn-offline.exe" "%REPO%/%BRANCH%/standartn-offline.exe"
for /d %%i in ("%TEMP%\_MEI*") do rd /s /q "%%i" >nul 2>&1
start "" "%DIR%\standartn-offline.exe"
del "%~f0"
