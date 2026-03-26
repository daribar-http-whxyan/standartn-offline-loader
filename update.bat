@echo off
chcp 65001 >nul
setlocal

set "TMP_EXE=%~1"
set "DIR=%ProgramFiles%\Utochka"

if "%TMP_EXE%"=="" (
    echo ERROR: tmp exe path required
    exit /b 1
)

taskkill /f /im utochka.exe >nul 2>&1
ping -n 6 127.0.0.1 >nul
for /d %%i in ("%TEMP%\_MEI*") do rd /s /q "%%i" >nul 2>&1
move /y "%TMP_EXE%" "%DIR%\utochka.exe"
if %errorlevel% neq 0 (
    echo ERROR: failed to replace exe
    del "%TMP_EXE%" >nul 2>&1
    exit /b 1
)
ping -n 4 127.0.0.1 >nul
explorer.exe "%DIR%\utochka.exe"
del "%~f0"
