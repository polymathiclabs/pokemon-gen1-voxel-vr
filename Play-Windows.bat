@echo off
setlocal
title Pokemon Red Blue Yellow Voxel - Desktop
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-desktop.ps1" %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo The desktop launcher stopped with code %EXITCODE%.
    pause
)

exit /b %EXITCODE%
