@echo off
rem Registers Clear-Traces.ps1 to run at every system startup, as SYSTEM.
rem Re-launches itself elevated if not already running as administrator.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register.ps1"
if %errorlevel% neq 0 (
    echo Failed to register the task.
) else (
    echo To clean once now:  powershell -ExecutionPolicy Bypass -File "%~dp0Clear-Traces.ps1" -IncludeTemp -RestartExplorer
    echo To remove:          uninstall.bat
)
pause
