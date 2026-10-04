function RUN_ME(action)
%RUN_ME  Start here. One command that runs the whole load flow study.
%
%   Open MATLAB, make this folder the current folder, and type:
%
%       RUN_ME              solve all four cases, redraw every figure and
%                           regenerate both HTML documents      (a few minutes)
%       RUN_ME check        report the environment and change nothing
%       RUN_ME open         open the Simulink diagram to present
%       RUN_ME docs         regenerate the HTML documents only
%       RUN_ME tests        run the validation suite
%
%   Then read docs/manual/index.html.
%
%   This file is a wrapper. The work is in matlab/ashuganj.m, and every action
%   above is passed straight to it - see 'help ashuganj' for the full list.
%
%   It locates the project from its own path, so the folder can be copied to any
%   drive, any directory, any PC, and this still works with no editing. There is
%   no absolute path anywhere in the project.

here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'matlab'));

if nargin < 1
    ashuganj();
else
    ashuganj(action);
end
end
