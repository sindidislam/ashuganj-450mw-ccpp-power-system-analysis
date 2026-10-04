function [np, nf] = test_phase5c_differential()
%TEST_PHASE5C_DIFFERENTIAL  87G + 87T slope, stability, harmonic block.
T = t_case('test_phase5c_differential');
out = fullfile(tempdir, ['ph5c_diff_' char(java.util.UUID.randomUUID())]);
mkdir(out); cleanup = onCleanup(@()rmdir(out, 's')); %#ok<NASGU>
root = ashuganj_root();

% --- 87G ---
G = phase5c_diff_87g(out, root);
T = T.chk(abs(G.In_A - 12019.2) < 0.5, '87G In = 12019.2 A (458MVA/22kV)');
T = T.chk(abs(G.Isec_n_A - 12019.2/15000) < 1e-3, '87G secondary 0.8013 A');
T = T.chk(abs(G.pickup_A - 2403.8) < 0.5 && abs(G.pickup_sec_A - 0.1603) < 1e-3, '87G pickup 2403.8 A / 0.1603 A sec');
T = T.chk(G.k1 == 0.20 && G.k2 == 0.50 && G.Irest1_pu == 1.0, '87G slopes 20/50%, breakpoint 1.0pu');
T = T.chk(abs(G.highset_A - 60096) < 2, '87G high-set 5pu = 60096 A');
T = T.chk(~G.A.trip, '87G-A normal load NO TRIP');
T = T.chk(~G.B.trip, '87G-B external 126kA STABLE');
T = T.chk(G.C.trip, '87G-C internal 5kA TRIP');
T = T.chk(isfile(G.png), '87G plot written');
a = imfinfo(G.png); T = T.chk(a.Width > 800 && a.Height > 400, '87G plot usable size');

% --- 87T ---
H = phase5c_diff_87t(out, root);
T = T.chk(abs(H.In_LV_450_A - 11809.1) < 0.5, '87T LV 11809.1 A (450MVA/22kV)');
T = T.chk(abs(H.In_HV_400_A - 649.5) < 0.5, '87T HV 649.5 A (450MVA/400kV)');
T = T.chk(abs(H.Isec_LV_450_A - 0.7873) < 1e-3, '87T LV sec 0.7873 A');
T = T.chk(abs(H.Isec_HV_400_A - 0.4060) < 1e-3, '87T HV sec 0.4060 A');
T = T.chk(abs(H.M_LV - 1.2702) < 1e-3 && abs(H.M_HV - 2.4633) < 1e-3, '87T matching 1.2702 / 2.4633');
T = T.chk(abs(H.pickup_A_LV450 - 3542.7) < 0.5, '87T pickup 3542.7 A LV450');
T = T.chk(H.k1 == 0.25 && H.k2 == 0.50 && H.Irest1_pu == 1.50, '87T slopes 25/50%, breakpoint 1.5pu');
T = T.chk(~H.A.trip, '87T-A normal NO TRIP');
T = T.chk(~H.B.trip, '87T-B external through STABLE');
T = T.chk(H.C.trip, '87T-C internal TRIP');
T = T.chk(~H.D.trip, '87T-D inrush 2nd-harm BLOCKED');
T = T.chk(~H.E.trip, '87T-E overexcitation 5th-harm BLOCKED');
T = T.chk(isfile(H.png), '87T plot written');
% fault linkage: every threshold below its minimum protected fault
FT = readtable(fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_fault_currents.csv'), 'VariableNamingRule', 'preserve');
FI = FT(strcmp(string(FT.stage), 'Ikpp'), :);
f1lll = FI(strcmp(string(FI.location), 'F1') & strcmp(string(FI.fault_type), 'LLL') & strcmp(string(FI.caseID), 'LF360_GAT_OUT'), :).Irms_kA(1) * 1000;
f3lll = FI(strcmp(string(FI.location), 'F3') & strcmp(string(FI.fault_type), 'LLL') & strcmp(string(FI.caseID), 'LF360_GAT_OUT'), :).Irms_kA(1) * 1000;
T = T.chk(G.pickup_A < 5000 && 5000 < f1lll, '87G pickup < internal fault < through fault');
T = T.chk(H.pickup_A_LV450 < f1lll && 17170.8 < f3lll, '87T pickup and GEN-51 pickup below min phase fault');

try, phase5c_diff_87g(42); T = T.chk(false, '87G invalid path rejected'); catch ME, T = T.chk(startsWith(ME.identifier, 'phase5c_diff_87g'), '87G invalid path rejected'); end
try, phase5c_diff_87t(42); T = T.chk(false, '87T invalid path rejected'); catch ME, T = T.chk(startsWith(ME.identifier, 'phase5c_diff_87t'), '87T invalid path rejected'); end
[np, nf] = T.done();
end
