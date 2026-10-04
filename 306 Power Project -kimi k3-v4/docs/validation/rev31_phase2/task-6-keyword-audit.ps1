$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path

# Define keywords to audit
$auditTerms = @(
    '389.30',
    '389.3',
    '360',
    '342.01',
    '458',
    'SEMIPOL',
    'SFC',
    'battery',
    'charger',
    'Xd',
    'Xq',
    'X2',
    'X0',
    'Td0',
    'Tq0'
)

# File patterns to scan
$targetExtensions = @('.m', '.md', '.csv', '.txt')

Write-Output "Scanning repository for Prompt Section 40 audit terms..."

$results = [System.Collections.Generic.List[PSObject]]::new()

# Exclude generated audit recursion directories (.git, .gemini, tmp, logs, generated audit scripts)
$files = Get-ChildItem -Path $root -Recurse -File | Where-Object {
    $ext = $_.Extension.ToLower()
    $rel = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
    ($targetExtensions -contains $ext) -and `
    (-not ($rel -match '^\.system_generated/')) -and `
    (-not ($rel -match '^docs/validation/rev31_phase2/task-6-keyword')) -and `
    (-not ($rel -match '\.log$'))
}

foreach ($f in $files) {
    $rel = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $lineText = $lines[$i]
        $lineNum = $i + 1
        
        foreach ($term in $auditTerms) {
            $isMatch = $false
            if ($term -in @('389.30', '389.3', '342.01', '458', 'SEMIPOL', 'SFC')) {
                if ($lineText -match [regex]::Escape($term)) { $isMatch = $true }
            } elseif ($term -eq '360') {
                if ($lineText -match '\b360(\.0+)?\b') { $isMatch = $true }
            } elseif ($term -eq 'battery') {
                if ($lineText -match '(?i)\bbatter(y|ies)\b') { $isMatch = $true }
            } elseif ($term -eq 'charger') {
                if ($lineText -match '(?i)\bcharger(s)?\b') { $isMatch = $true }
            } elseif ($term -in @('Xd', 'Xq', 'X2', 'X0', 'Td0', 'Tq0')) {
                if ($lineText -match [regex]::Escape($term) -or $lineText -match [regex]::Escape($term.ToLower())) { $isMatch = $true }
            }
            
            if ($isMatch) {
                # Classification logic
                $classification = "DOCUMENTATION"
                $trimmed = $lineText.Trim()
                $isComment = ($trimmed.StartsWith('%') -or $trimmed.StartsWith('//') -or $trimmed.StartsWith('#'))
                
                if ($rel -match '^rev2/' -or $rel -match 'Ashuganj_South_PSAF' -or $rel -match 'historical' -or $rel -match 'baseline_lf') {
                    $classification = "LEGACY"
                } elseif ($rel -match 'tests?/') {
                    $classification = "TEST_EXPECTATION"
                } elseif ($isComment) {
                    $classification = "COMMENT"
                } elseif ($rel -match '\.md$' -or $rel -match '\.txt$') {
                    $classification = "DOCUMENTATION"
                } elseif ($rel -match 'matlab/data/engineering_assumptions\.m') {
                    $classification = "ENGINEERING_ASSUMPTION"
                } elseif ($rel -match 'matlab/data/ashuganj_operating_profiles\.m') {
                    if ($lineText -match 'LF389P30' -or $lineText -match 'LF1' -or $lineText -match 'LF2') {
                        $classification = "HISTORICAL"
                    } elseif ($lineText -match 'LF342' -or $lineText -match 'LF3' -or $lineText -match 'LF4') {
                        $classification = "QUALIFIED_SCENARIO"
                    } else {
                        $classification = "PRIMARY_DATA"
                    }
                } elseif ($rel -match 'matlab/data/') {
                    if ($lineText -match '389\.3') {
                        $classification = "HISTORICAL"
                    } elseif ($lineText -match '342\.01') {
                        $classification = "QUALIFIED_SCENARIO"
                    } elseif ($lineText -match 'assumption' -or $lineText -match 'assumed') {
                        $classification = "ENGINEERING_ASSUMPTION"
                    } else {
                        $classification = "PRIMARY_DATA"
                    }
                } elseif ($rel -match 'matlab/(solver|analysis|build|studies|ashuganj\.m)') {
                    if ($lineText -match '389\.3') {
                        $classification = "HISTORICAL"
                    } elseif ($lineText -match '342\.01') {
                        $classification = "QUALIFIED_SCENARIO"
                    } else {
                        $classification = "PRIMARY_LIVE_CODE"
                    }
                } elseif ($rel -match '^results/') {
                    $classification = "PRIMARY_DATA"
                }
                
                $results.Add([PSCustomObject]@{
                    Term = $term
                    FilePath = $rel
                    Line = $lineNum
                    Classification = $classification
                    Snippet = if ($lineText.Length -gt 100) { $lineText.Substring(0, 97) + "..." } else { $lineText }
                })
            }
        }
    }
}

Write-Output "Total matches found across repository: $($results.Count)"
$summary = $results | Group-Object Classification | Select-Object Name, Count
Write-Output "`n=== CLASSIFICATION SUMMARY ==="
$summary | Format-Table -AutoSize | Out-String | Write-Output

$termSummary = $results | Group-Object Term | Select-Object Name, Count
Write-Output "=== TERM SUMMARY ==="
$termSummary | Format-Table -AutoSize | Out-String | Write-Output

$results | Export-Csv -NoTypeInformation -LiteralPath "docs/validation/rev31_phase2/task-6-keyword-audit.csv"
Write-Output "Detailed results exported to docs/validation/rev31_phase2/task-6-keyword-audit.csv"
