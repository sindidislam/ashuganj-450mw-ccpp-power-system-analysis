function [np, nf] = test_phase4_prefault()
%TEST_PHASE4_PREFAULT  M1 prefault provider reads the frozen solved states
%   through the kV columns only. Solver-base *_pu columns must never leak in.
%
%   Spec: Secs 9/16. LF360 pair is PRIMARY; LF342/LF389P30 are rejected as
%   primary (available only with explicit opt-in, never relabelled).

T = t_case('test_phase4_prefault');

F = phase4_prefault('LF360_GAT_OUT');
T = T.eq(F.Vt_B22_kV, 22.0, 'B22 22 kV OUT');
T = T.near(F.Ang_B22_deg, -22.7815, 1e-3, 'B22 angle OUT -22.7815 deg');
T = T.eq(F.Pgen_MW, 360.0, 'P frozen 360 MW');
T = T.near(F.Qgen_MVAr, 27.832638, 1e-4, 'Q OUT 27.83 MVAr');

G = phase4_prefault('LF360_GAT_IN');
T = T.near(G.Qgen_MVAr, 23.668784, 1e-4, 'Q IN 23.67 MVAr');
T = T.chk(abs(G.Qgen_MVAr - F.Qgen_MVAr) > 1, 'OUT/IN Q differ: no shared EMF');
T = T.near(F.Vremote_kV, 229.731274, 1e-3, 'V_REMOTE_kV OUT via kV column');
T = T.eq(F.GAT_in, false, 'OUT case GAT open');
T = T.eq(G.GAT_in, true, 'IN case GAT closed');
T = T.eq(F.couplerClosed, true, 'coupler CLOSED base');

try
    phase4_prefault('LF389P30_GAT_OUT');
    T = T.chk(false, 'historical rejected as primary');
catch ME
    T = T.chk(startsWith(ME.identifier, 'phase4'), 'historical rejected as primary');
end

[np, nf] = T.done();
end
