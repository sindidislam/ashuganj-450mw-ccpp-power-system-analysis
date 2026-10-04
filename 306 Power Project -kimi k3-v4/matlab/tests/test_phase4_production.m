function [np, nf] = test_phase4_production()
%TEST_PHASE4_PRODUCTION  Bounded-subset production package check (task K2).
%
%   Runs RUN_PHASE4_PRODUCTION over 2 legs x F3 LLL/LG OUT into a scratch
%   tag and asserts the production archive shape: manifest.json +
%   sha256.txt + analytic_bounds.csv + run_log.txt + the 4 standard CSVs
%   exist, currents carry the 25 schema columns in order, every CSV has
%   rows, and the forbidden-column scan is clean on all headers. Scratch
%   results are removed on success (left in place on failure for diagnosis).

T = t_case('test_phase4_production');
tag = 'prod_subset';
root = ashuganj_root();
D = fullfile(root, 'results', 'phase4_fault', tag);
if exist(D, 'dir') == 7
    rmdir(D, 's');
end

R = run_phase4_production(tag, 'overwrite', true, ...
    'legs', {'base', 'C-HIGH'}, 'locs', {'F3'}, ...
    'types', {'LLL', 'LG'}, 'stages', {'Ikpp', 'ip'}, ...
    'skipValidate', true);
T = T.chk(isstruct(R) && all(isfield(R, {'dir', 'nCurr', 'nCon', 'nBand', 'nCt'})), ...
    'production runner returns result struct');

files = {'phase4_fault_currents.csv', 'phase4_contributions.csv', ...
    'phase4_bands.csv', 'phase4_ct_data.csv', 'manifest.json', ...
    'analytic_bounds.csv', 'sha256.txt', 'run_log.txt'};
for k = 1:numel(files)
    T = T.chk(exist(fullfile(D, files{k}), 'file') == 2, ...
        ['production file written: ' files{k}]);
end

schemaHeaders = {'fault_type', 'location', 'm', 'caseID', 'grid_dataset', 'XoR_P', ...
    'zero_band', 'k0g', 'XdRole', 'NER_variant', 'GAT_variant', 'ZfMode', 'Zf_ohm', ...
    'coupler', 'stage', 'unit', 'base', 'Irms_kA', 'Iang_deg', 'Iseq0_kA', 'Iseq1_kA', ...
    'Iseq2_kA', 'r_kappa_ip', 't_break_s', 'footnote'};
bandHeaders = {'group', 'fault_type', 'min_Ik_kA', 'max_Ik_kA', 'min_leg', 'max_leg', ...
    'mid_Ik_kA', 'mid_leg', 'incomplete', 'note'};
ctHeaders = {'fault_type', 'location', 'caseID', 'through_path', 'stage', 'kind', ...
    'primary_kA', 'FL_anchor_kA', 'ratio_1600_1_A', 'ratio_800_1_A', 'ratio_400_1_A', 'footnote'};

C = readtable(fullfile(D, 'phase4_fault_currents.csv'));
T = T.chk(isequal(C.Properties.VariableNames, schemaHeaders), ...
    'currents carry 25 schema columns in order');
T = T.chk(height(C) > 0, 'currents row count > 0');

K = readtable(fullfile(D, 'phase4_contributions.csv'));
T = T.chk(height(K) > 0, 'contributions row count > 0');
T = T.chk(numel(K.Properties.VariableNames) >= numel(schemaHeaders) && ...
    isequal(K.Properties.VariableNames(1:numel(schemaHeaders)), schemaHeaders), ...
    'contributions lead with schema columns');

B = readtable(fullfile(D, 'phase4_bands.csv'));
T = T.chk(isequal(B.Properties.VariableNames, bandHeaders), 'bands headers exact');
T = T.chk(height(B) > 0, 'bands row count > 0');

G = readtable(fullfile(D, 'phase4_ct_data.csv'));
T = T.chk(isequal(G.Properties.VariableNames, ctHeaders), 'ct headers exact');
T = T.chk(height(G) > 0, 'ct row count > 0');

A = readtable(fullfile(D, 'analytic_bounds.csv'));
T = T.chk(height(A) > 0 && any(strcmp(A.Properties.VariableNames, 'method')), ...
    'analytic bounds rows with method column');

T = T.chk(~hasForbidden(C.Properties.VariableNames) && ...
    ~hasForbidden(K.Properties.VariableNames) && ...
    ~hasForbidden(B.Properties.VariableNames) && ...
    ~hasForbidden(G.Properties.VariableNames) && ...
    ~hasForbidden(A.Properties.VariableNames), ...
    'forbidden-column scan clean on all headers');

M = fileread(fullfile(D, 'manifest.json'));
T = T.chk(contains(M, 'C-HIGH') && contains(M, 'phase4_fault_currents.csv'), ...
    'manifest records leg list and CSV inventory');

H = fileread(fullfile(D, 'sha256.txt'));
T = T.chk(contains(H, 'phase4_fault_currents.csv') && contains(H, 'manifest.json'), ...
    'sha256 covers CSVs and manifest');

if T.nf == 0 && exist(D, 'dir') == 7
    rmdir(D, 's');
end
[np, nf] = T.done();
end

function tf = hasForbidden(headers)
pats = {'pickup', 'tms', 'grading', 'differential', 'duty', 'verdict', 'rating'};
tf = false;
for i = 1:numel(headers)
    h = lower(char(headers{i}));
    for j = 1:numel(pats)
        if ~isempty(strfind(h, pats{j}))
            tf = true;
            return;
        end
    end
end
end
