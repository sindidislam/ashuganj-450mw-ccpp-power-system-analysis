function paths = setup_phase6_workspace()
%SETUP_PHASE6_WORKSPACE Add code paths without running upstream build/writers.
phase6 = fileparts(fileparts(mfilename('fullpath')));
root = fileparts(phase6);
addpath(fullfile(phase6,'scripts'));
addpath(fullfile(root,'matlab','data'));
addpath(fullfile(root,'matlab','data','assumptions'));
addpath(fullfile(root,'matlab','analysis'));
addpath(fullfile(root,'matlab','utilities'));
addpath(fullfile(root,'matlab','build'));
addpath(fullfile(root,'matlab','phase5'));
paths = struct('project',root,'phase6',phase6, ...
    'model',fullfile(phase6,'model','PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx'), ...
    'reference',fullfile(phase6,'data','phase5_reference'), ...
    'results',fullfile(phase6,'results'));
end
