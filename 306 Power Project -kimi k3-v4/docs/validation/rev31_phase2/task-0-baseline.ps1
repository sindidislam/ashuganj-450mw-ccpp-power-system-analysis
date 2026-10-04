$ErrorActionPreference = 'Stop'
$files = @(
    'matlab/data/generatorCapability.m',
    'matlab/data/phase2_source_data.m',
    'matlab/data/engineering_assumptions.m',
    'matlab/data/ashuganj_generators.m',
    'matlab/data/ashuganj_master_data.m',
    'matlab/data/ashuganj_phase2_systems.m',
    'matlab/data/ashuganj_operating_profiles.m',
    'matlab/data/validate_operating_profile.m',
    'matlab/build/build_ashuganj_main.m',
    'matlab/analysis/phase2_dc_step.m',
    'matlab/analysis/check_generator_operating_point.m',
    'matlab/analysis/plot_generator_capability.m',
    'PHASE2_FINAL_REPORT.md'
)

Write-Output "=== FILE HASHES ==="
foreach ($f in $files) {
    if (Test-Path $f) {
        $h = (Get-FileHash $f -Algorithm SHA256).Hash
        Write-Output "$h  $f"
    } else {
        Write-Output "MISSING  $f"
    }
}

# Verify rev2 directory untouched against baseline_hashes.csv
$baseline = Import-Csv 'docs/validation/rev31_phase2/baseline_hashes.csv'
$rev2Files = $baseline | Where-Object { $_.Path -like 'rev2*' }
$rev2Changed = 0
foreach ($r in $rev2Files) {
    if (-not (Test-Path $r.Path)) {
        $rev2Changed++
    } else {
        $h = (Get-FileHash $r.Path -Algorithm SHA256).Hash
        if ($h -ne $r.SHA256) {
            $rev2Changed++
        }
    }
}
Write-Output "`n=== REV2 PRESERVATION CHECK ==="
Write-Output "Rev2 files in baseline: $($rev2Files.Count)"
Write-Output "Rev2 modified files: $rev2Changed"
