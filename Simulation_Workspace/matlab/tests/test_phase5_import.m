function [np, nf] = test_phase5_import()
T = t_case('test_phase5_import');
root = ashuganj_root();
Fp = fullfile(root,'results','phase4_fault','production','phase4_fault_currents.csv');
T = T.chk(exist(Fp,'file')==2, 'production currents CSV exists');
Ti = phase5_import(root);
T = T.chk(height(Ti)==40, 'backbone import yields 2x5x4 Ikpp = 40 rows');
% Regression: F3 LLL OUT Ikpp == 50.5308851865359 kA within 1e-6
r = Ti(strcmp(Ti.fault_location,'F3')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(~isempty(r), 'F3 LLL OUT row present');
T = T.chk(abs(r.I_primary_kA-50.5308851865359)<1e-6, 'F3 LLL OUT identity 50.530885 kA');
% F1 LG OUT == 0.00727200442799167 kA (7.27 A NER physics preserved)
g = Ti(strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LG')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(g.I_primary_kA-0.00727200442799167)<1e-9, 'F1 LG OUT identity 7.27 A');
% Task 3: F1/F2 distinct labels, identical values, no artificial Z
a = Ti(strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
b = Ti(strcmp(Ti.fault_location,'F2')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(a.I_primary_kA-b.I_primary_kA)<1e-9, 'F1==F2 values, distinct labels, no artificial Z');
T = T.chk(all(Ti.m(strcmp(Ti.fault_location,'F4'))==0.5), 'F4 primary m=0.5');
T = T.chk(~any(strcmp(Ti.provenance,'scratch')), 'no scratch/probe provenance');
% Task 3: through-current join from phase4_contributions.csv where available
T = T.chk(all(ismember({'leg_GEN_kA','leg_GRID_kA','through_note'}, Ti.Properties.VariableNames)), 'through-current leg columns + note present');
r3 = Ti(strcmp(Ti.fault_location,'F3')&strcmp(Ti.fault_type,'LLL')&strcmp(Ti.caseID,'LF360_GAT_OUT'),:);
T = T.chk(abs(r3.leg_GRID_kA-47.3697866297748)<1e-9, 'F3 LLL OUT through-current leg_GRID matches contributions');
[np, nf] = T.done();
end
