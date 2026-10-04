# OpenCode Keep-Awake Design — 2026-09-18

## Goal
While an OpenCode chat is actively working, Windows must not enter sleep
(S3/S4/modern standby) so long tasks keep running. Screen-off is allowed.
When OpenCode work ends, normal sleep behavior resumes.

## Decisions (user-confirmed)
- Active definition: only when working (not merely installed).
- Mode: background watcher, auto-start.
- Power: AC only (allow normal sleep on battery).

## Context (verified 2026-09-19 local)
- OS: Windows 11 Pro 64-bit, Balanced scheme.
- Sleep after: 15 min AC + DC (`STANDBYIDLE` 0x384).
- Display off: 10 min AC, 3 min DC.
- `opencode.exe` observed running; live state DB (`opencode.db`, `-wal`
  with fresh writes) at `%USERPROFILE%\.local\share\opencode\`.
  The watcher scans both `%USERPROFILE%\.local\share\opencode\` and
  `%USERPROFILE%\.config\opencode\` for `opencode.db*` (config dir holds
  config files only).

## Approach (chosen: A — activity watcher)
Use `SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED)` re-asserted
periodically while working; deliberately omit `ES_DISPLAY_REQUIRED` so the
display may still turn off. Clear with `ES_CONTINUOUS` alone when idle so
sleep timers resume. No `powercfg` timeout changes.

Rejected:
- B (pure process watcher): blocks sleep even when opencode idle overnight.
- C (hook → lock file): most precise but depends on opencode hook support;
  keep as future upgrade.

## Architecture
Single per-user background PowerShell watcher launched at logon via
Scheduled Task `OpenCodeKeepAwake`, running hidden with lowest priority.

## Components
- `opencode-keepawake.ps1` — watcher loop (params: IdleMinutes=10,
  PollSeconds=30, LogPath). P/Invoke `kernel32!SetThreadExecutionState`.
- `Install-OpenCodeKeepAwake.ps1` — creates/updates logon Scheduled Task
  (no admin), starts watcher immediately.
- `Uninstall-OpenCodeKeepAwake.ps1` — removes task, stops watcher, releases
  execution state.
- Log file: `%USERPROFILE%\.config\opencode\keep-awake\keepawake.log`.
- Install location: `%USERPROFILE%\.config\opencode\keep-awake\`
  (system-wide; not in project Downloads folder).

## Data flow / blocking condition (all must hold)
1. On AC power (`Get-CimInstance Win32_Battery` absent or `BatteryStatus`
   indicates AC / `powercfg` AC online).
2. `Get-Process opencode` returns ≥1 process.
3. Any `opencode.db`, `opencode.db-wal`, `opencode.db-shm` mtime within
   `IdleMinutes` (default 10), scanning both
   `%USERPROFILE%\.local\share\opencode\` and
   `%USERPROFILE%\.config\opencode\` (newest mtime wins).
If true → assert `ES_CONTINUOUS | ES_SYSTEM_REQUIRED` each poll while
blocking; log transitions only. If false → call `ES_CONTINUOUS` once to
release; log. `try/finally` releases on exit. If no `opencode.db*` in
either dir → treat as idle (RELEASE) + WARN log; never block on
process alone.

## Error handling
- Never modifies sleep/display timeouts.
- Missing DB dir or DB access errors → treat as idle (RELEASE) + WARN
  log, never block on process alone; battery status failure → assume AC
  + log warning; never crash loop.
- Single instance via named mutex; second start exits.
- Dry-run switch `-WhatIf`-style logging of would-block without API call.

## Testing
- Dry run: log shows BLOCK/RELEASE transitions correctly.
- Live: run watcher, confirm `powercfg /REQUESTS` (elevated) shows SYSTEM
  request from PowerShell while blocking; wait for display-off timeout and
  confirm screen turns off while task continues.
- Release: close opencode / wait > IdleMinutes / unplug AC → request clears
  and `powercfg` sleep timers resume.
- Install: logoff/logon restarts task; uninstall removes task and releases.

## Scope
Single-user Windows 11 helper. No admin, no third-party tools, no repo code
changes. Future: opencode hook lock-file for exact busy/idle precision.
