function [np, nf] = test_phase5c_enrichment()
%TEST_PHASE5C_ENRICHMENT  MVA, first-ring, sliding, voltages.
T = t_case('test_phase5c_enrichment');
out = fullfile(tempdir, ['ph5c_enr_' char(java.util.UUID.randomUUID())]);
mkdir(out); cleanup = onCleanup(@()rmdir(out, 's')); %#ok<NASGU>
R = phase5c_fault_enrichment(out, ashuganj_root());
T = T.chk(isfile(R.enriched) && isfile(R.sliding), 'enriched + sliding CSVs written');
T = T.chk(abs(R.F1_LLL_kA - 126.21414119005) < 1e-6, 'F1 LLL 126.21 kA backbone');
T = T.chk(abs(R.F3_LLL_kA - 50.5308851865359) < 1e-6, 'F3 LLL 50.53 kA backbone');
T = T.chk(abs(R.F1_MVA - sqrt(3)*22000*126214.14/1e6) < 0.5, 'F1 MVA = sqrt3*22kV*I');
T = T.chk(abs(R.F3_MVA - sqrt(3)*230000*50530.89/1e6) < 1.0, 'F3 MVA = sqrt3*230kV*I');
E = readtable(R.enriched, 'VariableNamingRule', 'preserve');
f1 = E(strcmp(string(E.location), 'F1') & strcmp(string(E.fault_type), 'LLL') & strcmp(string(E.caseID), 'LF360_GAT_OUT'), :);
T = T.chk(abs(f1.ring_GEN_kA - 55.0487096805279) < 1e-4, 'first-ring GEN leg 55.05 kA');
T = T.chk(abs(f1.ring_GSUT_HV_kA - 72.1051542513644) < 1e-4, 'first-ring GSUT_HV leg 72.11 kA');
f1lg = E(strcmp(string(E.location), 'F1') & strcmp(string(E.fault_type), 'LG'), :);
T = T.chk(all(f1lg.ring_NER_A > 0 & f1lg.ring_NER_A < 10), 'LG NER earth ~2.4 mA seq (7.27 A faulted)');
S = readtable(R.sliding, 'VariableNamingRule', 'preserve');
T = T.chk(height(S) == 3 && all(S.m == [0.05; 0.5; 0.95]), 'sliding m = 5/50/95%');
T = T.chk(S.Isc_kA_F4_LLL(1) > S.Isc_kA_F4_LLL(2) && S.Isc_kA_F4_LLL(2) > S.Isc_kA_F4_LLL(3), 'sliding current falls with distance');
try, phase5c_fault_enrichment(42); T = T.chk(false, 'invalid path rejected'); catch ME, T = T.chk(startsWith(ME.identifier, 'phase5c_enrich'), 'invalid path rejected'); end
[np, nf] = T.done();
end
