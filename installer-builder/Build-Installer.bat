@echo off
setlocal
cd /d "%~dp0"
echo ================================================
echo       KODARA Studio Code - Installer Builder
echo ================================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Installer.ps1"
set "BUILD_EXIT=%ERRORLEVEL%"
if not "%BUILD_EXIT%"=="0" (
  echo.
  echo Installer build failed. Review the message above.
)
echo.
pause
exit /b %BUILD_EXIT%
