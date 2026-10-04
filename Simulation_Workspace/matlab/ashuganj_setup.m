function ashuganj_setup()
%ASHUGANJ_SETUP  Put every project folder on the MATLAB path.
%
%   Call this once per MATLAB session before running anything else:
%       run('<root>/matlab/ashuganj_setup.m')
%   or, if <root>/matlab is already on the path, simply
%       ashuganj_setup

here = fileparts(mfilename('fullpath'));
addpath(here);
addpath(fullfile(here,'data'));
addpath(fullfile(here,'data','assumptions'));
addpath(fullfile(here,'utilities'));
addpath(fullfile(here,'build'));
addpath(fullfile(here,'tests'));
addpath(fullfile(here,'analysis'));
addpath(fullfile(here,'studies'));
addpath(fullfile(here,'gui'));

% matlab/env is DELIBERATELY not on the path. It holds one-off probes that
% measured the solver's behaviour - evidence for the validation documents, not
% library code. Run one with:
%     run(fullfile(ashuganj_root,'matlab','env','probe_freq.m'))

root = fileparts(here);
dirs = { fullfile(root,'simulink','main'), ...
         fullfile(root,'simulink','studies'), ...
         fullfile(root,'simulink','backups'), ...
         fullfile(root,'results','load_flow'), ...
         fullfile(root,'results','plots'), ...
         fullfile(root,'results','figures'), ...
         fullfile(root,'results','reports'), ...
         fullfile(root,'data','master'), ...
         fullfile(root,'docs','model'), ...
         fullfile(root,'docs','manual'), ...
         fullfile(root,'docs','validation') };
for i = 1:numel(dirs)
    if ~isfolder(dirs{i}), mkdir(dirs{i}); end
end

fprintf('Ashuganj South project path configured.\n');
fprintf('  root  : %s\n', root);
fprintf('  MATLAB: %s\n', version);
end
