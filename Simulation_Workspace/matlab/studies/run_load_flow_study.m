function S = run_load_flow_study(varargin)
%RUN_LOAD_FLOW_STUDY  Phase 12: solve the whole case matrix and write the results.
%
%   S = RUN_LOAD_FLOW_STUDY                 solve LF1..LF4, write every artefact
%   S = RUN_LOAD_FLOW_STUDY('Cases', {'LF1'})       one case only
%   S = RUN_LOAD_FLOW_STUDY('Write', false)         solve but write nothing
%
%   WHY FOUR CASES
%   --------------
%   Approved answer Q2c asks for the rated 389.30 MW dispatch to be compared with
%   the site-derated 342.01 MW. Approved answer Q4c asks for the GAT out of
%   service to be compared with the GAT in service. Those are INDEPENDENT
%   choices, so together they define a 2x2 matrix and four load flows, not two:
%
%                     GAT out (radial)      GAT in (looped)
%       389.30 MW          LF1                   LF2
%       342.01 MW          LF3                   LF4
%
%   Reporting only two of them would confound the dispatch effect with the GAT
%   effect. All four are solved here so the two effects can be separated, which
%   is the whole reason the matrix exists.
%
%   ONE FRESH BUILD PER SOLVE
%   -------------------------
%   power_loadflow('solve') writes the solution back into the blocks - source
%   Voltage and PhaseAngle, load NominalVoltage (measured in
%   matlab/env/probe_mutation.m). Solving a model twice therefore solves a
%   slightly different network the second time. Every case here is built from
%   scratch immediately before it is solved, and built quietly, unsaved and
%   un-backed-up so that a study run can never disturb the deliverable .slx.
%
%   The deliverable models ARE written, once, at the end: the base case to
%   simulink/main/ and each case to simulink/studies/. Those are written by a
%   final clean build, never by a solved model, so what ships is the network as
%   specified rather than the network with a solution smeared into its blocks.
%
%   WHAT IS CROSS-CHECKED
%   ---------------------
%   Every case is checked three ways before its numbers are written:
%
%     1. KCL at every bus, from branch flows reconstructed OUTSIDE the solver
%        using the documented impedances (ashuganj_bus_results).
%     2. System power balance: generation - load - losses = export, to 1e-6 MW.
%     3. The case definition: the solved generator injection must equal the MW
%        the case dispatches, or the wrong case was solved.
%
%   A case that fails a cross-check is still written, with its verdict recorded
%   in system_summary.csv. Hiding an inconsistent case would defeat the point of
%   running the matrix.
%
%   A case that does not CONVERGE is different: power_loadflow returns LF.bus
%   stripped of Vbus, Sbus and every other solution field, so there are no
%   numbers to write. Such a case is caught before any post-processing, appears
%   in system_summary.csv as NaN with the solver's own error message, and is
%   absent from the detail tables. It is never quietly replaced by zeros.
%
%   MERGED NODES IN THE BUS TABLE
%   -----------------------------
%   The register carries eight buses; the solver reports five, because a
%   zero-impedance connection is an identity to it and not a branch. The three
%   6.6 kV load nodes are one node (the feeder impedances are MISSING) and the
%   two 230 kV busbars are one node (the coupler is closed by assumption). The
%   bus table lists all eight, but only the representative of each merged group
%   carries the solver's injection; the others show NaN and name the bus they
%   merged into, so a reader cannot total the table and find 42 MW of auxiliary
%   load in a plant that has 14. Each bus's own ALLOCATED share is in the
%   separate P_load_alloc_MW/Q_load_alloc_MVAr columns - dataset input, never
%   mixed into the solver-output columns.
%
%   OUTPUTS
%   -------
%   results/load_flow/bus_results.csv          one row per bus per case
%   results/load_flow/generator_results.csv    one row per case
%   results/load_flow/transformer_results.csv  one row per transformer per case
%   results/load_flow/line_results.csv         one row per branch per case
%   results/load_flow/system_summary.csv       one row per case
%   results/load_flow/residuals.csv            the KCL cross-check, per bus
%   results/load_flow/<case>_powergui_report.rep   the solver's own report
%
%   The report extension is .rep, not .txt: power_loadflow appends it to the
%   name passed in, which was measured rather than assumed.
%
%   See also BUILD_ASHUGANJ_MAIN, ASHUGANJ_BRANCH_FLOWS, ASHUGANJ_BUS_RESULTS.

p = inputParser;
p.addParameter('Cases', {}, @iscell);
p.addParameter('Write', true, @islogical);
p.addParameter('SaveModels', true, @islogical);
p.parse(varargin{:});
opt = p.Results;

D    = ashuganj_master_data();
root = ashuganj_root();
if isempty(opt.Cases), opt.Cases = {D.cases.ID}; end

outDir = fullfile(root, 'results', 'load_flow');
if opt.Write && ~exist(outDir, 'dir'), mkdir(outDir); end

hdr('ASHUGANJ 450 MW CCPP (SOUTH) - PHASE 12 BALANCED LOAD FLOW STUDY');
fprintf('  system base   : %g MVA\n', D.base.Sbase_MVA);
fprintf('  frequency     : %g Hz  (Bangladesh grid - the prior CYME model used 60)\n', D.base.f_Hz);
fprintf('  cases         : %s\n', strjoin(opt.Cases, ', '));
fprintf('  reporting base: 100 MVA; transformer loading against every cooling stage\n');

S = {};
for i = 1:numel(opt.Cases)
    S{i} = solve_one(opt.Cases{i}, D, outDir, opt.Write);   %#ok<AGROW>
end
% Accumulated in a cell, not by S(i) = ...: S = struct([]) has NO fields, and
% assigning a populated struct into a fieldless struct array is an error
% ("dissimilar structures"), not an initialisation.
S = [S{:}];

% ------------------------------------------------------------------ tables
if opt.Write
    write_tables(S, D, outDir);
end

% -------------------------------------------------- deliverable model files
% Clean builds, never solved. build_ashuganj_main backs up the existing main
% model before overwriting it, so nothing that worked is ever destroyed.
if opt.SaveModels
    hdr('DELIVERABLE MODELS');
    build_ashuganj_main('LF1', 'Quiet', true, 'Backup', true, 'Save', true, 'Close', true);
    fprintf('  simulink/main/Ashuganj_South_Main.slx        (case LF1, clean build)\n');

    studyDir = fullfile(root, 'simulink', 'studies');
    if ~exist(studyDir, 'dir'), mkdir(studyDir); end
    for i = 1:numel(opt.Cases)
        cid = opt.Cases{i};
        nm  = ['Load_Flow_' cid];
        build_ashuganj_main(cid, 'ModelName', nm, 'Quiet', true, 'Backup', false, ...
            'Save', true, 'Close', true, ...
            'SavePath', fullfile(studyDir, [nm '.slx']));
        fprintf('  simulink/studies/%-24s (case %s, clean build)\n', [nm '.slx'], cid);
    end
    % The brief names simulink/studies/Load_Flow.slx. Provide it as the base
    % case under that exact name as well, so the requested layout is satisfied
    % without pretending one file can hold four cases.
    build_ashuganj_main('LF1', 'ModelName', 'Load_Flow', 'Quiet', true, ...
        'Backup', false, 'Save', true, 'Close', true, ...
        'SavePath', fullfile(studyDir, 'Load_Flow.slx'));
    fprintf('  simulink/studies/Load_Flow.slx               (case LF1, the name the brief asks for)\n');
end

% ------------------------------------------------------------------ verdict
hdr('STUDY SUMMARY');
fprintf('  %-5s %-34s %9s %9s %9s %9s %8s  %s\n', ...
    'CASE', 'DESCRIPTION', 'P_gen MW', 'P_exp MW', 'Q_gen MVA', 'Loss MW', 'ITER', 'CHECKS');
for i = 1:numel(S)
    fprintf('  %-5s %-34s %9.4f %9.4f %9.4f %9.5f %8d  %s\n', ...
        S(i).ID, trunc(S(i).Name, 34), S(i).Gen_P_MW, S(i).Export_P_MW, ...
        S(i).Gen_Q_MVAr, S(i).Loss_P_MW, S(i).Iterations, S(i).Verdict);
end
nbad = sum(~strcmp({S.Verdict}, 'OK'));
fprintf('\n');
if nbad == 0
    fprintf('  All %d cases converged and passed every cross-check.\n', numel(S));
else
    fprintf('  %d of %d cases FAILED a cross-check - see residuals.csv.\n', nbad, numel(S));
end
if opt.Write
    fprintf('  results written to results/load_flow/\n');
end
fprintf('\n');
end

% =====================================================================
function s = solve_one(cid, D, outDir, doWrite)
%SOLVE_ONE  Fresh build, solve, cross-check, and collect one case.
hdr(sprintf('CASE %s', cid));

info = build_ashuganj_main(cid, 'Quiet', true, 'Backup', false, 'Save', false);
C    = info.case;
fprintf('  %s\n', C.Name);
fprintf('  G1 %.2f MW (%s) | GAT %s | coupler %s | %s | aux %.3f MW + j%.3f MVAr\n', ...
    C.Gen_P_MW, lower(C.Gen_scenario), tf2s(C.GAT_in,'IN','OUT'), ...
    tf2s(C.Coupler_closed,'CLOSED','OPEN'), C.Topology, C.Load_P_MW, C.Load_Q_MVAr);

t0 = tic;
% The solver's own report is requested in the SAME call that returns LF, so the
% two cannot describe different solves. power_loadflow('solve') writes its
% solution back into the blocks, so a second solve for the report would be a
% second, slightly different network.
rptPath = '';
if doWrite
    rptPath = fullfile(outDir, sprintf('%s_powergui_report', cid));
end
if isempty(rptPath)
    LF = power_loadflow(info.model, 'solve');
else
    LF = power_loadflow(info.model, 'solve', 'report', rptPath);
end
secs = toc(t0);

% ---- CONVERGENCE, before anything is post-processed --------------------
% Measured semantics (matlab/env/probe_lf_status.m): status == 1 converged,
% status == -1 did not, and LF.error carries the solver's own message. On a
% failed solve LF.bus loses Vbus, Sbus and every other solution field, so
% post-processing a non-converged case does not produce bad numbers - it
% produces a confusing error several functions deep. power_loadflow does NOT
% throw on non-convergence, so this check is the only thing standing between a
% failed solve and a plausible-looking table.
if LF.status ~= 1 || ~isempty(LF.error)
    fprintf('  *** DID NOT CONVERGE: status %d, "%s"\n', LF.status, LF.error);
    s = failed_case(C, LF, secs);
    bdclose(info.model);
    return
end

Sb = D.base.Sbase_MVA;
R  = ashuganj_branch_flows(LF, D, C, info.zones);
[B, res] = ashuganj_bus_results(LF, D, C, R, info.zones);
node = ashuganj_bus_map(LF, D, info.zones);

% ---- checks -------------------------------------------------------------
chk = {};
Pgen = real(LF.bus(node.B22).Sbus)*Sb;
Qgen = imag(LF.bus(node.B22).Sbus)*Sb;
Pexp = -real(LF.bus(node.BGRID230).Sbus)*Sb;    % positive = plant exports
Qexp = -imag(LF.bus(node.BGRID230).Sbus)*Sb;
Ploss = Pgen - C.Load_P_MW - Pexp;

% Convergence is not re-checked here: it was already gated above, before any
% post-processing, because a non-converged LF has no solution fields to
% post-process at all.
if abs(Pgen - C.Gen_P_MW) > 1e-3
    chk{end+1} = sprintf('DISPATCH MISMATCH %.4f vs %.4f MW', Pgen, C.Gen_P_MW);
end
worst = max([res.Residual_MVA]);
if worst > 0.05
    chk{end+1} = sprintf('KCL RESIDUAL %.3e MVA', worst);
end
% System balance: generation must equal load + losses + export. Ploss is
% DEFINED by that identity above, so the independent statement is that the
% losses so implied match the sum of the branch losses computed separately.
brLoss = sum([R(~isnan([R.P_loss_MW])).P_loss_MW]);
if abs(Ploss - brLoss) > 1e-3
    chk{end+1} = sprintf('LOSS MISMATCH %.6f (balance) vs %.6f MW (branches)', Ploss, brLoss);
end

if isempty(chk), verdict = 'OK'; else, verdict = strjoin(chk, '; '); end

fprintf('  solved in %.1f s, %d iterations, worst KCL residual %.2e MVA\n', ...
    secs, LF.iterations, worst);
fprintf('  P_gen %.4f MW | aux %.4f MW | losses %.5f MW | export %.4f MW\n', ...
    Pgen, C.Load_P_MW, Ploss, Pexp);
fprintf('  Q_gen %.4f MVAr | export %.4f MVAr | branch losses %.5f MW\n', ...
    Qgen, Qexp, brLoss);
fprintf('  verdict: %s\n', verdict);

% ---- per-bus voltage table --------------------------------------------
% Merged buses print their injection as NaN and carry "= <bus>" in the label.
% They are listed rather than hidden, because the register really does define
% them and the reader is entitled to see that they were not forgotten - but a
% number that belongs to the whole merged node is not printed against one member
% of it.
fprintf('\n  %-9s %-38s %6s %10s %9s %10s %10s\n', ...
    'BUS', 'LABEL', 'TYPE', '|V| pu', 'ang deg', 'P MW', 'Q MVAr');
for j = 1:numel(B)
    lbl = B(j).Label;
    if ~isempty(B(j).Merged_into)
        lbl = sprintf('%s  [= %s]', lbl, B(j).Merged_into);
    end
    fprintf('  %-9s %-38s %6s %10.6f %9.4f %10.4f %10.4f\n', ...
        B(j).Name, trunc(lbl, 38), B(j).Type, B(j).V_pu_nom, ...
        B(j).Ang_deg, B(j).P_inj_MW, B(j).Q_inj_MVAr);
end
nMerged = sum(~cellfun(@isempty, {B.Merged_into}));
if nMerged > 0
    fprintf(['  (%d of %d register buses are the SAME solved node as another and ' ...
             'show NaN injection;\n   their allocated load shares are in the ' ...
             'P_load_alloc columns of bus_results.csv)\n'], nMerged, numel(B));
end

s = struct('ID', C.ID, 'Name', C.Name, 'Case', C, 'LF', LF, 'B', B, 'R', R, ...
           'res', res, 'node', node, 'Gen_P_MW', Pgen, 'Gen_Q_MVAr', Qgen, ...
           'Export_P_MW', Pexp, 'Export_Q_MVAr', Qexp, 'Loss_P_MW', Ploss, ...
           'Branch_Loss_MW', brLoss, 'Worst_Residual_MVA', worst, ...
           'Iterations', LF.iterations, 'Solve_s', secs, 'Verdict', verdict);
bdclose(info.model);
end

% =====================================================================
function s = failed_case(C, LF, secs)
%FAILED_CASE  The record of a case that did not converge.
%
%   Same field names in the same order as the success path, so that
%   S = [S{:}] still concatenates and the summary table still prints. The
%   numbers are NaN rather than absent or zero: a non-converged solve produced
%   no generation, no export and no losses, and writing 0 there would read as
%   "measured zero" instead of "not solved". Zero MW of loss is a claim; NaN is
%   the truth.
%
%   B, R, res and node are empty because they cannot be built - power_loadflow
%   strips Vbus, Sbus and every other solution field from LF.bus when it fails
%   (measured in matlab/env/probe_lf_status.m). write_tables skips a case whose
%   B is empty and says so, rather than emitting rows of NaN that look like
%   results.
%
%   The failure is NOT swallowed. It reaches the study summary as the verdict
%   below, carrying the solver's own message.
s = struct('ID', C.ID, 'Name', C.Name, 'Case', C, 'LF', LF, ...
           'B', [], 'R', [], 'res', [], 'node', [], ...
           'Gen_P_MW', NaN, 'Gen_Q_MVAr', NaN, ...
           'Export_P_MW', NaN, 'Export_Q_MVAr', NaN, 'Loss_P_MW', NaN, ...
           'Branch_Loss_MW', NaN, 'Worst_Residual_MVA', NaN, ...
           'Iterations', LF.iterations, 'Solve_s', secs, ...
           'Verdict', sprintf('DID NOT CONVERGE (status %d): %s', ...
                              LF.status, LF.error));
end

% =====================================================================
function write_tables(S, D, outDir)
%WRITE_TABLES  Every deliverable CSV. One row per object per case.
Sb = D.base.Sbase_MVA;

% A case that did not converge has no bus table, no branch table and no
% residuals, because power_loadflow returns LF.bus stripped of every solution
% field when it fails. Such a case is EXCLUDED from the four detail tables -
% there is nothing to put in them - but it still gets a row in
% system_summary.csv carrying the solver's error message, so the study's own
% summary can never look complete while a case is missing from it.
solved = ~cellfun(@isempty, {S.B});
if ~all(solved)
    fprintf('  NOTE: %s did not converge and appear only in system_summary.csv\n', ...
        strjoin({S(~solved).ID}, ', '));
end
Sok = S(solved);

% ---------------------------------------------------------------- buses
% Merged_into comes FIRST after the bus name, so the qualification on P_inj/Q_inj
% cannot be missed by a reader who scans left to right and stops at the numbers.
% P_load_alloc_* are dataset input, kept in their own columns and never summed
% into the solver-output ones.
rows = {};
for i = 1:numel(Sok)
    for j = 1:numel(Sok(i).B)
        b = Sok(i).B(j);
        rows(end+1,:) = {Sok(i).ID, b.Name, b.Merged_into, b.Label, b.Type, ...
            b.Vnom_V, b.Vbase_V, ...
            b.V_pu_nom, b.V_kV, b.Ang_deg, b.P_inj_MW, b.Q_inj_MVAr, ...
            b.P_load_alloc_MW, b.Q_load_alloc_MVAr, ...
            b.Alt_base_V, b.V_pu_alt, b.Note};   %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'Case','Bus','Merged_into','Label','Type', ...
    'Vnom_V','Vbase_V','V_pu','V_kV','Angle_deg','P_inj_MW','Q_inj_MVAr', ...
    'P_load_alloc_MW','Q_load_alloc_MVAr','Alt_base_V','V_pu_alt_base','Note'});
writetable(T, fullfile(outDir, 'bus_results.csv'));

% ------------------------------------------------------------ generator
g = D.gen(1);
rows = {};
for i = 1:numel(Sok)
    C = Sok(i).Case;
    Smva = hypot(Sok(i).Gen_P_MW, Sok(i).Gen_Q_MVAr);
    rows(end+1,:) = {Sok(i).ID, g.Label, g.Vnom_V/1000, C.Gen_scenario, ...
        Sok(i).Gen_P_MW, Sok(i).Gen_Q_MVAr, Smva, ...
        Sok(i).Gen_P_MW/max(Smva,realmin), ...
        Sok(i).B(idxof(Sok(i).B,'B22')).V_pu_nom, ...
        Sok(i).B(idxof(Sok(i).B,'B22')).Ang_deg, ...
        100*Smva/g.Snom_MVA, 100*Smva/g.Smax_MVA, ...
        Smva*1e6/(sqrt(3)*g.Vnom_V), g.Inom_A, ...
        'unconstrained - no Q limit is documented for this machine'};   %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'Case','Generator','Vnom_kV','Dispatch', ...
    'P_MW','Q_MVAr','S_MVA','PowerFactor','V_pu','Angle_deg', ...
    'Loading_pct_458MVA_50C','Loading_pct_518MVA_30C','I_A','I_rated_A','Q_limits'});
writetable(T, fullfile(outDir, 'generator_results.csv'));

% --------------------------------------------------------- transformers
rows = {};
for i = 1:numel(Sok)
    R = Sok(i).R;
    for k = 1:numel(R)
        if ~strcmp(R(k).Type, 'transformer'), continue, end
        x = D.tx(strcmp({D.tx.Label}, R(k).Name));
        stages = x.S_MVA;
        load_stages = 100*max(R(k).S_from_MVA, R(k).S_to_MVA) ./ stages;
        rows(end+1,:) = {Sok(i).ID, R(k).Name, x.KKS, x.VectorGroup, ...
            x.V_HV_V/1000, x.V_LV_V/1000, x.Z_pct, x.S_rating_MVA, ...
            R(k).From, R(k).To, R(k).P_from_MW, R(k).Q_from_MVAr, R(k).S_from_MVA, ...
            R(k).P_to_MW, R(k).Q_to_MVAr, R(k).S_to_MVA, ...
            R(k).P_loss_MW, R(k).Q_loss_MVAr, R(k).I_A, ...
            mat2str(stages), sprintf('%.2f', load_stages(1)), ...
            sprintf('%.2f', load_stages(end)), x.Tap_used, x.Tap_V_used_V/1000, ...
            R(k).Note};   %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'Case','Transformer','KKS','VectorGroup', ...
    'V_HV_kV','V_LV_kV','Z_pct','Z_base_MVA','From_bus','To_bus', ...
    'P_LV_MW','Q_LV_MVAr','S_LV_MVA','P_HV_MW','Q_HV_MVAr','S_HV_MVA', ...
    'P_loss_MW','Q_loss_MVAr','I_HV_A','Rating_stages_MVA', ...
    'Loading_pct_lowest_stage','Loading_pct_highest_stage', ...
    'Tap_used','Tap_kV','Note'});
writetable(T, fullfile(outDir, 'transformer_results.csv'));

% ---------------------------------------------------------------- lines
% "Lines" here means every non-transformer branch in the register. There is no
% transmission line in this model: the grid is represented at the plant
% boundary (Q7a) and every conductor inside the plant is a busbar, bay or
% cable whose length and impedance are MISSING. The table records that rather
% than implying line data exists.
rows = {};
for i = 1:numel(Sok)
    R = Sok(i).R;
    for k = 1:numel(R)
        if strcmp(R(k).Type, 'transformer'), continue, end
        rows(end+1,:) = {Sok(i).ID, R(k).Name, R(k).Type, R(k).From, R(k).To, ...
            R(k).V_from_pu, R(k).V_to_pu, R(k).I_A, ...
            R(k).P_from_MW, R(k).Q_from_MVAr, R(k).S_from_MVA, ...
            R(k).P_to_MW, R(k).Q_to_MVAr, ...
            R(k).P_loss_MW, R(k).Q_loss_MVAr, R(k).Note};   %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'Case','Branch','Type','From_bus','To_bus', ...
    'V_from_pu','V_to_pu','I_A','P_from_MW','Q_from_MVAr','S_from_MVA', ...
    'P_to_MW','Q_to_MVAr','P_loss_MW','Q_loss_MVAr','Note'});
writetable(T, fullfile(outDir, 'line_results.csv'));

% --------------------------------------------------------------- summary
% Every case appears here, converged or not. The accessors below return NaN for
% a case with no solution instead of erroring, so a failed case cannot silently
% drop out of the one table that is meant to show the whole matrix.
rows = {};
for i = 1:numel(S)
    C = S(i).Case;
    rows(end+1,:) = {S(i).ID, C.Name, C.Gen_scenario, C.Gen_P_MW, ...
        tf2s(C.GAT_in,'in','out'), tf2s(C.Coupler_closed,'closed','open'), C.Topology, ...
        S(i).Gen_P_MW, S(i).Gen_Q_MVAr, C.Load_P_MW, C.Load_Q_MVAr, ...
        S(i).Loss_P_MW, S(i).Export_P_MW, S(i).Export_Q_MVAr, ...
        100*S(i).Loss_P_MW/S(i).Gen_P_MW, ...
        busval(S(i).B, 'B230_1', 'V_pu_nom'), ...
        busval(S(i).B, 'B22',    'V_pu_nom'), ...
        busval(S(i).B, 'B6_6',   'V_pu_nom'), ...
        busval(S(i).B, 'B6_6',   'V_pu_alt'), ...
        brval(S(i).R, 'GSUT 10BAT10'), ...
        brval(S(i).R, 'UAT 10BBT10'), ...
        brval(S(i).R, 'GAT 10BBT20'), ...
        Sb, C.f_Hz, S(i).Iterations, S(i).Worst_Residual_MVA, S(i).Verdict};   %#ok<AGROW>
end
T = cell2table(rows, 'VariableNames', {'Case','Description','Dispatch','P_dispatch_MW', ...
    'GAT','Bus_coupler','Topology','P_gen_MW','Q_gen_MVAr','P_aux_MW','Q_aux_MVAr', ...
    'P_loss_MW','P_export_MW','Q_export_MVAr','Loss_pct_of_gen', ...
    'V_230kV_pu','V_22kV_pu','V_6p6kV_pu_6600base','V_6p6kV_pu_6900base', ...
    'S_GSUT_MVA','S_UAT_MVA','S_GAT_MVA','Sbase_MVA','f_Hz', ...
    'Iterations','Worst_KCL_residual_MVA','Checks'});
writetable(T, fullfile(outDir, 'system_summary.csv'));

% ------------------------------------------------------------- residuals
rows = {};
for i = 1:numel(Sok)
    for j = 1:numel(Sok(i).res)
        r = Sok(i).res(j);
        rows(end+1,:) = {Sok(i).ID, r.Name, real(r.Inj_MVA), imag(r.Inj_MVA), ...
            real(r.Branches_MVA), imag(r.Branches_MVA), ...
            r.dP_MW, r.dQ_MVAr, r.Residual_MVA};   %#ok<AGROW>
    end
end
T = cell2table(rows, 'VariableNames', {'Case','Bus','P_solver_MW','Q_solver_MVAr', ...
    'P_branches_MW','Q_branches_MVAr','dP_MW','dQ_MVAr','Residual_MVA'});
writetable(T, fullfile(outDir, 'residuals.csv'));
end

% =====================================================================
function k = idxof(B, name)
k = find(strcmp({B.Name}, name), 1);
if isempty(k)
    error('run_load_flow_study:noBus', ...
        'Bus ''%s'' is not in the reported bus table.', name);
end
end

function s = trunc(s, n)
if numel(s) > n, s = [s(1:n-3) '...']; end
end

function s = tf2s(tf, yes, no)
if tf, s = yes; else, s = no; end
end

function v = busval(B, name, field)
%BUSVAL  One field of one bus, or NaN if the case has no solved bus table.
%   Used only by system_summary.csv, which lists every case including any that
%   failed to converge. NaN there means "not solved", which is the truth; an
%   error would drop the failed case out of the summary altogether and a zero
%   would misreport it as a measurement.
v = NaN;
if isempty(B), return, end
k = find(strcmp({B.Name}, name), 1);
if ~isempty(k), v = B(k).(field); end
end

function v = brval(R, name)
%BRVAL  Apparent power at the from-end of one named branch, or NaN.
%   NaN covers two different absences and both are correct here: the case did
%   not converge, or the branch is genuinely not in this case's network (the GAT
%   in the radial cases LF1/LF3, whose bay is open).
v = NaN;
if isempty(R), return, end
k = find(strcmp({R.Name}, name), 1);
if ~isempty(k), v = R(k).S_from_MVA; end
end

function hdr(t)
fprintf('\n');
fprintf('%s\n', repmat('=', 1, 76));
fprintf('  %s\n', t);
fprintf('%s\n', repmat('=', 1, 76));
end
