function R = RUN_EMERGENCY_SUPPLY(varargin)
%RUN_EMERGENCY_SUPPLY Add the generator-off emergency study without rerunning old cases.
%   RUN_EMERGENCY_SUPPLY writes results/emergency_supply only.
%   Existing load-flow, fault, protection and dynamic cases are inputs.
%   Open START_RESULTS.html for the organized results reader after rebuilding it.
root = fileparts(mfilename('fullpath'));
addpath(fullfile(root,'matlab'));
ashuganj_setup();
R = run_emergency_supply_study(varargin{:});
end
