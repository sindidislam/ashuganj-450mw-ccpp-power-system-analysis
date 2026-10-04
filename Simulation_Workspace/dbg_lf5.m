addpath('matlab/analysis'); addpath('matlab/studies'); addpath('matlab/build');
run('matlab/ashuganj_setup.m');
D = ashuganj_master_data();
C = D.operating_profiles(1);
info = build_ashuganj_main(C.ID, 'Quiet', true, 'Backup', false, 'Save', false);
LF = power_loadflow('-v2', info.model, 'solve');
for i=1:numel(LF.bus)
    fprintf('Bus %d:\n', i);
    disp(LF.bus(i).vnodes);
end
bdclose('all');
