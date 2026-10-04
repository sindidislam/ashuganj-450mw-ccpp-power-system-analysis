function Y = phase4_topology(m, view, coupler)
%PHASE4_TOPOLOGY  Topology node map + m-division fractions + two-circuit B-view.
%
%   Y = PHASE4_TOPOLOGY(m, view, coupler) returns the Phase-4 network
%   topology on the unit-total convention: series/shunt quantities here are
%   FRACTIONS of the frozen/assumed totals, so fractions multiply M2 totals
%   downstream to obtain ohms/pu.
%
%   m in [0,1] is the fractional distance from the GIS end to the fault
%   point F4 along the 230 kV link (0 = GIS end, 1 = remote end).
%   view is 'lumped' or 'B' (two-circuit distributed view).
%   coupler is 'closed' or 'open' (bus-coupler state at the GIS 230 kV bus).
%
%   Node indices are stable across views; F4 exists as its own node only in
%   B-view. F1/F2 share one node index with distinct labels kept separate.
%
%   Q0 is a breaker connection; Q1 is a bus-disconnector connection; Q2 is
%   a bus-disconnector connection; Q9 is a line-disconnector connection.
%   Q51/Q52/Q8 are earth-switch states (OPEN). No switching model here.

% ---- input validation --------------------------------------------------
if ~(isnumeric(m) && isscalar(m) && isfinite(m) && m >= 0 && m <= 1)
    error('phase4_topology:badM', 'm must be a scalar in [0,1]');
end
if ~(ischar(view) || isstring(view))
    error('phase4_topology:badView', 'view must be ''lumped'' or ''B''');
end
view = char(view);
if ~(strcmp(view, 'lumped') || strcmp(view, 'B'))
    error('phase4_topology:badView', 'view must be ''lumped'' or ''B''');
end
if ~(ischar(coupler) || isstring(coupler))
    error('phase4_topology:badCoupler', 'coupler must be ''closed'' or ''open''');
end
coupler = char(coupler);
if ~(strcmp(coupler, 'closed') || strcmp(coupler, 'open'))
    error('phase4_topology:badCoupler', 'coupler must be ''closed'' or ''open''');
end

Y = struct();
Y.m = m;
Y.view = view;
Y.coupler = coupler;

% ---- node index map (exact field names) --------------------------------
Y.nodeB22 = 1;
Y.nodeB230_1 = 2;
if strcmp(coupler, 'closed')
    Y.nodeB230_2 = 2;
else
    Y.nodeB230_2 = 3;
end
Y.nodeB230_REMOTE = 4;
Y.nodeGRID = 5;
Y.nodeB66 = 6;
Y.nodeF1 = Y.nodeB22;
Y.nodeF2 = Y.nodeB22;
Y.labelF1 = 'F1_B22';
Y.labelF2 = 'F2_GSUT_LV';
Y.labelF3 = 'F3_GIS';
Y.labelF5 = 'F5_REMOTE';
if strcmp(view, 'B')
    Y.nodeF4 = 7;
else
    if m == 0
        Y.nodeF4 = Y.nodeB230_1;
    else
        error('phase4_topology:noF4lumped', 'F4 node exists only in B-view');
    end
end

% ---- per-unit m-division on the unit-total convention -------------------
%   Unit total: fractions multiply M2 totals downstream.
Y.Zs_eq_pu = 1;
Y.Zs_branch_pu = 2;
Y.Zs_S = m * Y.Zs_eq_pu;
Y.Zs_R = (1 - m) * Y.Zs_eq_pu;
Y.Bs_eq_pu = 1;
Y.Bs_branch_pu = 0.5;
Y.Bs_S = m;
Y.Bs_R = (1 - m);

% ---- in-function restoration asserts (tol 1e-12) ------------------------
if abs(Y.Zs_branch_pu / 2 - Y.Zs_eq_pu) > 1e-12
    error('phase4_topology:restoreBranch', 'branch/2 must restore series total');
end
if abs((Y.Zs_S + Y.Zs_R) - Y.Zs_eq_pu) > 1e-12
    error('phase4_topology:restoreSections', 'S+R must restore series total');
end
if abs(Y.Bs_branch_pu * 2 - Y.Bs_eq_pu) > 1e-12
    error('phase4_topology:restoreShuntBranch', 'shunt branch pair must restore shunt total');
end
if abs((Y.Bs_S + Y.Bs_R) - Y.Bs_eq_pu) > 1e-12
    error('phase4_topology:restoreShuntSections', 'shunt S+R must restore shunt total');
end

% ---- GIS tags (no switching model) --------------------------------------
Y.Q0 = 'breaker';
Y.Q1 = 'bus-disconnector';
Y.Q2 = 'bus-disconnector';
Y.Q9 = 'line-disconnector';
Y.Q51 = 'maintenance-earth-OPEN';
Y.Q52 = 'maintenance-earth-OPEN';
Y.Q8 = 'high-speed-earth-OPEN';

% ---- GAT HV tee flag ----------------------------------------------------
Y.gatTeeAtB230_2 = true;
end
