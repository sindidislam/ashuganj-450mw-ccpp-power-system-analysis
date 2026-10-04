function [np, nf] = test_phase4_handoff()
T = t_case('test_phase4_handoff');
H = phase4_handoff('smoke_run');
T = T.chk(isfield(H,'schemaOK') && H.schemaOK, 'full schema on every row');
T = T.chk(~H.hasSettingsCols, 'no pickup/TMS/grading/duty columns');
T = T.chk(exist(fullfile(H.dir,'phase4_fault_currents.csv'),'file')==2, 'currents CSV written');
[np, nf] = T.done();
end
