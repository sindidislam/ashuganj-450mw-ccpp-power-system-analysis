function S = run_phase2_load_flow(varargin)
%RUN_PHASE2_LOAD_FLOW Solves and verifies Phase 2 load-flow cases.
%   S = RUN_PHASE2_LOAD_FLOW() solves the primary 360 MW operating cases
%   (LF360_GAT_OUT and LF360_GAT_IN) and writes the results to
%   results/phase2_loadflow/.
%
%   S = RUN_PHASE2_LOAD_FLOW('Cases', {'LF360_GAT_OUT', 'LF360_GAT_IN'})
%   S = RUN_PHASE2_LOAD_FLOW('Cases', 'all') % solves all 6 canonical profiles
%   S = RUN_PHASE2_LOAD_FLOW('Write', false) % solve and verify without disk writes
%   S = RUN_PHASE2_LOAD_FLOW('OutputDir', 'custom/path')

p = inputParser;
addParameter(p, 'Cases', {'LF360_GAT_OUT', 'LF360_GAT_IN'});
addParameter(p, 'Write', true, @islogical);
addParameter(p, 'OutputDir', '', @ischar);
parse(p, varargin{:});
opt = p.Results;

root = ashuganj_root();
if isempty(opt.OutputDir)
    outDir = fullfile(root, 'results', 'phase2_loadflow');
else
    outDir = opt.OutputDir;
end

D = ashuganj_master_data();

% Resolve requested cases
if ischar(opt.Cases) && strcmp(opt.Cases, 'all')
    case_ids = {D.operating_profiles.ID};
elseif ischar(opt.Cases)
    case_ids = {opt.Cases};
else
    case_ids = opt.Cases;
end

if opt.Write && ~exist(outDir, 'dir')
    mkdir(outDir);
end

fprintf('\n============================================================\n');
fprintf('  REV3.1 PHASE 2 LOAD-FLOW EXECUTION & VERIFICATION\n');
fprintf('============================================================\n');
fprintf('  Cases to solve: %s\n', strjoin(case_ids, ', '));
fprintf('  Output directory: %s\n\n', outDir);

S = [];
all_bus_results = {};

for i = 1:numel(case_ids)
    cid = case_ids{i};
    fprintf('--- Solving Case: %s -----------------------------------\n', cid);
    
    % 1. Fresh build (never solved beforehand to avoid state mutation)
    info = build_ashuganj_main(cid, 'Quiet', true, 'Backup', false, 'Save', false);
    C = info.case;
    
    % 2. Solve via frozen load flow engine
    t0 = tic;
    LF = power_loadflow(info.model, 'solve');
    elapsed = toc(t0);
    
    % 3. Comprehensive Independent Validation
    val = validate_phase2_load_flow(LF, D, C, info);
    if bdIsLoaded(info.model)
        bdclose(info.model);
    end
    
    % 4. Build Case Summary Record
    s = struct();
    s.ID = cid;
    s.Name = C.Name;
    s.Topology = C.Topology;
    s.GAT_in = C.GAT_in;
    s.Converged = val.converged;
    s.Iterations = val.iterations;
    s.Solve_time_s = elapsed;
    
    s.Gen_P_MW = val.Pgen_MW;
    s.Gen_Q_MVAr = val.Qgen_MVAr;
    s.Gen_S_MVA = val.Sgen_MVA;
    s.Gen_PF = val.PFgen;
    s.Gen_PF_type = val.PF_type;
    s.Gen_V_pu = val.Vgen_pu;
    s.Gen_V_kV = val.Vgen_kV;
    
    s.V230_1_kV = val.V230_1_kV;
    s.V230_2_kV = val.V230_2_kV;
    s.V6_6_kV = val.V6_6_kV;
    
    s.Paux_MW = val.Paux_MW;
    s.Qaux_MVAr = val.Qaux_MVAr;
    s.Export_P_MW = val.Pgrid_export_MW;
    s.Export_Q_MVAr = val.Qgrid_export_MVAr;
    
    s.Loss_P_MW = val.total_system_losses_P_MW;
    s.Loss_Q_MVAr = val.total_system_losses_Q_MVAr;
    s.Loss_GSUT_MW = val.loss_GSUT_MW;
    s.Loss_UAT_MW = val.loss_UAT_MW;
    s.Loss_GAT_MW = val.loss_GAT_MW;
    s.Loading_GSUT_pct = val.loading_GSUT_pct;
    s.Loading_UAT_pct = val.loading_UAT_pct;
    s.Loading_GAT_pct = val.loading_GAT_pct;
    
    s.Worst_KCL_MVA = val.worst_KCL_MVA;
    s.P_balance_err_MW = val.P_balance_err_MW;
    s.Q_balance_err_MVAr = val.Q_balance_err_MVAr;
    
    s.Capability_status = val.capability_status;
    s.Qmax_allowed_MVAr = val.Qmax_allowed_MVAr;
    s.Qmin_allowed_MVAr = val.Qmin_allowed_MVAr;
    s.Q_upper_margin_MVAr = val.Q_upper_margin_MVAr;
    s.Q_lower_margin_MVAr = val.Q_lower_margin_MVAr;
    s.MVA_margin = val.MVA_margin;
    s.Q_clipped = val.Q_clipped;
    s.Verdict = val.verdict;
    
    % Print report line
    fprintf('  Pgen: %8.4f MW | Qgen: %8.4f MVAr | Sgen: %8.4f MVA | PF: %.4f (%s)\n', ...
        s.Gen_P_MW, s.Gen_Q_MVAr, s.Gen_S_MVA, s.Gen_PF, s.Gen_PF_type);
    fprintf('  Vgen: %6.4f pu (%5.2f kV) | V230: %5.2f kV | V6.6: %5.2f kV\n', ...
        s.Gen_V_pu, s.Gen_V_kV, s.V230_1_kV, s.V6_6_kV);
    fprintf('  Grid Export: %8.4f MW + j%8.4f MVAr | Losses: %7.4f MW + j%7.4f MVAr\n', ...
        s.Export_P_MW, s.Export_Q_MVAr, s.Loss_P_MW, s.Loss_Q_MVAr);
    fprintf('  Power Balance Error: P: %.2e MW, Q: %.2e MVAr | Worst KCL: %.2e MVA\n', ...
        s.P_balance_err_MW, s.Q_balance_err_MVAr, s.Worst_KCL_MVA);
    fprintf('  Capability: %s (Q margin: +%.2f / -%.2f MVAr, S margin: %.2f MVA)\n', ...
        s.Capability_status, s.Q_upper_margin_MVAr, s.Q_lower_margin_MVAr, s.MVA_margin);
    fprintf('  Verdict: %s (solved in %.2f s, %d iters)\n\n', s.Verdict, elapsed, s.Iterations);
    
    S = [S; s]; %#ok<AGROW>
    all_bus_results{end+1} = struct('case_id', cid, 'table', val.bus_results); %#ok<AGROW>
end

% 5. Write Artifacts to Disk
if opt.Write && ~isempty(S)
    write_summary_csv(fullfile(outDir, 'phase2_system_summary.csv'), S);
    write_power_balance_csv(fullfile(outDir, 'phase2_power_balance.csv'), S);
    write_capability_csv(fullfile(outDir, 'phase2_capability_check.csv'), S);
    write_bus_results_csv(fullfile(outDir, 'phase2_bus_results.csv'), all_bus_results);
    save(fullfile(outDir, 'phase2_loadflow_results.mat'), 'S', 'all_bus_results');
    fprintf('  Results successfully saved to %s\n\n', outDir);
end
end

function write_summary_csv(filepath, S)
fid = fopen(filepath, 'w');
if fid < 0, return; end
fprintf(fid, 'Case_ID,Case_Name,P_gen_MW,Q_gen_MVAr,S_gen_MVA,PF,PF_Type,V_gen_pu,V_gen_kV,V_230kV,V_6_6kV,P_aux_MW,Q_aux_MVAr,P_export_MW,Q_export_MVAr,Loss_P_MW,Loss_Q_MVAr,Worst_KCL_MVA,Capability_Status,Q_Upper_Margin_MVAr,Q_Lower_Margin_MVAr,MVA_Margin,Iterations,Verdict\n');
for i = 1:numel(S)
    fprintf(fid, '%s,"%s",%.6f,%.6f,%.6f,%.6f,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6e,%s,%.6f,%.6f,%.6f,%d,"%s"\n', ...
        S(i).ID, S(i).Name, S(i).Gen_P_MW, S(i).Gen_Q_MVAr, S(i).Gen_S_MVA, S(i).Gen_PF, S(i).Gen_PF_type, ...
        S(i).Gen_V_pu, S(i).Gen_V_kV, S(i).V230_1_kV, S(i).V6_6_kV, S(i).Paux_MW, S(i).Qaux_MVAr, ...
        S(i).Export_P_MW, S(i).Export_Q_MVAr, S(i).Loss_P_MW, S(i).Loss_Q_MVAr, S(i).Worst_KCL_MVA, ...
        S(i).Capability_status, S(i).Q_upper_margin_MVAr, S(i).Q_lower_margin_MVAr, S(i).MVA_margin, ...
        S(i).Iterations, S(i).Verdict);
end
fclose(fid);
end

function write_power_balance_csv(filepath, S)
fid = fopen(filepath, 'w');
if fid < 0, return; end
fprintf(fid, 'Case_ID,P_gen_MW,P_aux_MW,P_export_MW,P_loss_MW,P_balance_err_MW,Q_gen_MVAr,Q_aux_MVAr,Q_export_MVAr,Q_loss_MVAr,Q_balance_err_MVAr,Worst_KCL_MVA,Verdict\n');
for i = 1:numel(S)
    fprintf(fid, '%s,%.6f,%.6f,%.6f,%.6f,%.6e,%.6f,%.6f,%.6f,%.6f,%.6e,%.6e,"%s"\n', ...
        S(i).ID, S(i).Gen_P_MW, S(i).Paux_MW, S(i).Export_P_MW, S(i).Loss_P_MW, S(i).P_balance_err_MW, ...
        S(i).Gen_Q_MVAr, S(i).Qaux_MVAr, S(i).Export_Q_MVAr, S(i).Loss_Q_MVAr, S(i).Q_balance_err_MVAr, ...
        S(i).Worst_KCL_MVA, S(i).Verdict);
end
fclose(fid);
end

function write_capability_csv(filepath, S)
fid = fopen(filepath, 'w');
if fid < 0, return; end
fprintf(fid, 'Case_ID,P_gen_MW,Q_gen_MVAr,S_gen_MVA,PF,Qmax_allowed_MVAr,Qmin_allowed_MVAr,Q_upper_margin_MVAr,Q_lower_margin_MVAr,Snom_MVA,MVA_margin,Capability_Status,Q_Clipped\n');
for i = 1:numel(S)
    fprintf(fid, '%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.2f,%.6f,%s,%s\n', ...
        S(i).ID, S(i).Gen_P_MW, S(i).Gen_Q_MVAr, S(i).Gen_S_MVA, S(i).Gen_PF, ...
        S(i).Qmax_allowed_MVAr, S(i).Qmin_allowed_MVAr, S(i).Q_upper_margin_MVAr, S(i).Q_lower_margin_MVAr, ...
        458.0, S(i).MVA_margin, S(i).Capability_status, 'false');
end
fclose(fid);
end

function write_bus_results_csv(filepath, all_res)
fid = fopen(filepath, 'w');
if fid < 0, return; end
fprintf(fid, 'Case_ID,Bus_Name,Vnom_kV,V_pu,V_kV,Angle_deg,P_inj_MW,Q_inj_MVAr\n');
for c = 1:numel(all_res)
    cid = all_res{c}.case_id;
    tbl = all_res{c}.table;
    for b = 1:numel(tbl)
        fprintf(fid, '%s,%s,%.2f,%.6f,%.6f,%.4f,%.6f,%.6f\n', ...
            cid, tbl(b).Name, tbl(b).Vnom_V/1000, tbl(b).V_pu, tbl(b).V_kV, ...
            tbl(b).Ang_deg, tbl(b).P_inj_MW, tbl(b).Q_inj_MVAr);
    end
end
fclose(fid);
end
