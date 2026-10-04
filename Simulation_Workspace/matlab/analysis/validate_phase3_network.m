function val = validate_phase3_network(LF, D, C, info)
val = struct(); val.case_id = C.ID; val.case_name = C.Name;
val.converged = (LF.status == 1 && isempty(LF.error));
val.iterations = LF.iterations;
if ~val.converged, val.verdict = 'DID_NOT_CONVERGE'; val.status = 'FAILED'; return; end
Sb = D.base.Sbase_MVA;
node = ashuganj_bus_map(LF, D, info.zones);
val.Pgen_MW = real(LF.bus(node.B22).Sbus)*Sb;
val.Qgen_MVAr = imag(LF.bus(node.B22).Sbus)*Sb;
val.Sgen_MVA = abs(LF.bus(node.B22).Sbus)*Sb;
val.PFgen = abs(val.Pgen_MW)/val.Sgen_MVA;
val.PF_type = 'Lagging'; if val.Qgen_MVAr < 0, val.PF_type = 'Leading'; end
val.Paux_MW = C.Load_P_MW; val.Qaux_MVAr = C.Load_Q_MVAr;
val.Vgen_pu = abs(LF.bus(node.B22).Vbus); val.Vgen_kV = val.Vgen_pu*22.0;
val.V230_1_pu = abs(LF.bus(node.B230_1).Vbus); val.V230_1_kV = val.V230_1_pu*230.0;
val.V230_2_pu = abs(LF.bus(node.B230_2).Vbus); val.V230_2_kV = val.V230_2_pu*230.0;
val.V6_6_pu = abs(LF.bus(node.B6_6).Vbus); val.V6_6_kV = val.V6_6_pu*6.6;
val.V_REMOTE_pu = abs(LF.bus(node.B230_REMOTE).Vbus); % solver-base pu (determinism reads this; do not renormalise)
R = ashuganj_branch_flows(LF, D, C, info.zones);
[B, res] = ashuganj_bus_results(LF, D, C, R, info.zones);
val.branch_flows = R; val.bus_results = B; val.residuals = res;
ib = find(strcmp({B.Name},'B230_REMOTE'),1); % reporting only: B230_REMOTE vbase is 100 kV block-default, so Vpu*230 mis-scales (~528 kV); bus V_kV is correct
val.V_REMOTE_kV = B(ib).V_kV;
ok = ~isnan([R.P_loss_MW]);
val.branch_losses_P_MW = sum([R(ok).P_loss_MW]);
val.branch_losses_Q_MVAr = sum([R(ok).Q_loss_MVAr]);
il = find(strcmp({R.Name},'L_LINE'),1);
if isempty(il), val.line_P_loss_MW = NaN; val.line_Q_loss_MVAr = NaN;
else, val.line_P_loss_MW = R(il).P_loss_MW; val.line_Q_loss_MVAr = R(il).Q_loss_MVAr; end
val.Pgrid_export_MW = -real(LF.bus(node.BGRID230).Sbus)*Sb;
val.Qgrid_export_MVAr = -imag(LF.bus(node.BGRID230).Sbus)*Sb;
val.P_balance_err_MW = abs(val.Pgen_MW-(val.Paux_MW+val.Pgrid_export_MW+val.branch_losses_P_MW));
val.Q_balance_err_MVAr = abs(val.Qgen_MVAr-(val.Qaux_MVAr+val.Qgrid_export_MVAr+val.branch_losses_Q_MVAr));
val.worst_KCL_MVA = max([res.Residual_MVA]);
cap = check_generator_operating_point(val.Pgen_MW, val.Qgen_MVAr, D.gen(1).Snom_MVA, D.gen(1).capabilityCurve);
val.capability_status = cap.status; val.Qmax_allowed_MVAr = cap.Qmax_allowed_MVAr;
val.Qmin_allowed_MVAr = cap.Qmin_allowed_MVAr; val.Q_upper_margin_MVAr = cap.Q_upper_margin_MVAr;
val.Q_lower_margin_MVAr = cap.Q_lower_margin_MVAr; val.MVA_margin = cap.MVA_margin; val.Q_clipped = cap.Q_clipped;
issues = {};
if abs(val.Pgen_MW-C.Gen_P_MW) > 1e-3, issues{end+1} = 'DISPATCH_MISMATCH'; end
if val.worst_KCL_MVA > 0.05, issues{end+1} = sprintf('KCL_RESIDUAL_HIGH (%.3e MVA)',val.worst_KCL_MVA); end
if val.P_balance_err_MW > 1e-3, issues{end+1} = sprintf('ACTIVE_BALANCE_MISMATCH (err %.6f MW)',val.P_balance_err_MW); end
if val.Q_balance_err_MVAr > 1e-3, issues{end+1} = sprintf('REACTIVE_BALANCE_MISMATCH (err %.6f MVAr)',val.Q_balance_err_MVAr); end
if ~strcmp(val.capability_status,'WITHIN_CAPABILITY'), issues{end+1} = ['CAPABILITY_' val.capability_status]; end
if isempty(issues), val.verdict = 'OK'; else, val.verdict = strjoin(issues,'; '); end
val.status = 'OK';
end
