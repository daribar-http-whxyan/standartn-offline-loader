@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "DIR=%ProgramFiles%\Utochka"
set "EXE=%DIR%\utochka.exe"
set "CFG=%DIR%\config.toml"
set "TMP_VER=%TEMP%\utochka_version.json"
set "REG=HKLM\Software\Microsoft\Windows\CurrentVersion\Run"

set "ENV=dev"
set "API=https://backoffice.daribar.com/api/internal/offline-applier/updater"
set "BRANCH=dev"
set "APP_VERSION=1.0.0"

echo === utochka: install ===
echo.

:: --- Ввод параметров ---
set /p "TOKEN=Token: "
if "%TOKEN%"=="" (
    echo ERROR: token is required
    pause
    exit /b 1
)

echo.
echo   env=%ENV%
echo.

:: --- [1/7] Проверка токена ---
echo [1/7] Checking token...
curl.exe -sf -X POST -H "Content-Type: application/json" ^
    -d "{\"version\":\"%APP_VERSION%\",\"data\":{\"token\":\"%TOKEN%\"}}" ^
    "%API%/version?env=%ENV%" -o "%TMP_VER%"
if %errorlevel% neq 0 (
    echo ERROR: invalid token or server unavailable
    pause
    exit /b 1
)
echo       OK

:: --- [2/7] Создание директории ---
echo [2/7] Creating %DIR% ...
if not exist "%DIR%" mkdir "%DIR%"

:: --- [3/7] VC++ Runtime ---
echo [3/7] Installing VC++ Runtime ...
curl.exe -Lo "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
"%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
del "%TEMP%\vc_redist.x64.exe" >nul 2>&1

:: --- [4/7] Скачивание EXE ---
echo [4/7] Downloading utochka.exe ...
curl.exe -f -X POST -H "Content-Type: application/json" ^
    -d "{\"version\":\"%APP_VERSION%\",\"data\":{\"token\":\"%TOKEN%\"}}" ^
    -o "%EXE%" "%API%/download?env=%ENV%"
if %errorlevel% neq 0 (
    echo ERROR: failed to download exe
    pause
    exit /b 1
)

:: --- [5/7] SHA256 проверка ---
echo [5/7] Verifying SHA256 ...

:: Получить хэш скачанного файла (вторая строка вывода certutil)
set "ACTUAL_HASH="
for /f "skip=1" %%h in ('certutil -hashfile "%EXE%" SHA256') do (
    if not defined ACTUAL_HASH set "ACTUAL_HASH=%%h"
)

:: Получить ожидаемый хэш из manifest JSON
for /f "usebackq" %%h in (`powershell -NoProfile -Command "(Get-Content '%TMP_VER%' | ConvertFrom-Json).sha256"`) do (
    set "EXPECTED_HASH=%%h"
)

if /i not "!ACTUAL_HASH!"=="!EXPECTED_HASH!" (
    echo ERROR: SHA256 mismatch!
    echo   expected: !EXPECTED_HASH!
    echo   actual:   !ACTUAL_HASH!
    del "%EXE%" >nul 2>&1
    del "%TMP_VER%" >nul 2>&1
    pause
    exit /b 1
)
echo       OK

:: --- [6/7] Config ---
echo [6/7] Creating config.toml ...
if exist "%CFG%" (
    echo       config.toml already exists, skipping
    goto step7
)
curl.exe -Lo "%CFG%" https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/%BRANCH%/config.example.toml
if %errorlevel% neq 0 (
    echo ERROR: failed to download config
    pause
    exit /b 1
)
:: Подставить токен и env
powershell -NoProfile -Command ^
    "(Get-Content '%CFG%') -replace 'your-token-here','%TOKEN%' -replace 'env = \"dev\"','env = \"%ENV%\"' | Set-Content '%CFG%'"

:step7
:: --- [7/7] Автозагрузка + запуск ---
echo [7/7] Adding to startup and launching ...
reg add "%REG%" /v "Utochka" /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1
start "" "%EXE%"

echo.
echo Done!
echo   EXE:    %EXE%
echo   Config: %CFG%
echo   Env:    %ENV%
echo.
echo Edit config.toml: set pharmacy_code.
del "%TMP_VER%" >nul 2>&1
pause
