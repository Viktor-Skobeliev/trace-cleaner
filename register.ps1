#Requires -Version 5.1
# Registers the "TraceCleaner" task to run Clear-Traces.ps1 at every system startup,
# as SYSTEM with highest privileges. Object-based, so paths with spaces are safe.
# Run elevated (install.bat does this for you).

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'Clear-Traces.ps1'
if (-not (Test-Path $script)) { throw "Clear-Traces.ps1 not found next to register.ps1" }

$arg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}" -IncludeTemp' -f $script
$action    = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
$trigger   = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
                -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 1)

Register-ScheduledTask -TaskName 'TraceCleaner' -Action $action -Trigger $trigger `
    -Principal $principal -Settings $settings -Force | Out-Null

Write-Host 'Installed. TraceCleaner runs at every system startup, as SYSTEM.'
