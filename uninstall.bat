@echo off
rem Removes the TraceCleaner startup task. Leaves the scripts in place.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

schtasks /Delete /TN "TraceCleaner" /F
echo.
echo Removed the startup task. The scripts and logs are untouched.
pause
