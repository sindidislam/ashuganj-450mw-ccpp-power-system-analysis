function [np, nf] = test_phase4_registry()
%TEST_PHASE4_REGISTRY  Phase-4 canonical parameter registry holds frozen
%   Phase-3 values and Phase-4 design inputs with provenance, and keeps
%   MISSING parameters MISSING (NaN, present and explicit).
%
%   Spec: Secs 3/5/25. Design-defined peak wording; no IEC claims anywhere.

T = t_case('test_phase4_registry');
R = phase4_registry();

% ---- frozen Phase-3 interface (Sec 3: DO NOT CHANGE THESE VALUES) -------
T = T.eq(R.frozen.Zbase_ohm.value, 529, 'Zbase frozen 529 ohm');
T = T.eq(R.frozen.R_eq_ohm.value, 0.0277725, 'R_eq frozen 0.0277725 ohm');
T = T.eq(R.frozen.X_eq_ohm.value, 0.1425655, 'X_eq frozen 0.1425655 ohm');
T = T.eq(R.frozen.B_eq_uS.value, 3.937996, 'B_eq frozen 3.937996 uS');
T = T.eq(R.frozen.length_km.value, 0.7, 'length locked 0.7 km');
T = T.eq(R.frozen.circuits.value, 2, 'two circuits locked');

% ---- machine reactances: X2 is a DISTINCT cell from Xdpp_sat ------------
T = T.eq(R.machine.Xdpp_sat.value, 0.2248, 'Xdpp_sat primary 0.2248');
T = T.eq(R.machine.X2.value, 0.2242, 'X2 0.2242 distinct from Xdpp_sat');
T = T.eq(R.machine.X0.value, 0.128, 'X0 0.128 workbook project data');

% ---- MISSING stays MISSING: NaN, present and explicit --------------------
T = T.isnan(R.gat.Z_PT.value, 'GAT Z_PT stays MISSING NaN');
T = T.isnan(R.gat.Z_ST.value, 'GAT Z_ST stays MISSING NaN');
T = T.isnan(R.line.R0_ohm.value, 'South R0 point value stays MISSING NaN');
T = T.isnan(R.line.X0_ohm.value, 'South X0 point value stays MISSING NaN');
T = T.isnan(R.ngt.Z_series_HV.value, 'NGT series-Z stays MISSING NaN');
T = T.isnan(R.uat.ZN_LV_device.value, 'UAT LV-neutral device stays MISSING NaN');
T = T.isnan(R.gat.ZN_LV_device.value, 'GAT LV-neutral device stays MISSING NaN');
T = T.isnan(R.gat.ZN_HV_device.value, 'GAT HV-neutral device stays MISSING NaN');

% ---- B_eq cross-check: recompute from the frozen L_LINE C_F ---------------
L = ashuganj_lines();
kL = find(strcmp({L.Name}, 'L_LINE'), 1);
T = T.chk(~isempty(kL), 'L_LINE present for B_eq cross-check');
T = T.near(2*pi*50*L(kL).C_F*1e6, R.frozen.B_eq_uS.value, 1e-9, 'B_eq matches C_F-derived susceptance');

% ---- grid datasets separate ----------------------------------------------
T = T.eq(R.grid.P.Ik_kA.value, 50, 'dataset P 50 kA estimated');
T = T.eq(R.grid.S.XoR.value, 10.99, 'dataset S X/R 10.99 legacy');

[np, nf] = T.done();
end
