function [np, nf] = test_phase4_matrix()
T = t_case('test_phase4_matrix');
run_phase4_matrix({'base','C-HIGH'}, {'F3'}, {'LLL','LG'}, {'Ikpp'}, 't14_smoke');
D = fullfile(ashuganj_root(), 'results', 'phase4_fault', 't14_smoke');
T = T.chk(exist(fullfile(D,'phase4_fault_currents.csv'),'file')==2, 'matrix currents written');
C = readtable(fullfile(D,'phase4_fault_currents.csv'));
T = T.chk(all(strcmp(C.stage(1:2), {'Ikpp';'Ikpp'})), 'stage labels present');
run_phase4_matrix({'GAT-IN'}, {'F3'}, {'LG'}, {'Ikpp'}, 't14_incheck');
D2 = fullfile(ashuganj_root(), 'results', 'phase4_fault', 't14_incheck');
C2 = readtable(fullfile(D2,'phase4_contributions.csv'));
T = T.chk(any(contains(C2.Properties.VariableNames,'leg_GAT_HV_kA')), 'IN run carries GAT columns');
run_phase4_matrix({'base'}, {'F4'}, {'LLL'}, {'Ikpp'}, 't14_f4check');
D3 = fullfile(ashuganj_root(), 'results', 'phase4_fault', 't14_f4check');
C3 = readtable(fullfile(D3,'phase4_contributions.csv'));
T = T.chk(any(contains(C3.Properties.VariableNames,'leg_LINE_B1_kA')), 'F4 run carries B1/B2 columns');
run_phase4_matrix({'base'}, {'F3'}, {'LG','LLG'}, {'Ib','Isteady'}, 't14_stages');
D4 = fullfile(ashuganj_root(), 'results', 'phase4_fault', 't14_stages');
C4 = readtable(fullfile(D4,'phase4_fault_currents.csv'));
ibRows = C4(strcmp(C4.stage,'Ib'),:);
T = T.chk(height(ibRows) >= 1 && all(ibRows.t_break_s == 0.06) && all(contains(ibRows.footnote,'constant-E')), 'Ib rows carry t_break + constant-E note');
stRows = C4(strcmp(C4.stage,'Isteady'),:);
T = T.chk(height(stRows) >= 1 && all(contains(stRows.footnote,'no-AVR')), 'steady rows carry no-AVR note');
llgRows = C4(strcmp(C4.fault_type,'LLG'),:);
T = T.chk(height(llgRows) >= 1 && all(contains(llgRows.footnote,'single-earth')), 'LLG rows carry single-earth note');
[np, nf] = T.done();
end
