$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$dir = 'docs/validation/rev31_phase2'
$matlab = 'C:\Program Files\MATLAB\R2024a\bin\matlab.exe'
$batch = @'
addpath(genpath('matlab'));
fprintf('TASK2 FINAL %s MATLAB %s\n',char(datetime('now')),version);
files={'matlab/data/engineering_assumptions.m','matlab/data/ashuganj_phase2_systems.m','matlab/tests/test_engineering_assumptions.m','matlab/tests/test_phase2_systems.m'};
for k=1:numel(files)
    fprintf('RESOLVED %s\n',which(files{k}(find(files{k}=='/',1,'last')+1:end)));
    advice=checkcode(files{k},'-id');
    fprintf('ANALYZER %s: %d advisories\n',files{k},numel(advice));
    for j=1:numel(advice)
        fprintf('  %s line %d: %s\n',advice(j).id,advice(j).line,advice(j).message);
    end
end
[a,b]=test_engineering_assumptions(); [c,d]=test_phase2_systems();
[e,f]=test_generator_capability(); [g,h]=test_generator_data(); [i,j]=test_base_conversion();
fprintf('TASK2 FINAL COUNTS %d %d %d %d %d %d %d %d %d %d\n',a,b,c,d,e,f,g,h,i,j);
assert(isequal([a b c d e f g h i j],[9 0 17 0 224 0 476 0 39 0]));
A=engineering_assumptions(); keys=fieldnames(A); rows=cell(numel(keys),8);
for k=1:numel(keys)
    r=A.(keys{k}); rows(k,:)={keys{k},r.component_path,mat2str(r.value),r.unit,mat2str(r.reasonable_range),mat2str(r.assumed_range),r.assumption_basis,r.status};
end
catalog=cell2table(rows,'VariableNames',{'Key','ComponentPath','Selected','Unit','ReasonableRange','AssumedRange','Basis','Status'});
writetable(catalog,'docs/validation/rev31_phase2/task-2-assumption-catalog.csv');
fprintf('CENTRAL_RECORDS %d\n',numel(keys));
fprintf('TASK2 FINAL VERIFIED 765 passed 0 failed; 26 new contracts and 739 existing assertions\n');
'@
$oneLine = ($batch -split '\r?\n' | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim().TrimEnd(';') }) -join '; '
& $matlab -wait -logfile "$dir/task-2-regression-green.log" -batch $oneLine
$exit = $LASTEXITCODE
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("MATLAB_FINAL_EXIT=$exit")
if ($exit -ne 0) { throw "MATLAB final verification failed: $exit" }
$log = Get-Content -LiteralPath "$dir/task-2-regression-green.log"
$lines.AddRange([string[]]($log | Where-Object { $_ -match 'TASK2|CENTRAL_RECORDS|ANALYZER|RESOLVED|=>|^  ISCL|^  AGROW' }))
$passes = @($log | Where-Object { $_ -match '^  PASS ' }).Count
$fails = @($log | Where-Object { $_ -match '^  FAIL ' }).Count
if ($passes -ne 765 -or $fails -ne 0) { throw "Unexpected log assertion counts: $passes/$fails" }
$lines.Add("LOG_RECOUNT_PASS=$passes FAIL=$fails")
$rows = Import-Csv -LiteralPath "$dir/task-2-start-hashes.csv"
$changed = @(); $missing = @()
foreach ($r in $rows) {
    $p = Join-Path $root $r.Path
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { $missing += $r.Path; continue }
    if ((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $r.SHA256) { $changed += $r.Path }
}
$lines.Add("PREEXISTING_FILES=$($rows.Count) UNCHANGED=$($rows.Count-$changed.Count-$missing.Count) CHANGED=$($changed.Count) MISSING=$($missing.Count)")
if ($changed.Count -or $missing.Count) { throw "Preexisting files changed/missing: $changed $missing" }
$first = Import-Csv -LiteralPath "$dir/task-2-test-first-hashes.csv"
foreach ($r in $first) {
    if ((Get-FileHash -LiteralPath $r.Path -Algorithm SHA256).Hash -ne $r.Hash) { throw 'Test changed after RED' }
}
$lines.Add('TESTS_UNCHANGED_SINCE_RED=2/2')
$products = @('matlab/data/engineering_assumptions.m', 'matlab/data/ashuganj_phase2_systems.m', 'matlab/tests/test_engineering_assumptions.m', 'matlab/tests/test_phase2_systems.m')
$products | ForEach-Object { [pscustomobject]@{Path = $_; Bytes = (Get-Item -LiteralPath $_).Length; SHA256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash } } | Export-Csv -NoTypeInformation -LiteralPath "$dir/task-2-product-hashes.csv"
$allowed = $products + @(Get-ChildItem -LiteralPath $dir -Filter 'task-2-*' -File | ForEach-Object { "$dir/$($_.Name)" })
$new = @(Get-ChildItem -LiteralPath . -Recurse -File | ForEach-Object { $_.FullName.Substring($root.Length + 1).Replace('\', '/') } | Where-Object { $_ -notin $rows.Path })
$unexpected = @($new | Where-Object { $_ -notin $allowed })
$lines.Add("UNEXPECTED_ADDITIONS=$($unexpected.Count)")
if ($unexpected.Count) { throw "Unexpected additions: $unexpected" }
$lines.Add('SCOPE_VERIFIED: four new MATLAB files plus Task2 evidence only; existing sources/history untouched.')
[IO.File]::WriteAllLines((Join-Path $root "$dir/task-2-verification.log"), $lines, [Text.UTF8Encoding]::new($false))
$lines | ForEach-Object { Write-Output $_ }
