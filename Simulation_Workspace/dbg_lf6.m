addpath('matlab/analysis'); addpath('matlab/studies'); addpath('matlab/build');
run('matlab/ashuganj_setup.m');
D = ashuganj_master_data();
C = D.operating_profiles(1);
info = build_ashuganj_main(C.ID, 'Quiet', true, 'Backup', false, 'Save', false);
LF = power_loadflow('-v2', info.model, 'solve');
disp(fieldnames(LF.bus));
disp(LF.bus(1));
bdclose('all');
