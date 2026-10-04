addpath('matlab/analysis');
load('results/phase3_loadflow/LF360_GAT_OUT.mat');
disp('Has line:'); disp(isfield(info.zones.grid, 'line'));
disp('Grid fields:'); disp(fieldnames(info.zones.grid));
