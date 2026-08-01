@echo off
setlocal
title Pokemon Red Blue Yellow Voxel - VR
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-vr.ps1" %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo The VR launcher stopped with code %EXITCODE%.
    pause
)

exit /b %EXITCODE%
