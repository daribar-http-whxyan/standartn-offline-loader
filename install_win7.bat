@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set "DIR=C:\Open-Sources\Utochka-D"
set "EXE=%DIR%\utochka.exe"
set "CFG=%DIR%\config.toml"
set "TMP_VER=%TEMP%\utochka_version.json"
set "REG=HKLM\Software\Microsoft\Windows\CurrentVersion\Run"

set "ENV=prod"
set "API=https://prod-backoffice.daribar.com/api/internal/offline-applier/updater"
set "BRANCH=main"
set "APP_VERSION=1.5.0"

echo === utochka: install (Windows 7) ===
echo.

:: --- Проверка TLS 1.2 ---
echo Checking TLS 1.2 support...
powershell -NoProfile -Command ^
    "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072 } catch { exit 1 }"
if %errorlevel% neq 0 (
    echo.
    echo ERROR: TLS 1.2 is not supported on this system.
    echo.
    echo To fix this you need to:
    echo   1. Install .NET Framework 4.5+
    echo      https://www.microsoft.com/en-us/download/details.aspx?id=30653
    echo   2. Install Windows update KB3140245 for TLS 1.2 in WinHTTP
    echo      https://support.microsoft.com/en-us/topic/kb3140245
    echo   3. Reboot and run this installer again
    echo.
    pause
    exit /b 1
)
echo       OK
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
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072;" ^
    "$body = '{\"version\":\"%APP_VERSION%\",\"data\":{\"token\":\"%TOKEN%\"}}';" ^
    "try {" ^
    "  $wc = New-Object Net.WebClient;" ^
    "  $wc.Headers.Add('Content-Type','application/json');" ^
    "  $resp = $wc.UploadString('%API%/version?env=%ENV%', $body);" ^
    "  [IO.File]::WriteAllText('%TMP_VER%', $resp);" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"
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
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072;" ^
    "(New-Object Net.WebClient).DownloadFile('https://aka.ms/vs/17/release/vc_redist.x64.exe', '%TEMP%\vc_redist.x64.exe')"
if %errorlevel% neq 0 (
    echo WARNING: failed to download VC++ Runtime, skipping
    goto step4
)
"%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
del "%TEMP%\vc_redist.x64.exe" >nul 2>&1

:step4
:: --- [4/7] Скачивание EXE ---
echo [4/7] Downloading utochka.exe ...
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072;" ^
    "$body = '{\"version\":\"%APP_VERSION%\",\"data\":{\"token\":\"%TOKEN%\"}}';" ^
    "try {" ^
    "  $wc = New-Object Net.WebClient;" ^
    "  $wc.Headers.Add('Content-Type','application/json');" ^
    "  $resp = $wc.UploadData('%API%/download?env=%ENV%', [Text.Encoding]::UTF8.GetBytes($body));" ^
    "  [IO.File]::WriteAllBytes('%EXE%', $resp);" ^
    "} catch { Write-Host $_.Exception.Message; exit 1 }"
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

:: Получить ожидаемый хэш из manifest JSON (без ConvertFrom-Json для совместимости с PS 2.0)
for /f "usebackq" %%h in (`powershell -NoProfile -Command "$c = [IO.File]::ReadAllText('%TMP_VER%'); if ($c -match '\"sha256\"\s*:\s*\"([a-fA-F0-9]+)\"') { $matches[1] } else { exit 1 }"`) do (
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
powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]3072;" ^
    "(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/%BRANCH%/config.example.toml', '%CFG%')"
if %errorlevel% neq 0 (
    echo ERROR: failed to download config
    pause
    exit /b 1
)
:: Подставить токен
powershell -NoProfile -Command ^
    "(Get-Content '%CFG%') -replace 'your-token-here','%TOKEN%' | Set-Content '%CFG%'"

:step7
:: --- [7/7] Автозагрузка + запуск ---
echo [7/7] Adding to startup and launching ...
reg add "%REG%" /v "Utochka" /t REG_SZ /d "\"C:\Open-Sources\Utochka-D\utochka.exe\"" /f >nul 2>&1
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
