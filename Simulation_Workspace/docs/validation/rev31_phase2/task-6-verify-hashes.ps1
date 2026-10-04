$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$baselinePath = "docs/validation/rev31_phase2/baseline_hashes.csv"
$rows = Import-Csv -LiteralPath $baselinePath

$changed = @()
$missing = @()
$unchanged = 0

foreach ($r in $rows) {
    $p = Join-Path $root $r.Path
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        $missing += $r.Path
        continue
    }
    $h = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
    if ($h -ne $r.SHA256) {
        $changed += [PSCustomObject]@{
            Path = $r.Path
            OldHash = $r.SHA256
            NewHash = $h
            OldBytes = $r.Bytes
            NewBytes = (Get-Item -LiteralPath $p).Length
        }
    } else {
        $unchanged++
    }
}

Write-Output "TOTAL_BASELINE_FILES=$($rows.Count)"
Write-Output "UNCHANGED_FILES=$unchanged"
Write-Output "CHANGED_FILES_COUNT=$($changed.Count)"
Write-Output "MISSING_FILES_COUNT=$($missing.Count)"

Write-Output "`n=== CHANGED PREEXISTING FILES ==="
$changed | Format-Table -AutoSize | Out-String | Write-Output

# Export the changed files report
$changed | Export-Csv -NoTypeInformation -LiteralPath "docs/validation/rev31_phase2/task-6-changed-files.csv"
