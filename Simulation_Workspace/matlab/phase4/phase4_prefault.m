function F = phase4_prefault(caseID, varargin)
%PHASE4_PREFAULT  Frozen prefault operating point for the Phase-4 fault study.
%
%   F = PHASE4_PREFAULT(caseID) returns the solved prefault state for the
%   primary LF360 pair only: 'LF360_GAT_OUT' or 'LF360_GAT_IN'.
%
%   F = PHASE4_PREFAULT(caseID, 'allowNonPrimary', true) additionally permits
%   the LF342 / LF389P30 solved states with their labels preserved. They are
%   never relabelled as primary: the opt-in only widens the gate, it never
%   renames the case.
%
%   Every electrical quantity comes from the frozen Phase-3 result files via
%   the named magnitude columns only:
%     results/phase3_loadflow/phase3_bus_results.csv
%       (Case_ID, Bus_Name, V_kV, Angle_deg, P_inj_MW, Q_inj_MVAr)
%     results/phase3_loadflow/phase3_system_summary.csv
%       (Case_ID, Gen_P_MW, Gen_Q_MVAr, GAT_in, Paux_MW, Qaux_MVAr)
%   Bus rows: B22 carries Vt/angle; B230_1 and B230_REMOTE carry the plant
%   and remote voltages plus angles. The one summary row per Case_ID carries
%   Gen P/Q, the GAT position flag, and the auxiliary load.
%
%   Output struct fields (exact names): Vt_B22_kV, Ang_B22_deg, Pgen_MW,
%   Qgen_MVAr, V230_1_kV, Ang230_1_deg, Vremote_kV, AngRemote_deg, GAT_in
%   (logical), auxP_MW, auxQ_MVAr, couplerClosed (always true).
%
%   Spec: Secs 9/16. LF360 pair is PRIMARY; LF342/LF389P30 are rejected as
%   primary unless the caller passes the explicit opt-in.

if nargin < 1 || ~(ischar(caseID) || isstring(caseID))
    error('phase4_prefault:badCase', 'caseID must be a character vector or string scalar.');
end
cid = char(string(caseID));
if ~isrow(cid)
    error('phase4_prefault:badCase', 'caseID must be a scalar case label.');
end

allowNonPrimary = false;
k = 1;
while k <= numel(varargin)
    nm = varargin{k};
    if ~(ischar(nm) || isstring(nm)) || k + 1 > numel(varargin)
        error('phase4_prefault:badOption', 'Options must be name/value pairs.');
    end
    if strcmpi(char(nm), 'allowNonPrimary')
        allowNonPrimary = logical(varargin{k + 1});
    else
        error('phase4_prefault:badOption', 'Unknown option ''%s''.', char(nm));
    end
    k = k + 2;
end

primary = {'LF360_GAT_OUT', 'LF360_GAT_IN'};
isPrimary = any(strcmp(cid, primary));
isLabelled = strncmp(cid, 'LF342', 5) || strncmp(cid, 'LF389P30', 8);
if ~(isPrimary || (allowNonPrimary && isLabelled))
    error('phase4_prefault:nonPrimary', ['Case ''%s'' is not a primary ' ...
        'Phase-4 prefault state. The LF360 pair is PRIMARY; pass ' ...
        '''allowNonPrimary'', true for LF342/LF389P30 labels.'], cid);
end

root = ashuganj_root();
busCsv = fullfile(root, 'results', 'phase3_loadflow', 'phase3_bus_results.csv');
sysCsv = fullfile(root, 'results', 'phase3_loadflow', 'phase3_system_summary.csv');
Tb = readtable(busCsv);
Ts = readtable(sysCsv);

busCase = string(Tb.Case_ID);
busName = string(Tb.Bus_Name);
sysCase = string(Ts.Case_ID);
want = string(cid);

i22 = find(busCase == want & busName == "B22", 1);
iP  = find(busCase == want & busName == "B230_1", 1);
iR  = find(busCase == want & busName == "B230_REMOTE", 1);
js  = find(sysCase == want, 1);
if isempty(i22) || isempty(iP) || isempty(iR) || isempty(js)
    error('phase4_prefault:missingRow', 'Frozen solved state missing for case ''%s''.', cid);
end

Vt_B22     = Tb.V_kV(i22);
Ang_B22    = Tb.Angle_deg(i22);
Pbus22     = Tb.P_inj_MW(i22);
Qbus22     = Tb.Q_inj_MVAr(i22);
V230_1     = Tb.V_kV(iP);
Ang230_1   = Tb.Angle_deg(iP);
Vremote    = Tb.V_kV(iR);
AngRemote  = Tb.Angle_deg(iR);

Pgen = Ts.Gen_P_MW(js);
Qgen = Ts.Gen_Q_MVAr(js);
gat  = logical(Ts.GAT_in(js));
auxP = Ts.Paux_MW(js);
auxQ = Ts.Qaux_MVAr(js);

% Consistency: summary Gen P/Q must agree with the B22 injection row.
mustNear(Pgen, Pbus22, 1e-6, 'Gen_P_MW vs B22 P_inj_MW');
mustNear(Qgen, Qbus22, 1e-6, 'Gen_Q_MVAr vs B22 Q_inj_MVAr');

% Frozen cross-checks (fail loud on any drift of the locked numbers).
mustNear(auxP, 14.0, 1e-9, 'auxP_MW');
mustNear(auxQ, 8.676421, 1e-6, 'auxQ_MVAr');
if strcmp(cid, 'LF360_GAT_OUT')
    mustNear(Vt_B22, 22.0, 1e-9, 'Vt_B22_kV OUT');
    mustNear(Ang_B22, -22.7815, 1e-6, 'Ang_B22_deg OUT');
    mustNear(Pgen, 360.0, 1e-9, 'Pgen_MW OUT');
    mustNear(Qgen, 27.832638, 1e-6, 'Qgen_MVAr OUT');
    mustNear(Vremote, 229.731274, 1e-6, 'Vremote_kV OUT');
    mustChk(~gat, 'GAT_in false OUT');
elseif strcmp(cid, 'LF360_GAT_IN')
    mustNear(Vt_B22, 22.0, 1e-9, 'Vt_B22_kV IN');
    mustNear(Pgen, 360.0, 1e-9, 'Pgen_MW IN');
    mustNear(Qgen, 23.668784, 1e-6, 'Qgen_MVAr IN');
    mustChk(gat, 'GAT_in true IN');
end

F = struct('Vt_B22_kV', Vt_B22, 'Ang_B22_deg', Ang_B22, ...
    'Pgen_MW', Pgen, 'Qgen_MVAr', Qgen, ...
    'V230_1_kV', V230_1, 'Ang230_1_deg', Ang230_1, ...
    'Vremote_kV', Vremote, 'AngRemote_deg', AngRemote, ...
    'GAT_in', gat, 'auxP_MW', auxP, 'auxQ_MVAr', auxQ, ...
    'couplerClosed', true);
end

function mustNear(a, b, tol, what)
if ~(isscalar(a) && isscalar(b) && abs(a - b) <= tol)
    error('phase4_prefault:freeze', 'Frozen value drift: %s got %g expected %g.', what, a, b);
end
end

function mustChk(ok, what)
if ~isequal(ok, true)
    error('phase4_prefault:freeze', 'Frozen value drift: %s.', what);
end
end
