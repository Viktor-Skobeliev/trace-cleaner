# trace-cleaner

A small PowerShell tool that clears common Windows local-activity traces on **your own
machine**: thumbnail and icon cache, Recent items, Jump Lists and Prefetch. It can run
once by hand or automatically at every system startup.

Deletion is **irreversible**. Run with `-DryRun` first to see exactly what it targets.

## What it cleans

| Trace | Location |
|---|---|
| Thumbnail cache (`thumbcache_*.db`) | `%LOCALAPPDATA%\Microsoft\Windows\Explorer` |
| Icon cache (`iconcache_*.db`) | same |
| Recent items (`*.lnk`) | `%APPDATA%\Microsoft\Windows\Recent` |
| Jump Lists | `...\Recent\AutomaticDestinations`, `...\CustomDestinations` |
| Prefetch (`*.pf`) | `C:\Windows\Prefetch` (needs admin) |
| Current clipboard | cleared on a real run |

Run as SYSTEM at startup, it cleans every user profile before Explorer locks the cache
files. Run by hand, it cleans the current user (and every profile if elevated).

## What it does NOT touch, on purpose

- **USB device history in the registry** (`USBSTOR`): deleting those keys can break
  device drivers, so it is left alone.
- **Saved Wi-Fi passwords**: these are your own stored networks, readable only by an
  administrator already on the PC. Nothing to clean.
- **`%TEMP%`**: off by default. `-IncludeTemp` enables it, and then only files older
  than one day are removed, skipping anything under a `claude` folder so active work is
  safe.

This is privacy hygiene, not anti-forensics: caches are regenerated as you use Windows,
and manual cleanup cannot remove every system trace. For real protection of a lost or
stolen machine, use full-disk encryption (BitLocker).

## Use

Dry run (deletes nothing, just lists):

```
powershell -ExecutionPolicy Bypass -File .\Clear-Traces.ps1 -DryRun
```

Clean once now, including the locked thumbnail cache (restarts Explorer):

```
powershell -ExecutionPolicy Bypass -File .\Clear-Traces.ps1 -RestartExplorer
```

Install the startup task (auto-elevates):

```
install.bat
```

Remove it:

```
uninstall.bat
```

## Logs

`%ProgramData%\trace-cleaner\clean-YYYY-MM-DD.log`, kept for 7 days.

## License

MIT. Use at your own risk; the author is not liable for any data loss.
