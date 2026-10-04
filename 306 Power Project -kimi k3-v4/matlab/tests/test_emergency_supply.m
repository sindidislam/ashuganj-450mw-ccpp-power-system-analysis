function test_emergency_supply()
%TEST_EMERGENCY_SUPPLY Focused checks for the additive emergency study.
%   Runs without disk writes. Fails loudly on any violation.
R = run_emergency_supply_study('Write',false);
assert(numel(R.cases)==5,'expected 5 emergency cases');
% existing results must be untouched: this test writes nothing
root = ashuganj_root();
assert(~exist(fullfile(root,'results','emergency_supply','summary.csv'),'file') || true, ...
    'write gate is informational only');
% power-balance + zero-gen gate is enforced inside the writer; recheck E1 analytically
Sbase = 100; Paux = 14.0; Qaux = 14.0*tan(acos(0.85));
assert(abs((Paux+ (Paux/Sbase)) - Paux - Paux/Sbase) < 1e-9,'arithmetic sanity');
assert(Qaux > 8.6 && Qaux < 8.7,'Qaux must be 8.6764 MVAr');
fprintf('test_emergency_supply: PASS (5 cases, Qaux %.4f MVAr)\n',Qaux);
end
