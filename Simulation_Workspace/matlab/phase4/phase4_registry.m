function R = phase4_registry()
%PHASE4_REGISTRY  Canonical Phase-4 parameter registry (M1 foundation).
%
%   R = PHASE4_REGISTRY() returns every Phase-4 design input as a named
%   struct field carrying value + unit + base + status + source + locator +
%   rationale + variant ID. No hard-coded fault-study literals may live
%   anywhere else: M1-M8 read constants from here.
%
%   Frozen Phase-3 numbers are CROSS-CHECKED at runtime against
%   matlab/data/ashuganj_lines.m (read-only). A mismatch is an error(),
%   never a silent redefinition: this function asserts the freeze, it does
%   not own it.
%
%   MISSING parameters are present with value = NaN (explicit, never []).
%
%   Spec: Secs 3/5/25. Status enum closed: SOURCE/PRIMARY, DERIVED,
%   ENGINEERING_ASSUMPTION, HISTORICAL, LEGACY, MISSING.

R = struct();

% ---- frozen Phase-3 interface (Sec 3) ------------------------------------
R.frozen.Sbase_MVA       = e(100, 'MVA', 'system', 'DERIVED', 'PHASE3_FINAL_REPORT.md:53,61', 'frozen arithmetic V^2/S', 'base');
R.frozen.Vbase_kV        = e(230, 'kV', 'system', 'DERIVED', 'PHASE3_FINAL_REPORT.md:53,61', 'frozen nominal', 'base');
R.frozen.Zbase_ohm       = e(529, 'ohm', '100MVA-230kV', 'DERIVED', 'PHASE3_FINAL_REPORT.md:53,61', 'frozen arithmetic 230^2/100', 'base');
R.frozen.Zbase_22_ohm    = e(4.84, 'ohm', '100MVA-22kV', 'DERIVED', '22^2/100 arithmetic', 'level base for 22-kV Zfpu reporting (spec Sec 21)', 'base');
R.lv.Vbus_kV    = e(6.6, 'kV', 'physical', 'SOURCE/PRIMARY', 'phase3_bus_results.csv Vnom_kV column (B6_6 rows)', 'plant MV bus nominal; pu base voltage of LV zone', 'base');
R.lv.Vwind_kV   = e(6.9, 'kV', 'physical', 'SOURCE/PRIMARY', 'UAT/GAT data sheets (LV winding rating)', 'transformer LV winding nominal; distinct from 6.6-kV bus', 'base');
R.lv.Zbase_ohm  = e(0.4356, 'ohm', '100MVA-6.6kV', 'DERIVED', '6.6^2/100 arithmetic', 'ohmic base of the LV zone; aux/neutral pu conversions use this, never 529', 'base');
R.lv.a_nominal  = e(6.9/6.6, 'dimensionless', 'physical', 'DERIVED', 'Vwind/Vbus nominal documented ratio', 'off-nominal LV tap magnitude; no operating-tap invention (correction record)', 'base');
R.frozen.R1_pu_km        = e(0.00015, 'pu/km', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:53,61; ashuganj_lines.m:79', 'Mallard family ref, file MISSING, never PRIMARY', 'base');
R.frozen.X1_pu_km        = e(0.00077, 'pu/km', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:53,61; ashuganj_lines.m:81', 'Mallard family ref, file MISSING, never PRIMARY', 'base');
R.frozen.Y1_pu_km        = e(0.001488, 'pu/km', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:53,61 (report only)', 'Y1 locator is REPORT ONLY, no .m literal', 'base');
R.frozen.R_eq_ohm        = e(0.0277725, 'ohm', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:78', 'locked lumped D/C equivalent R_eq = r1*L/2', 'base');
R.frozen.X_eq_ohm        = e(0.1425655, 'ohm', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:80', 'locked lumped equivalent X_eq = x1*L/2', 'base');
R.frozen.B_eq_uS         = e(3.937996, 'microS', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:19,61; ashuganj_lines.m:82-83', 'locked equivalent B_eq = 2*b1*L at 50 Hz', 'base');
R.frozen.length_km       = e(0.7, 'km', 'physical', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:49,61; ashuganj_lines.m:71', 'locked GIS-to-grid length; INEL-0026 unavailable', 'base');
R.frozen.circuits        = e(2, 'count', 'physical', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:49; ashuganj_lines.m:74-75', '2 circuits both in service, LUMPED_DUAL_CIRCUIT_PI', 'base');
R.frozen.conductor_ref   = e('MALLARD_795_MCM', 'designation', 'physical', 'ENGINEERING_ASSUMPTION', 'PHASE3_FINAL_REPORT.md:49,53; ashuganj_lines.m:76-77', 'Ghorasal-Mallard family ref only, NOT measured South link', 'base');
R.frozen.bus_from        = e('B230_1', 'name', '-', 'SOURCE/PRIMARY', 'ashuganj_lines.m:65-66', 'frozen topology wiring', 'base');
R.frozen.bus_to          = e('B230_REMOTE', 'name', '-', 'SOURCE/PRIMARY', 'ashuganj_lines.m:65-66', 'REMOTE_GRID_BUS_ASSUMED, actual substation unknown', 'base');

% ---- machine reactances (458 MVA / 22 kV QUALIFIED interpretation) -------
mb = '458MVA-22kV-QUALIFIED';
R.machine.Snom_MVA = e(458, 'MVA', 'machine', 'SOURCE/PRIMARY', 'workbook C3 + Siemens 2.1 + nameplate', 'multi-source corroborated', 'base');
R.machine.Vnom_kV  = e(22, 'kV', 'machine', 'SOURCE/PRIMARY', 'workbook D3 + Siemens 2.1 + nameplate', 'multi-source corroborated', 'base');
R.machine.Xd       = e(1.7830, 'pu', mb, 'SOURCE/PRIMARY', 'workbook H3', 'WORKBOOK-DERIVED+QUALIFIED, no Siemens corroboration', 'base');
R.machine.Xdp      = e(0.3256, 'pu', mb, 'SOURCE/PRIMARY', 'workbook I3', 'WORKBOOK-DERIVED+QUALIFIED, no Siemens corroboration', 'base');
R.machine.Xdpp     = e(0.2608, 'pu', mb, 'SOURCE/PRIMARY', 'workbook J3', 'unsaturated sensitivity role, no Siemens corroboration', 'sensitivity');
R.machine.Xdpp_sat = e(0.2248, 'pu', mb, 'SOURCE/PRIMARY', 'workbook K3 + Siemens 2.1.1 22.48%', 'DIRECTLY-SOURCE-BACKED saturated, primary fault-study case', 'primary');
R.machine.Xq       = e(1.7510, 'pu', mb, 'SOURCE/PRIMARY', 'workbook L3', 'WORKBOOK-DERIVED+QUALIFIED, no q-axis Siemens data', 'base');
R.machine.Xqp      = e(0.5087, 'pu', mb, 'SOURCE/PRIMARY', 'workbook M3', 'WORKBOOK-DERIVED+QUALIFIED', 'base');
R.machine.Xqpp     = e(0.2593, 'pu', mb, 'SOURCE/PRIMARY', 'workbook N3', 'WORKBOOK-DERIVED+QUALIFIED; saliency sensitivity vs 0.2248', 'base');
R.machine.Xl       = e(0.2027, 'pu', mb, 'SOURCE/PRIMARY', 'workbook O3', 'WORKBOOK-DERIVED+QUALIFIED', 'base');
R.machine.X2       = e(0.2242, 'pu', mb, 'SOURCE/PRIMARY', 'workbook P3 X2(sat)', 'WORKBOOK-DERIVED+QUALIFIED project data, NOT Siemens-OEM-verified; DISTINCT cell from K3, never merged', 'primary');
R.machine.X0       = e(0.128, 'pu', mb, 'SOURCE/PRIMARY', 'workbook Q3 X0(sat)', 'WORKBOOK-DERIVED+QUALIFIED project data, NOT Siemens-OEM-verified', 'primary');
R.machine.Ra_ohm   = e(0.00089, 'ohm', 'stator', 'SOURCE/PRIMARY', 'workbook U3 (ohm explicit)', 'WORKBOOK-DERIVED+QUALIFIED, temp/test conditions not supplied', 'base');

% ---- grid datasets (never merged) -----------------------------------------
R.grid.P.Ik_kA = e(50, 'kA', '230kV', 'SOURCE/PRIMARY', 'Generator Data_South.pdf p.2/report p.7 s2.4', 'Level-1 Siemens direct source quantity; Siemens own word ESTIMATED, confidence inherited as estimate, never firm', 'primary');
R.grid.P.Zmag_ohm = e(2.65581124, 'ohm', '230kV', 'DERIVED', 'V^2/Ssc arithmetic, inherits ESTIMATED confidence', 'magnitude, NEVER called X', 'primary');
R.grid.P.XoR_band = e([10, 20], 'dimensionless', '230kV', 'ENGINEERING_ASSUMPTION', 'spec Sec 15 reference band, no source pair', 'base representative 15 via variant field', 'primary');
R.grid.P.XoR_base = e(15, 'dimensionless', '230kV', 'ENGINEERING_ASSUMPTION', 'arithmetic band centre, not measurement', 'split-only sensitivity, |Z| fixed', 'primary');
R.grid.P.XN_reported = e(2.66, 'ohm', '230kV', 'ENGINEERING_ASSUMPTION', 'Siemens s2.4 rounded', 'separately reported; NEVER paired with |Z| as exact R/X', 'primary');
R.grid.S.Ik_kA = e(45.01, 'kA', '230kV', 'LEGACY', 'Master-Data md:524-543; REV3_1_DATA_RECONCILIATION.md:177-192', 'QUALIFIED/SECONDARY sensitivity only', 'sensitivity');
R.grid.S.XoR    = e(10.99, 'dimensionless', '230kV', 'LEGACY', 'Master-Data md:530', 'lives INSIDE secondary profile only', 'sensitivity');
R.grid.k0g_band = e([1.0, 1.5, 2.0], 'dimensionless', '230kV', 'ENGINEERING_ASSUMPTION', 'spec Sec 8/15 per dataset', 'base 1.5; same-angle scaling is simplification', 'primary');

% ---- transformers (% on own ratings) ---------------------------------------
R.gsut.Z_pct  = e(16.0, '%', '515MVA-230/22kV-tap9', 'SOURCE/PRIMARY', 'GSUT sheet + nameplate', 'YNd1 principal tap 9', 'base');
R.gsut.R_pct  = e(0.21, '%', '515MVA-230/22kV-tap9', 'SOURCE/PRIMARY', 'GSUT sheet + nameplate', 'nameplate R used', 'base');
R.gsut.Z0_pct = e(15.8, '%', '515MVA-230/22kV-tap9', 'SOURCE/PRIMARY', 'GSUT sheet', 'QUALIFIED test-connection reading', 'base');
R.uat.Z_pct   = e(10.5, '%', '25MVA-22/6.9kV-tap3', 'SOURCE/PRIMARY', 'UAT sheet + nameplate', 'Dyn11 principal tap 3', 'base');
R.uat.R_pct   = e(0.4, '%', '25MVA-22/6.9kV-tap3', 'SOURCE/PRIMARY', 'UAT sheet + nameplate', 'approximate marker preserved', 'base');
R.uat.Z0_pct  = e(9.3, '%', '25MVA-22/6.9kV-tap3', 'SOURCE/PRIMARY', 'UAT sheet + nameplate', 'QUALIFIED test-connection reading', 'base');
R.uat.ground_limit_A = e(5, 'A', '6.9kV-LV', 'SOURCE/PRIMARY', 'UAT sheet LV-neutral clause', 'CURRENT LIMIT only, not impedance', 'base');
R.uat.ZN_LV_device = e(NaN, 'ohm', '6.9kV-LV', 'MISSING', 'UAT sheet LV-neutral clause (5-A limit only, 10BBW10 unresolved)', 'LV neutral device R/X MISSING; bounded equivalent in spec Sec 12', 'base');
R.gat.Z_PS_pct  = e(12.0, '%', '25MVA-230/6.9kV-tap13', 'SOURCE/PRIMARY', 'GAT-in-UAT-docs S/N 100580', 'pairwise HV-LV ONLY, INCOMPLETE', 'base');
R.gat.R_PS_pct  = e(0.5, '%', '25MVA-230/6.9kV-tap13', 'SOURCE/PRIMARY', 'GAT-in-UAT-docs', 'approximate pairwise figure', 'base');
R.gat.Z0_PS_pct = e(10.8, '%', '25MVA-230/6.9kV-tap13', 'SOURCE/PRIMARY', 'GAT-in-UAT-docs', 'pairwise; QUALIFIED test reading; +/-7.5% tolerance leg separate', 'base');
R.gat.Z_PT = e(NaN, '%', '25MVA', 'MISSING', 'ashuganj_transformers.m:301-302', 'HV-tertiary MISSING; never fabricated', 'base');
R.gat.Z_ST = e(NaN, '%', '25MVA', 'MISSING', 'ashuganj_transformers.m:303-304', 'LV-tertiary MISSING; never fabricated', 'base');
R.gat.ZN_LV_device = e(NaN, 'ohm', '6.9kV-LV', 'MISSING', 'GAT-in-UAT-docs LV-neutral clause (5-A limit)', 'LV neutral device MISSING; NOT solid; bounded equivalent in spec Sec 13', 'base');
R.gat.ZN_HV_device = e(NaN, 'ohm', '230kV-HV', 'MISSING', 'no GAT neutral device in source set', 'solid ASSUMPTION position, no measured record', 'base');

% ---- NGT series impedance: MISSING at source level --------------------------
R.ngt.Z_series_HV = e(NaN, 'ohm', 'HV side', 'MISSING', 'Generator Data_South.pdf s2.3 NER clause (no series-Z data)', 'NER transformer series impedance MISSING; neglected-vs-bounded rule in spec Sec 10', 'base');

% ---- South-line zero point values: MISSING at source level -----------------
R.line.R0_ohm = e(NaN, 'ohm', '100MVA-230kV', 'MISSING', 'ashuganj_lines.m:84', 'never 3xX1/R1 as fact; band in Sec 14', 'base');
R.line.X0_ohm = e(NaN, 'ohm', '100MVA-230kV', 'MISSING', 'ashuganj_lines.m:85', 'band in Sec 14', 'base');
R.line.B0_uS  = e(NaN, 'microS', '100MVA-230kV', 'MISSING', 'ashuganj_lines.m:86', 'band in Sec 14', 'base');
R.line.kR_band = e([2.0, 5.0], 'dimensionless', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'spec Sec 14 reference band', 'base representative 3.5', 'primary');
R.line.kX_band = e([2.0, 3.5], 'dimensionless', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'spec Sec 14 reference band', 'base representative 2.75', 'primary');
R.line.kB_band = e([0.60, 0.85], 'dimensionless', '100MVA-230kV', 'ENGINEERING_ASSUMPTION', 'spec Sec 14 reference band', 'base representative 0.725', 'primary');

% ---- runtime freeze cross-check (assert, never redefine) --------------------
L = ashuganj_lines();
kL = find(strcmp({L.Name}, 'L_LINE'), 1);
assert(~isempty(kL), 'phase4_registry:freeze', 'L_LINE missing from frozen register');
assert(abs(L(kL).R_ohm - 0.0277725) < 1e-12, 'phase4_registry:freeze', 'R_eq freeze violated');
assert(abs(L(kL).X_ohm - 0.1425655) < 1e-12, 'phase4_registry:freeze', 'X_eq freeze violated');
assert(abs(L(kL).Length_km - 0.7) < 1e-12, 'phase4_registry:freeze', 'length freeze violated');
assert(L(kL).Physical_circuit_count == 2, 'phase4_registry:freeze', 'circuit-count freeze violated');
B_from_C_uS = 2*pi*50*L(kL).C_F*1e6;
assert(abs(B_from_C_uS - 3.937996) < 1e-9, 'phase4_registry:freeze', 'B_eq freeze violated');
end

% =====================================================================
function s = e(value, unit, base, status, source, rationale, variant)
s = struct('value', value, 'unit', unit, 'base', base, 'status', status, ...
    'source', source, 'locator', source, 'rationale', rationale, 'variant', variant);
end
