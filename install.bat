@echo off
rem Registers Clear-Traces.ps1 to run at every system startup, as SYSTEM.
rem Re-launches itself elevated if not already running as administrator.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT=%~dp0Clear-Traces.ps1"
if not exist "%SCRIPT%" (
    echo Clear-Traces.ps1 not found next to this installer.
    pause
    exit /b 1
)

schtasks /Create /TN "TraceCleaner" /SC ONSTART /RU SYSTEM /RL HIGHEST /F /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%SCRIPT%\" -IncludeTemp"

if %errorlevel% equ 0 (
    echo.
    echo Installed. The cleaner runs at every startup, before Explorer loads.
    echo To clean once now:  powershell -ExecutionPolicy Bypass -File "%SCRIPT%" -RestartExplorer
    echo To remove:          uninstall.bat
) else (
    echo Failed to create the scheduled task.
)
pause
