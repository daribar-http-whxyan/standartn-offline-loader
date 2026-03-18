@echo off
setlocal

set "DIR=C:\Daribar\standartn-offline"
set "EXE=%DIR%\standartn-offline.exe"
set "CFG=%DIR%\config.toml"
set "REG=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

echo [1/5] Creating %DIR% ...
if not exist "%DIR%" mkdir "%DIR%"

echo [2/5] Downloading standartn-offline.exe ...
curl.exe -Lo "%EXE%" https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/main/standartn-offline.exe
if %errorlevel% neq 0 (
    echo ERROR: failed to download exe
    pause
    exit /b 1
)

echo [3/5] Downloading config.toml ...
if exist "%CFG%" (
    echo config.toml already exists, skipping
    goto step4
)
curl.exe -Lo "%CFG%" https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/main/config.example.toml
if %errorlevel% neq 0 (
    echo ERROR: failed to download config
    pause
    exit /b 1
)

:step4
echo [4/5] Adding to startup ...
reg add "%REG%" /v "StandartnOffline" /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1

echo [5/5] Starting standartn-offline.exe ...
start "" "%EXE%"

echo.
echo Done!
echo   EXE: %EXE%
echo   Config: %CFG%
echo.
echo Edit config.toml - set token and pharmacy_code.
pause
