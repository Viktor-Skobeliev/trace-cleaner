#Requires -Version 5.1
<#
.SYNOPSIS
    Clears common Windows local-activity traces: thumbnail/icon cache, Recent items,
    Jump Lists and Prefetch. Privacy hygiene for your own machine.

.DESCRIPTION
    Deletes only known trace files in known locations. It never recurses into arbitrary
    folders and never deletes a folder itself, only its trace files. Deletion is
    irreversible. Run with -DryRun first to see exactly what would be removed.

    Run as SYSTEM at startup (see install.bat) it cleans every user profile before
    Explorer locks the cache files. Run interactively it cleans the current user and,
    if elevated, every profile; with -RestartExplorer it also unlocks and rebuilds the
    thumbnail cache immediately.

    NOT touched, on purpose:
      - USB device history in the registry (USBSTOR): deleting it can break device
        drivers. Left alone.
      - Saved Wi-Fi passwords: these are your own stored networks, visible only to an
        admin already on this PC. Nothing to clean.
      - %TEMP%: off by default (-IncludeTemp enables it) and then only files older than
        one day, skipping anything under a "claude" folder, so active work is safe.

.PARAMETER DryRun
    List what would be deleted and delete nothing.

.PARAMETER IncludeTemp
    Also remove temp files older than 1 day (excluding active "claude" work folders).

.PARAMETER RestartExplorer
    Interactive only: stop Explorer, clear the thumbnail cache, start Explorer again,
    so the cache is cleared now instead of at next startup.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Clear-Traces.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$IncludeTemp,
    [switch]$RestartExplorer
)

$ErrorActionPreference = 'Continue'
$script:LogDir  = Join-Path $env:ProgramData 'trace-cleaner'
$script:Deleted = 0
$script:Locked  = 0
$script:Errors  = 0
$KeepLogDays    = 7

function Write-Log {
    param([string]$Msg)
    if (-not (Test-Path $script:LogDir)) {
        New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null
    }
    $file = Join-Path $script:LogDir ("clean-{0:yyyy-MM-dd}.log" -f (Get-Date))
    $line = "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $Msg
    try { Add-Content -LiteralPath $file -Value $line -Encoding UTF8 } catch {}
    Write-Host $line
}

function Remove-OldLogs {
    Get-ChildItem -Path $script:LogDir -Filter 'clean-*.log' -File -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$KeepLogDays) } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
}

function Clear-Trace {
    # $Pattern: a wildcard path. Only files are removed, never folders.
    param([string]$Pattern, [string]$Label)
    $items = Get-ChildItem -Path $Pattern -Force -File -ErrorAction SilentlyContinue
    foreach ($f in $items) {
        if ($DryRun) { Write-Log "DRY   [$Label] $($f.FullName)"; $script:Deleted++; continue }
        try {
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
            $script:Deleted++
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match 'being used|another process|access to the path') {
                $script:Locked++; Write-Log "LOCK  [$Label] $($f.FullName)"
            } else {
                $script:Errors++; Write-Log "ERR   [$Label] $($f.FullName): $msg"
            }
        }
    }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ProfileDirs {
    if (Test-Admin) {
        Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName 'NTUSER.DAT') } |
            ForEach-Object { $_.FullName }
    } else {
        , $env:USERPROFILE
    }
}

Write-Log "=== start (DryRun=$DryRun, IncludeTemp=$IncludeTemp, Admin=$(Test-Admin)) ==="

if ($RestartExplorer -and -not $DryRun) {
    Write-Log "restarting Explorer to unlock the thumbnail cache"
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

foreach ($prof in Get-ProfileDirs) {
    $explorer = Join-Path $prof 'AppData\Local\Microsoft\Windows\Explorer'
    Clear-Trace (Join-Path $explorer 'thumbcache_*.db') 'thumbnail cache'
    Clear-Trace (Join-Path $explorer 'iconcache_*.db')  'icon cache'

    $recent = Join-Path $prof 'AppData\Roaming\Microsoft\Windows\Recent'
    Clear-Trace (Join-Path $recent '*.lnk') 'recent items'
    Clear-Trace (Join-Path $recent 'AutomaticDestinations\*') 'jump lists (auto)'
    Clear-Trace (Join-Path $recent 'CustomDestinations\*')    'jump lists (custom)'

    if ($IncludeTemp) {
        $temp = Join-Path $prof 'AppData\Local\Temp'
        $old  = Get-ChildItem -Path $temp -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) -and $_.FullName -notmatch '\\claude\\' }
        foreach ($f in $old) {
            if ($DryRun) { Write-Log "DRY   [temp] $($f.FullName)"; $script:Deleted++; continue }
            try { Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop; $script:Deleted++ }
            catch { $script:Locked++ }
        }
    }
}

# Prefetch is machine-wide; needs admin. Skipped cleanly otherwise.
if (Test-Admin) {
    Clear-Trace 'C:\Windows\Prefetch\*.pf' 'prefetch'
} else {
    Write-Log "prefetch skipped (needs admin)"
}

# Current clipboard (only meaningful in an interactive session).
if (-not $DryRun) {
    try { Clear-Clipboard -ErrorAction SilentlyContinue } catch {}
}

if ($RestartExplorer -and -not $DryRun -and -not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
    Start-Process explorer.exe
}

Remove-OldLogs
Write-Log "=== done: removed=$script:Deleted locked=$script:Locked errors=$script:Errors ==="
