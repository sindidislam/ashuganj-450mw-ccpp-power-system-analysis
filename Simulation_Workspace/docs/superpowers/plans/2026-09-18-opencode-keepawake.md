# OpenCode Keep-Awake Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a per-user background watcher that blocks Windows sleep only while OpenCode is actively working on AC power, allowing screen-off and auto-releasing afterwards.

**Architecture:** Single hidden PowerShell loop re-asserts `SetThreadExecutionState(ES_CONTINUOUS|ES_SYSTEM_REQUIRED)` every 30s while (on-AC AND opencode.exe running AND opencode.db* written within 10 min); otherwise releases. Logon Scheduled Task provides auto-start; no timeout changes, no admin.

**Tech Stack:** Windows 11 PowerShell 5.1, `kernel32!SetThreadExecutionState` via P/Invoke, Scheduled Tasks (`ScheduledTasks` module), Pester for logic tests.

**Spec:** `docs/superpowers/specs/2026-09-18-opencode-keepawake-design.md`

## Global Constraints

- Windows 11 Pro, Balanced scheme; do NOT modify sleep/display timeouts.
- Block system sleep only; deliberately omit `ES_DISPLAY_REQUIRED` so screen may turn off.
- Active condition requires ALL: on AC AND opencode.exe running AND DB mtime within IdleMinutes (default 10).
- AC-only: on battery the watcher must release and never block.
- No admin required; per-user install under `%USERPROFILE%\.config\opencode\keep-awake\`.
- Single watcher instance via named mutex; `try/finally` always releases.

---

## File Structure

- Create: `C:\Users\sindi\.config\opencode\keep-awake\opencode-keepawake.ps1` — watcher loop + pure logic functions (`Test-ShouldBlock`, `Test-OnACPower`, `Test-OpencodeRunning`, `Get-OpencodeLastWrite`), logging, `-NoLoop`/`-DryRun` switches.
- Create: `C:\Users\sindi\.config\opencode\keep-awake\Tests\KeepAwake.Tests.ps1` — Pester tests for `Test-ShouldBlock`.
- Create: `C:\Users\sindi\.config\opencode\keep-awake\Install-OpenCodeKeepAwake.ps1` — creates/updates logon task `OpenCodeKeepAwake`, starts it.
- Create: `C:\Users\sindi\.config\opencode\keep-awake\Uninstall-OpenCodeKeepAwake.ps1` — removes task, stops watcher, releases state.
- Log: `C:\Users\sindi\.config\opencode\keep-awake\keepawake.log` (created at runtime).

---

### Task 1: Watcher script + logic tests

**Files:**
- Create: `C:\Users\sindi\.config\opencode\keep-awake\opencode-keepawake.ps1`
- Test: `C:\Users\sindi\.config\opencode\keep-awake\Tests\KeepAwake.Tests.ps1`

**Interfaces:**
- Consumes: `opencode.db*` mtimes from `%USERPROFILE%\.local\share\opencode` and `%USERPROFILE%\.config\opencode` (newest wins), `Get-Process opencode`, `SystemInformation.PowerStatus`.
- Produces: `Test-ShouldBlock([bool]$OnAc,[bool]$ProcRunning,$LastWrite,[datetime]$Now,[int]$IdleMinutes)` → `[bool]`; watcher loop honoring `-IdleMinutes`, `-PollSeconds`, `-DryRun`, `-NoLoop`.

- [ ] **Step 1: Write the failing Pester test**

```powershell
# File: C:\Users\sindi\.config\opencode\keep-awake\Tests\KeepAwake.Tests.ps1
BeforeAll {
  . "$PSScriptRoot\..\opencode-keepawake.ps1" -NoLoop
}
Describe 'Test-ShouldBlock' {
  It 'blocks when AC + running + fresh write' {
    Test-ShouldBlock -OnAc $true -ProcRunning $true `
      -LastWrite ([datetime]'2026-09-18T10:00:00') `
      -Now ([datetime]'2026-09-18T10:05:00') -IdleMinutes 10 | Should -Be $true
  }
  It 'releases when idle expired' {
    Test-ShouldBlock -OnAc $true -ProcRunning $true `
      -LastWrite ([datetime]'2026-09-18T10:00:00') `
      -Now ([datetime]'2026-09-18T10:30:00') -IdleMinutes 10 | Should -Be $false
  }
  It 'releases on battery' {
    Test-ShouldBlock -OnAc $false -ProcRunning $true `
      -LastWrite ([datetime]'2026-09-18T10:00:00') `
      -Now ([datetime]'2026-09-18T10:01:00') -IdleMinutes 10 | Should -Be $false
  }
  It 'releases when no process' {
    Test-ShouldBlock -OnAc $true -ProcRunning $false `
      -LastWrite ([datetime]'2026-09-18T10:00:00') `
      -Now ([datetime]'2026-09-18T10:01:00') -IdleMinutes 10 | Should -Be $false
  }
  It 'releases when LastWrite is null' {
    Test-ShouldBlock -OnAc $true -ProcRunning $true `
      -LastWrite $null -Now ([datetime]'2026-09-18T10:01:00') `
      -IdleMinutes 10 | Should -Be $false
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `Invoke-Pester -Path "$env:USERPROFILE\.config\opencode\keep-awake\Tests\KeepAwake.Tests.ps1"`
Expected: FAIL — file `opencode-keepawake.ps1` not found.

- [ ] **Step 3: Write minimal watcher implementation**

```powershell
# File: C:\Users\sindi\.config\opencode\keep-awake\opencode-keepawake.ps1
param(
  [int]$IdleMinutes = 10,
  [int]$PollSeconds = 30,
  [string]$LogPath = "$env:USERPROFILE\.config\opencode\keep-awake\keepawake.log",
  [switch]$DryRun,
  [switch]$NoLoop
)
Add-Type -AssemblyName System.Windows.Forms
$ES_CONTINUOUS = 0x80000000
$ES_SYSTEM_REQUIRED = 0x00000001
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$es = Add-Type -MemberDefinition $sig -Name KeepAwakeES -Namespace Win32 -PassThru
function Write-KeepAwakeLog([string]$Msg) {
  $line = "{0:u} {1}" -f (Get-Date), $Msg
  New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
  Add-Content -LiteralPath $LogPath -Value $line
}
function Test-OnACPower {
  return ([System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus -eq 'Online')
}
function Test-OpencodeRunning {
  return ($null -ne (Get-Process -Name 'opencode' -ErrorAction SilentlyContinue))
}
function Get-OpencodeLastWrite {
  $dirs = @("$env:USERPROFILE\.local\share\opencode", "$env:USERPROFILE\.config\opencode")
  $files = foreach ($dir in $dirs) { Get-ChildItem -LiteralPath $dir -Filter 'opencode.db*' -ErrorAction SilentlyContinue }
  if (-not $files) { return $null }
  return ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
}
function Test-ShouldBlock([bool]$OnAc, [bool]$ProcRunning, $LastWrite, [datetime]$Now, [int]$IdleMinutes) {
  if (-not $OnAc) { return $false }
  if (-not $ProcRunning) { return $false }
  if ($null -eq $LastWrite) { return $false }
  return ((($Now - [datetime]$LastWrite).TotalMinutes) -le $IdleMinutes)
}
function Set-SleepBlock([bool]$Block) {
  if ($DryRun) { return }
  if ($Block) { [void]$es::SetThreadExecutionState($ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED) }
  else { [void]$es::SetThreadExecutionState($ES_CONTINUOUS) }
}
if ($NoLoop) { return }
$mutex = New-Object System.Threading.Mutex($false, 'Global\OpenCodeKeepAwake')
if (-not $mutex.WaitOne(0)) { Write-KeepAwakeLog 'Another watcher running; exiting.'; exit 0 }
try {
  Write-KeepAwakeLog "Watcher start IdleMinutes=$IdleMinutes PollSeconds=$PollSeconds DryRun=$DryRun"
  $blocking = $false
  while ($true) {
    $onAc = Test-OnACPower
    $proc = Test-OpencodeRunning
    $lw = Get-OpencodeLastWrite
    if (($null -eq $lw) -and $proc) { Write-KeepAwakeLog 'WARN: opencode.db* not found; needs process+DB to block.' }
    $want = Test-ShouldBlock -OnAc $onAc -ProcRunning $proc -LastWrite $lw -Now (Get-Date) -IdleMinutes $IdleMinutes
    if ($want -and -not $blocking) { Write-KeepAwakeLog 'BLOCK sleep (working on AC).'; Set-SleepBlock $true; $blocking = $true }
    elseif ($want -and $blocking) { Set-SleepBlock $true }
    elseif ((-not $want) -and $blocking) { Write-KeepAwakeLog 'RELEASE sleep (idle/closed/battery).'; Set-SleepBlock $false; $blocking = $false }
    Start-Sleep -Seconds $PollSeconds
  }
} finally {
  Set-SleepBlock $false
  $mutex.ReleaseMutex() | Out-Null
  Write-KeepAwakeLog 'Watcher exit; released.'
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `Invoke-Pester -Path "$env:USERPROFILE\.config\opencode\keep-awake\Tests\KeepAwake.Tests.ps1"`
Expected: PASS — 5/5 tests.

- [ ] **Step 5: Dry-run the watcher for one poll**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\keep-awake\opencode-keepawake.ps1" -IdleMinutes 10 -PollSeconds 5 -DryRun` (stop with Ctrl+C after ~15s), then `Get-Content "$env:USERPROFILE\.config\opencode\keep-awake\keepawake.log" -Tail 5`
Expected: log shows `Watcher start` and BLOCK/RELEASE or WARN lines; no error.

- [ ] **Step 6: Commit (if git repo present; otherwise skip)**

```bash
git add docs/superpowers/specs/2026-09-18-opencode-keepawake-design.md docs/superpowers/plans/2026-09-18-opencode-keepawake.md
git commit -m "docs: opencode keep-awake spec and plan" || echo "no git repo, skip"
```

---

### Task 2: Installer (logon Scheduled Task + start now)

**Files:**
- Create: `C:\Users\sindi\.config\opencode\keep-awake\Install-OpenCodeKeepAwake.ps1`

**Interfaces:**
- Consumes: watcher path from Task 1.
- Produces: Scheduled Task `OpenCodeKeepAwake` (AtLogOn, current user) running hidden watcher; task started immediately.

- [ ] **Step 1: Write installer**

```powershell
# File: C:\Users\sindi\.config\opencode\keep-awake\Install-OpenCodeKeepAwake.ps1
$dir = "$env:USERPROFILE\.config\opencode\keep-awake"
$watcher = Join-Path $dir 'opencode-keepawake.ps1'
if (-not (Test-Path -LiteralPath $watcher)) { throw "Watcher not found: $watcher (do Task 1 first)" }
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$watcher`" -IdleMinutes 10 -PollSeconds 30"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'OpenCodeKeepAwake' -Action $action -Trigger $trigger -Settings $settings -Description 'Block sleep while OpenCode is actively working (AC only).' -Force | Out-Null
Start-ScheduledTask -TaskName 'OpenCodeKeepAwake'
Get-ScheduledTask -TaskName 'OpenCodeKeepAwake' | Select-Object TaskName, State
```

- [ ] **Step 2: Run installer**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\keep-awake\Install-OpenCodeKeepAwake.ps1"`
Expected: outputs TaskName `OpenCodeKeepAwake`, State `Running`; `Get-ScheduledTask -TaskName OpenCodeKeepAwake` exists.

- [ ] **Step 3: Verify watcher process alive**

Run: `Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -match 'opencode-keepawake' } | Select-Object ProcessId, CommandLine`
Expected: ≥1 row with `opencode-keepawake.ps1` in CommandLine.

---

### Task 3: Uninstaller + live release verification

**Files:**
- Create: `C:\Users\sindi\.config\opencode\keep-awake\Uninstall-OpenCodeKeepAwake.ps1`

**Interfaces:**
- Consumes: task `OpenCodeKeepAwake`, watcher processes from Task 2.
- Produces: task removed, watcher stopped, execution state released.

- [ ] **Step 1: Write uninstaller**

```powershell
# File: C:\Users\sindi\.config\opencode\keep-awake\Uninstall-OpenCodeKeepAwake.ps1
Unregister-ScheduledTask -TaskName 'OpenCodeKeepAwake' -Confirm:$false -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'opencode-keepawake' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$t = Add-Type -MemberDefinition $sig -Name KeepAwakeESOff -Namespace Win32 -PassThru
[void]$t::SetThreadExecutionState(0x80000000)
'Uninstalled OpenCodeKeepAwake; sleep behavior restored.'
```

- [ ] **Step 2: Verify live block then release (do NOT uninstall yet)**

Run: keep watcher running; from an elevated prompt run `powercfg /REQUESTS`; confirm a SYSTEM request from PowerShell while working; then close opencode or wait >10 min idle / unplug AC and confirm the request clears and `keepawake.log` shows RELEASE.
Expected: BLOCK entry while active on AC; RELEASE entry after idle/close/battery.

- [ ] **Step 3: Run uninstaller only if user wants removal (default: keep installed)**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.config\opencode\keep-awake\Uninstall-OpenCodeKeepAwake.ps1"`
Expected: prints confirmation; `Get-ScheduledTask -TaskName OpenCodeKeepAwake` errors (not found); no `opencode-keepawake` PowerShell processes remain.
