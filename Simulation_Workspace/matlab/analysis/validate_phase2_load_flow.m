function val = validate_phase2_load_flow(LF, D, C, info)
%VALIDATE_PHASE2_LOAD_FLOW Independent verification of Phase 2 load flow.
%   val = VALIDATE_PHASE2_LOAD_FLOW(LF, D, C, info) performs comprehensive
%   independent cross-checks on solved load-flow LF per Prompt §35 and §36:
%   1. Solver convergence gating
%   2. Bus voltage extraction (22 kV, 230 kV, 6.6 kV)
%   3. Independent reconstruction of branch flows & transformer losses
%   4. Independent active power balance: Pgen = Paux + Pgrid + Ploss
%   5. Independent reactive power balance: Qgen = Qaux + Qgrid + Qloss
%   6. KCL residual verification at all buses
%   7. Generator P-Q capability curve operating-point evaluation (Prompt §9)
%   8. Strict non-clipping policy check (Prompt §10)

val = struct();
val.case_id = C.ID;
val.case_name = C.Name;

% 1. Convergence Gate
val.converged = (LF.status == 1 && isempty(LF.error));
val.iterations = LF.iterations;
val.solver_error = LF.error;

if ~val.converged
    val.verdict = 'DID_NOT_CONVERGE';
    val.status = 'FAILED';
    return;
end

Sb = D.base.Sbase_MVA;
node = ashuganj_bus_map(LF, D, info.zones);

% 2. Generator Operating Quantities
val.Pgen_MW = real(LF.bus(node.B22).Sbus) * Sb;
val.Qgen_MVAr = imag(LF.bus(node.B22).Sbus) * Sb;
val.Sgen_MVA = sqrt(val.Pgen_MW^2 + val.Qgen_MVAr^2);
val.PFgen = abs(val.Pgen_MW) / val.Sgen_MVA;
if val.Qgen_MVAr >= 0
    val.PF_type = 'Lagging';
else
    val.PF_type = 'Leading';
end

% 3. Grid Export / Boundary Quantities
val.Pgrid_export_MW = -real(LF.bus(node.BGRID230).Sbus) * Sb;
val.Qgrid_export_MVAr = -imag(LF.bus(node.BGRID230).Sbus) * Sb;

% 4. Auxiliary Load
val.Paux_MW = C.Load_P_MW;
val.Qaux_MVAr = C.Load_Q_MVAr;

% 5. Bus Voltages (magnitudes and angles from complex phasors)
val.Vgen_pu = abs(LF.bus(node.B22).Vbus);
val.Vgen_kV = val.Vgen_pu * 22.0;
val.Vgen_angle_deg = angle(LF.bus(node.B22).Vbus) * 180 / pi;

val.V230_1_pu = abs(LF.bus(node.B230_1).Vbus);
val.V230_1_kV = val.V230_1_pu * 230.0;
val.V230_1_angle_deg = angle(LF.bus(node.B230_1).Vbus) * 180 / pi;

val.V230_2_pu = abs(LF.bus(node.B230_2).Vbus);
val.V230_2_kV = val.V230_2_pu * 230.0;
val.V230_2_angle_deg = angle(LF.bus(node.B230_2).Vbus) * 180 / pi;

val.V6_6_pu = abs(LF.bus(node.B6_6).Vbus);
val.V6_6_kV = val.V6_6_pu * 6.6;
val.V6_6_angle_deg = angle(LF.bus(node.B6_6).Vbus) * 180 / pi;

% 6. Independent Branch Flow and Loss Reconstruction
R = ashuganj_branch_flows(LF, D, C, info.zones);
[B, res] = ashuganj_bus_results(LF, D, C, R, info.zones);
val.branch_flows = R;
val.bus_results = B;
val.residuals = res;

% Sum branch active & reactive losses
valid_br = ~isnan([R.P_loss_MW]);
val.branch_losses_P_MW = sum([R(valid_br).P_loss_MW]);
val.branch_losses_Q_MVAr = sum([R(valid_br).Q_loss_MVAr]);

% Transformer-specific losses
idx_gsut = find(strcmp({R.Name}, 'GSUT 10BAT10'), 1);
idx_uat = find(strcmp({R.Name}, 'UAT 10BBT10'), 1);
idx_gat = find(strcmp({R.Name}, 'GAT 10BBT20'), 1);

val.loss_GSUT_MW = 0; val.loading_GSUT_pct = 0; val.S_GSUT_MVA = 0;
if ~isempty(idx_gsut)
    val.loss_GSUT_MW = R(idx_gsut).P_loss_MW;
    val.loading_GSUT_pct = R(idx_gsut).Loading_pct;
    val.S_GSUT_MVA = R(idx_gsut).S_from_MVA;
end

val.loss_UAT_MW = 0; val.loading_UAT_pct = 0; val.S_UAT_MVA = 0;
if ~isempty(idx_uat)
    val.loss_UAT_MW = R(idx_uat).P_loss_MW;
    val.loading_UAT_pct = R(idx_uat).Loading_pct;
    val.S_UAT_MVA = R(idx_uat).S_from_MVA;
end

val.loss_GAT_MW = 0; val.loading_GAT_pct = 0; val.S_GAT_MVA = 0;
if ~isempty(idx_gat) && C.GAT_in
    val.loss_GAT_MW = R(idx_gat).P_loss_MW;
    val.loading_GAT_pct = R(idx_gat).Loading_pct;
    val.S_GAT_MVA = R(idx_gat).S_from_MVA;
end

val.transformer_losses_P_MW = val.loss_GSUT_MW + val.loss_UAT_MW + val.loss_GAT_MW;
val.total_system_losses_P_MW = val.branch_losses_P_MW;
val.total_system_losses_Q_MVAr = val.branch_losses_Q_MVAr;

% 7. Independent Active and Reactive Power Balance (Prompt §36)
% Theoretical P balance: Pgen = Paux + Pgrid + Ploss
P_expected = val.Paux_MW + val.Pgrid_export_MW + val.branch_losses_P_MW;
val.P_balance_err_MW = abs(val.Pgen_MW - P_expected);

% Theoretical Q balance: Qgen = Qaux + Qgrid + Qloss
Q_expected = val.Qaux_MVAr + val.Qgrid_export_MVAr + val.branch_losses_Q_MVAr;
val.Q_balance_err_MVAr = abs(val.Qgen_MVAr - Q_expected);

% Worst KCL residual
val.worst_KCL_MVA = max([res.Residual_MVA]);

% 8. Capability Curve Operating Point Check (Prompt §9 & §10)
cap = check_generator_operating_point(val.Pgen_MW, val.Qgen_MVAr, D.gen(1).Snom_MVA, D.gen(1).capabilityCurve);
val.capability_status = cap.status;
val.Qmax_allowed_MVAr = cap.Qmax_allowed_MVAr;
val.Qmin_allowed_MVAr = cap.Qmin_allowed_MVAr;
val.Q_upper_margin_MVAr = cap.Q_upper_margin_MVAr;
val.Q_lower_margin_MVAr = cap.Q_lower_margin_MVAr;
val.MVA_margin = cap.MVA_margin;
val.Q_clipped = cap.Q_clipped; % Strictly false per Prompt §10

% 9. Cross-Check Verdict Compilation
issues = {};
if abs(val.Pgen_MW - C.Gen_P_MW) > 1e-3
    issues{end+1} = sprintf('DISPATCH_MISMATCH (%.4f vs %.4f MW)', val.Pgen_MW, C.Gen_P_MW);
end
if val.worst_KCL_MVA > 0.05
    issues{end+1} = sprintf('KCL_RESIDUAL_HIGH (%.3e MVA)', val.worst_KCL_MVA);
end
if val.P_balance_err_MW > 1e-3
    issues{end+1} = sprintf('ACTIVE_BALANCE_MISMATCH (err %.6f MW)', val.P_balance_err_MW);
end
if val.Q_balance_err_MVAr > 1e-3
    issues{end+1} = sprintf('REACTIVE_BALANCE_MISMATCH (err %.6f MVAr)', val.Q_balance_err_MVAr);
end
if ~strcmp(val.capability_status, 'WITHIN_CAPABILITY')
    issues{end+1} = sprintf('CAPABILITY_%s', val.capability_status);
end

if isempty(issues)
    val.verdict = 'OK';
else
    val.verdict = strjoin(issues, '; ');
end
end
