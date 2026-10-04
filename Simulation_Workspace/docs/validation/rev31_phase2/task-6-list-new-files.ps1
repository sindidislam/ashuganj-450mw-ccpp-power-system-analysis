$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$baseline = Import-Csv 'docs/validation/rev31_phase2/baseline_hashes.csv'
$baselinePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($r in $baseline) {
    [void]$baselinePaths.Add($r.Path)
}

$allFiles = Get-ChildItem -Path matlab, results, docs -Recurse -File | ForEach-Object {
    $_.FullName.Substring($root.Length + 1).Replace('\', '/')
}

$newFiles = $allFiles | Where-Object { -not $baselinePaths.Contains($_) }
Write-Output "Total new files in matlab/results/docs: $($newFiles.Count)"
$newFiles | ForEach-Object { Write-Output "NEW: $_" }
