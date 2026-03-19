@echo off                                                                                                                                                                                     
  chcp 65001 >nul                
  setlocal                                                                                                                                                                                      
                                                                                                                                                                                                
  set "DIR=C:\Daribar\standartn-offline"                                                                                                                                                        
  set "EXE=%DIR%\standartn-offline.exe"                                                                                                                                                         
  set "CFG=%DIR%\config.toml"                                                                                                                                                                   
  set "REG=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"                                                                                                                                  

  echo [1/6] Creating %DIR% ...
  if not exist "%DIR%" mkdir "%DIR%"

  echo [2/6] Installing VC++ Runtime ...
  curl.exe -Lo "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
  "%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
  del "%TEMP%\vc_redist.x64.exe" >nul 2>&1

  echo [3/6] Downloading standartn-offline.exe ...
  curl.exe -Lo "%EXE%" https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/main/standartn-offline.exe
  if %errorlevel% neq 0 (
      echo ERROR: failed to download exe
      pause
      exit /b 1
  )

  echo [4/6] Downloading config.toml ...
  if exist "%CFG%" (
      echo config.toml already exists, skipping
      goto step5
  )
  curl.exe -Lo "%CFG%" https://raw.githubusercontent.com/daribar-http-whxyan/standartn-offline-loader/main/config.example.toml
  if %errorlevel% neq 0 (
      echo ERROR: failed to download config
      pause
      exit /b 1
  )

  :step5
  echo [5/6] Adding to startup ...
  reg add "%REG%" /v "StandartnOffline" /t REG_SZ /d "\"%EXE%\"" /f >nul 2>&1

  echo [6/6] Starting standartn-offline.exe ...
  start "" "%EXE%"

  echo.
  echo Done!
  echo   EXE: %EXE%
  echo   Config: %CFG%
  echo.
  echo Edit config.toml - set token and pharmacy_code.
  pause
