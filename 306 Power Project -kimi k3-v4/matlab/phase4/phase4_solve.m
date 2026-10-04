function F = phase4_solve(caseID, ds, XoR_P, loc, type, stage, Zf_ohm, varargin)
%PHASE4_SOLVE  Full-nodal M4 fault solver with Thevenin audit and ip.
%
%   F = PHASE4_SOLVE(caseID, ds, XoR_P, loc, type, stage, Zf_ohm) solves the
%   subtransient (Ikpp) short circuit on the full coupled sequence-nodal
%   base. Optional 8th arg opts struct overrides base-run defaults.
%
%   Positional inputs:
%     caseID : 'LF360_GAT_OUT' / 'LF360_GAT_IN' (via phase4_prefault)
%     ds     : 'P' / 'S' grid dataset (via phase4_seqPN)
%     XoR_P  : grid X/R for dataset P in [10,20]
%     loc    : 'F1'/'F2' (B22) / 'F3' (GIS 230 kV) / 'F5' (remote) / 'F4' (line, B-view)
%     type   : 'LLL' / 'LG' / 'LL' / 'LLG'
%     stage  : 'Ikpp'/'Ib'/'Isteady' (T9 additive: Ib/Isteady beside Ikpp)
%     Zf_ohm : fault resistance >= 0, real (negative or complex errors)
%   opts fields (all optional): m (F4 fractional distance, default 0.5),
%     gatLeg (default 'H1'), coupler ('closed'/'open', default 'closed'),
%     kR/kX/kB (default 3.5/2.75/0.725), k0g (default 1.5), ner (default
%     'primary'), XdRole ('sat'/'unsat', default 'sat'), lambda_T (default 1.0).
%   Additive Task-12 support (base-identical by default, no other solve
%   math touched): lineScale (default 1.0; multiplies line series+shunt
%     totals in ALL sequences including zero-band totals; B-view and
%     m-division fractions unchanged), gatZ0sel ('nominal'/'low'/'high',
%     default 'nominal'; forwarded to phase4_seqZ as the applied GAT Z0),
%     ovr (optional struct forwarded additive-only through seqZ to
%     grounding: Rloading_tolfrac/ZN_UAT_scale/ZN_GATLV_scale/ZN_GATHV_ohm;
%     strict 'phase4'-prefixed validation, base defaults reproduce exactly).
%
%   Architecture (binding): full-nodal base, Thevenin scalars audit only.
%   Node map (global indices): 1=B22, 2=B230_1 (coupler-closed: also
%   B230_2), 3=B230_2 (coupler-open only), 4=B230_REMOTE, 5=GRID internal,
%   6=B6_6, 7=F4node (B-view only), 8=gen neutral N (zero only), 9=UAT
%   neutral N_UAT (zero only). F1/F2 share node 1 with labels kept separate
%   (see phase4_topology).
%
%   Per-sequence Ybus on 100 MVA / 230 kV (complex pu):
%     POSITIVE: gen Norton at B22 (Epp from phase4_sources behind Zpp from
%       phase4_seqPN per XdRole); GSUT Z1 branch 1->2 with +30 deg complex
%       tap (YNd1 HV leads LV; sign verified by the prefault gate: gate
%       31% without it, <5% with it; negative sequence uses the conjugate);
%       UAT Z1 branch 1->6 with documented nominal LV tap aU = V_HV/V_LV
%       = 1/(6.9/6.6) (magnitude only; no vector-group shift modeled --
%       pre-existing angle choice, limitation noted); aux
%       constant-Z shunt at 6 fitted at the prefault point
%       (ENGINEERING_ASSUMPTION shunt: Zaux_ohm =
%       (V66_kV*1000)^2/conj(Saux_MVA*1e6), pu on the 6.6-kV LV-zone base
%       0.4356 ohm (correction record C1/C2; never 529); GAT Z1_PS branch (HV tee node 2, or
%       3 when open) iff the prefault case is GAT_in, same nominal LV tap; line Z1 lumped 2->4
%       (series only; PI shunt omitted, ~1e-5 effect); grid Z1 branch 4->5
%       with internal Eg fixed (Thevenin branch, explicit internal node).
%       Grid source (literal): Eg = Vremote_pu + Z1grid_pu*Igrid_pu,
%       Igrid_pu = conj((Export_P+j*Export_Q)/100/Vremote_pu), Export from
%       the frozen system-summary row (flow remote->grid).
%     NEGATIVE: same topology with Z2 values, all Norton injections zeroed
%       (machine Z2 shunt to ground stays), grid internal grounded.
%     ZERO: gen chain 1->8 (Z0gen) ->ground (3ZN); GSUT HV leg 2->ground
%       (Z0gsut; solid-neutral position per phase4_seqZ); UAT 6->9 (Z0uat)
%       ->ground (Z3N_UAT_equiv_pu: single x3 upstream, never here --
%       correction record C7); GAT HV-LV zero
%       branch iff GAT_in with H-leg treatment (H0: no loop shunt,
%       tertiary open; H1: 100-MVA loop shunt at LV; H2: explicit 1e-6
%       short-limit shunt);
%       line zero 2->4; grid zero 4->5 with Z0 = k0g*Z1 same-angle
%       (simplification). Grid zero far end is GROUNDED (Thevenin source
%       zeroed; series-Z-to-grounded-node is electrically identical to a
%       shunt-to-ground branch; an open end would wrongly disconnect grid
%       zero contribution). Aux shunt OPEN; earthing switches absent.
%   B-view (F4): two circuits; healthy circuit 2->4 direct with
%     Z_branch = 2*Z_eq totals; faulted circuit 2->7->4 split m/(1-m) on
%     Z_branch (B_branch = B_eq/2 unused: no shunts modelled); T7 fractions
%     times M2 totals; zero layer split the same way. m=0/1 degenerates to
%     the GIS/remote node (no zero-length section stamped).
%
%   PREFAULT-REPRODUCTION GATE: no-fault positive solve; solved V at nodes
%   1/2/4 vs CSV prefault complex voltages; pre_res = max relative
%   deviation, always printed, error('phase4_solve:prefault') above 0.10.
%
%   FAULT COUPLING: one coupled KCL system over [V1,V2,V0] plus fault
%   unknowns (modified-nodal constraint rows = the explicit inter-layer
%   coupling; genuinely nodal, no Thevenin reduction). Series-loop
%   equivalent: LG constrains V1f+V2f+V0f = 3*Zf*If with a single shared
%   If (Zf = 0 handled exactly; a literal 3-segment chain would
%   over-constrain the bolted case and break Ia = 3*I0, so the loop is
%   stamped as constraints); LL constrains V1f-V2f = Zf*If with I2 = -I1
%   (I0 = 0 by construction, asserted < 1e-9); LLG uses an explicit common
%   node c (V1f = Vc, V2f = Vc, V0f-Vc = 3*Zf*If0, If1+If2+If0 = 0); LLL is
%   a Zf shunt on layer 1 (bolted: V1f fixed 0, KCL residual current).
%   Currents are INTO the fault; phases via Fortescue.
%
%   THEVENIN AUDIT (independent path, scalars only): sources zeroed, 1 pu
%   injected per sequence at the fault node -> Zth1/2/0; closed-form
%   scalars evaluated with Vf = retained nodal open-circuit voltage at the
%   fault node (equals the CSV prefault value to within pre_res; driving
%   the scalars with the CSV phasor directly would inject pre_res into the
%   audit and make the mandated 1e-6 closure unsatisfiable, so the audit
%   verifies coupling/Zth algebra to solver precision while the gate
%   independently ties Vf to CSV within 10%). audit_res = worst relative
%   |I_nodal - I_scalar| over I1/I2/I0 (jointly-zero terms score 0).
%   Thevenin-only solving as base is FORBIDDEN; scalars audit only.
%   F4 CSV Vf (traceability only): linear complex interpolation by m
%   between V230_1 and Vremote (audit-only approximation).
%
%   ip: r = real(Zth1)/imag(Zth1) (r <= 0 -> kappa = 1.02 resistive limit);
%   kappa = phase4_kappa(r); governing magnitude LG |Ia|, LL/LLG
%   max(|Ib|,|Ic|), LLL |I1|; ip = kappa*sqrt(2)*governing (pu magnitude).
%
%   Output fields (exact names): I1,I2,I0,Ia,Ib,Ic (complex, INTO fault),
%   V1F,V2F,V0F, audit_res, r, kappa, ip, Vf, Zth1, Zth2, Zth0, pre_res,
%   stage; plus Vf_csv (CSV prefault phasor at fault node) and Eg.
%
%   OUTPUT-ONLY additions (Task 10; solution math, gates, audit, and all
%   fields above stay behavior-identical): Vbus1/Vbus2 (solved sequence
%   voltages over pn, node 5 = Eg/0), Vbus0 (over zn, node 5 = 0; all-zero
%   where the zero network is DEAD: LLL and LL), pn/zn (active global-node
%   lists in vector order), branch (struct array name/from/to/I1/I2/I0:
%   per-branch sequence currents in from->to reference, same impedances as
%   the Ybus build above, never redefined; from = -1 is the machine
%   internal node, to = 0 is earth), GAT_in (case flag), faultNode
%   (global fault node), isF4, mF4 (faulted-line fraction).

if nargin < 7
    error('phase4_solve:args', 'Seven positional inputs required: caseID, ds, XoR_P, loc, type, stage, Zf_ohm.');
end
if isstring(caseID), caseID = char(caseID); end
if isstring(ds), ds = char(ds); end
if isstring(loc), loc = char(loc); end
if isstring(type), type = char(type); end
if isstring(stage), stage = char(stage); end

if ~any(strcmp(loc, {'F1','F2','F3','F4','F5'}))
    error('phase4_solve:badLoc', 'Unknown fault location ''%s'': use F1/F2/F3/F4/F5.', loc);
end
if ~any(strcmp(type, {'LLL','LG','LL','LLG'}))
    error('phase4_solve:badType', 'Unknown fault type ''%s'': use LLL/LG/LL/LLG.', type);
end
if ~(ischar(stage) && isrow(stage) && any(strcmp(stage, {'Ikpp','Ib','Isteady'})))
    error('phase4_solve:badStage', 'Unknown stage: use ''Ikpp''/''Ib''/''Isteady''.');
end
if ~(isnumeric(Zf_ohm) && isscalar(Zf_ohm) && isreal(Zf_ohm) && isfinite(Zf_ohm) && Zf_ohm >= 0)
    error('phase4_solve:badZf', 'Zf_ohm must be a real finite scalar >= 0 (resistive).');
end

o = struct('m', 0.5, 'gatLeg', 'H1', 'coupler', 'closed', ...
    'kR', 3.5, 'kX', 2.75, 'kB', 0.725, 'k0g', 1.5, ...
    'ner', 'primary', 'XdRole', 'sat', 'lambda_T', 1.0, ...
    'lineScale', 1.0, 'gatZ0sel', 'nominal');
o.ovr = struct('Rloading_tolfrac', 0, 'ZN_UAT_scale', 1, ...
    'ZN_GATLV_scale', 1, 'ZN_GATHV_ohm', 0);
if numel(varargin) >= 1
    if ~isstruct(varargin{1}) || ~isscalar(varargin{1})
        error('phase4_solve:badOpts', 'opts (8th arg) must be a scalar struct.');
    end
    fn = fieldnames(varargin{1});
    for i = 1:numel(fn)
        if strcmp(fn{i}, 'ovr') && isstruct(varargin{1}.ovr) && isscalar(varargin{1}.ovr) ...
                && isfield(o, 'ovr') && isstruct(o.ovr)
            % merge ovr subfields additively (partial ovr keeps base defaults)
            sfn = fieldnames(varargin{1}.ovr);
            for j = 1:numel(sfn)
                o.ovr.(sfn{j}) = varargin{1}.ovr.(sfn{j});
            end
        else
            o.(fn{i}) = varargin{1}.(fn{i});
        end
    end
end
if isstring(o.coupler), o.coupler = char(o.coupler); end
if isstring(o.gatLeg), o.gatLeg = char(o.gatLeg); end
if isstring(o.ner), o.ner = char(o.ner); end
if isstring(o.XdRole), o.XdRole = char(o.XdRole); end
if ~any(strcmp(o.XdRole, {'sat','unsat'}))
    error('phase4_solve:badXdRole', 'opts.XdRole must be ''sat'' or ''unsat''.');
end
if ~(isnumeric(o.m) && isscalar(o.m) && isfinite(o.m) && o.m >= 0 && o.m <= 1)
    error('phase4_solve:badM', 'opts.m must be a scalar in [0,1].');
end
if ~any(strcmp(o.coupler, {'closed','open'}))
    error('phase4_solve:badCoupler', 'opts.coupler must be ''closed'' or ''open''.');
end
% ---- Task-12 additive validation (strict, 'phase4'-prefixed) ----
if ~(isnumeric(o.lineScale) && isscalar(o.lineScale) && isfinite(o.lineScale) && o.lineScale > 0 && o.lineScale <= 10)
    error('phase4_solve:badLineScale', 'opts.lineScale must be a finite scalar in (0,10] (default 1.0).');
end
if isstring(o.gatZ0sel), o.gatZ0sel = char(o.gatZ0sel); end
if ~(ischar(o.gatZ0sel) && isrow(o.gatZ0sel) && any(strcmp(o.gatZ0sel, {'nominal','low','high'})))
    error('phase4_solve:badGatZ0sel', 'opts.gatZ0sel must be ''nominal''/''low''/''high'' (default ''nominal'').');
end
if ~isstruct(o.ovr) || ~isscalar(o.ovr)
    error('phase4_solve:badOvr', 'opts.ovr must be a scalar struct.');
end
% ovr range validation defers to phase4_grounding via seqZ, but unknown
% fields are rejected here as well for strictness (same allow-list).
ofn = fieldnames(o.ovr);
for i = 1:numel(ofn)
    if ~any(strcmp(ofn{i}, {'Rloading_tolfrac','ZN_UAT_scale','ZN_GATLV_scale','ZN_GATHV_ohm'}))
        error('phase4_solve:badOvr', 'Unknown opts.ovr field ''%s''.', ofn{i});
    end
end
if isfield(o.ovr, 'Rloading_tolfrac')
    v = o.ovr.Rloading_tolfrac;
    if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= -0.1 && v <= 0.1)
        error('phase4_solve:badOvr', 'opts.ovr.Rloading_tolfrac must be finite in [-0.1,0.1].');
    end
end
if isfield(o.ovr, 'ZN_UAT_scale')
    v = o.ovr.ZN_UAT_scale;
    if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0.2 && v <= 3.0)
        error('phase4_solve:badOvr', 'opts.ovr.ZN_UAT_scale must be finite in [0.2,3.0].');
    end
end
if isfield(o.ovr, 'ZN_GATLV_scale')
    v = o.ovr.ZN_GATLV_scale;
    if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0.2 && v <= 3.0)
        error('phase4_solve:badOvr', 'opts.ovr.ZN_GATLV_scale must be finite in [0.2,3.0].');
    end
end
if isfield(o.ovr, 'ZN_GATHV_ohm')
    v = o.ovr.ZN_GATHV_ohm;
    if ~(isnumeric(v) && isscalar(v) && isfinite(v) && v >= 0 && v <= 5)
        error('phase4_solve:badOvr', 'opts.ovr.ZN_GATHV_ohm must be finite in [0,5] ohm.');
    end
end

% ---- upstream modules (their 'phase4'-prefixed errors propagate) ----
PF = phase4_prefault(caseID);
N  = phase4_seqPN(ds, XoR_P);
Z  = phase4_seqZ(struct('kR', o.kR, 'kX', o.kX, 'kB', o.kB, 'k0g', o.k0g, ...
    'gatLeg', o.gatLeg, 'lambda_T', o.lambda_T, 'grid', ds, 'XoR_P', XoR_P, ...
    'ner', o.ner, 'gatZ0sel', o.gatZ0sel, 'ovr', o.ovr));
S  = phase4_sources(caseID, o.XdRole);

% ---- registry canonicals (C8: no duplicated literals below) ----
Rr = phase4_registry();
Zbase_LV = Rr.lv.Zbase_ohm.value;  % 0.4356 ohm (6.6 kV LV zone)
aLVnom = Rr.lv.a_nominal.value;    % 6.9/6.6 documented nominal LV tap magnitude (no operating-tap invention)
kMreg = Rr.frozen.Sbase_MVA.value/Rr.machine.Snom_MVA.value;  % 100/458 MVA-ratio transfer

% ---- frozen summary row: Export + aux-lv voltage ----
root = ashuganj_root();
Ts = readtable(fullfile(root, 'results', 'phase3_loadflow', 'phase3_system_summary.csv'));
js = find(string(Ts.Case_ID) == string(caseID), 1);
if isempty(js)
    error('phase4_solve:missingRow', 'No system-summary row for case ''%s''.', caseID);
end
ExpP = Ts.Export_P_MW(js); ExpQ = Ts.Export_Q_MVAr(js); V66kV = Ts.V6_6_kV(js);

% ---- study-base sources ----
if strcmp(o.XdRole, 'sat')
    Zpp = N.Z1gen_sat_R + 1j*N.Z1gen_sat_X;
else
    Zpp = N.Z1gen_unsat_R + 1j*N.Z1gen_unsat_X;
end
Z2gen = N.Z2gen_R + 1j*N.Z2gen_X;
Epp = S.Epp;  % machine-pu voltage == study-pu voltage (zone-nominal bases)
Vrem = (PF.Vremote_kV/230)*exp(1j*PF.AngRemote_deg*pi/180);
Z1grid = N.Z1grid_R + 1j*N.Z1grid_X;
Igrid = conj((ExpP + 1j*ExpQ)/100/Vrem);
Eg = Vrem + Z1grid*Igrid;

% ---- T9 stage sources (ADDITIVE: Ikpp lines above untouched) ----
% 'Ib' uses APPROXIMATION fallback E' = Vt + (Ra + j*Xd')*It with
% Z' = Ra + j*Xd' (Xd' = 0.3256 machine base, same MVA-ratio transfer as
% Zpp path). Constant-E' reference approximation at specified t_break;
% t_break is input only (no default, no decay model); no mu/q
% post-processing. Two-axis sensitivity is carried downstream (D5).
% 'Isteady' uses constant-field synchronous reference Esync =
% Vt + (Ra + j*Xd)*It with Zsync = Ra + j*Xd (Xd = 1.7830); no
% AVR/governor. Two-axis (Edp/Eqp) and field (Eq) values are NOT injected
% (single-sequence engine); they remain reported diagnostics from
% phase4_sources. Both stages reuse the same Norton/Ybus/coupling/audit
% machinery below; audit and prefault gate apply to every stage.
if strcmp(stage, 'Ib')
    kM_T9 = kMreg;
    RaStudy_T9 = N.Z1gen_sat_R;  % same Ra transfer as Zpp path
    RaMach_T9 = RaStudy_T9/kM_T9;
    Xdp_T9 = Rr.machine.Xdp.value;  % 0.3256 (registry, not literal)
    Epp = S.Vt_pu + (RaMach_T9 + 1j*Xdp_T9)*S.It_pu;
    Zpp = RaStudy_T9 + 1j*Xdp_T9*kM_T9;
elseif strcmp(stage, 'Isteady')
    kM_T9 = kMreg;
    RaStudy_T9 = N.Z1gen_sat_R;  % same Ra transfer as Zpp path
    RaMach_T9 = RaStudy_T9/kM_T9;
    Xd_T9 = Rr.machine.Xd.value;  % 1.7830 (registry, not literal)
    Epp = S.Vt_pu + (RaMach_T9 + 1j*Xd_T9)*S.It_pu;
    Zpp = RaStudy_T9 + 1j*Xd_T9*kM_T9;
end

% ---- aux shunt (ENGINEERING_ASSUMPTION constant-Z, fitted at prefault) ----
% LV-zone base (correction record C1/C2): 6.6-kV bus base 0.4356 ohm, NOT
% the 230-kV 529-ohm base (that was a 1214x base error collapsing B6_6).
Saux_MVA = PF.auxP_MW + 1j*PF.auxQ_MVAr;
Zaux_ohm = (V66kV*1000)^2/conj(Saux_MVA*1e6);
Zaux = Zaux_ohm/Zbase_LV;

% ---- topology / node map ----
isF4 = strcmp(loc, 'F4');
if isF4
    TOP = phase4_topology(o.m, 'B', o.coupler);
else
    TOP = phase4_topology(0, 'lumped', o.coupler);
end
nB22 = TOP.nodeB22; n230a = TOP.nodeB230_1; nRem = TOP.nodeB230_REMOTE;
if strcmp(o.coupler, 'open'), nGatHV = TOP.nodeB230_2; else, nGatHV = n230a; end
coupOpen = strcmp(o.coupler, 'open');
useF4node = isF4 && o.m > 0 && o.m < 1;
switch loc
    case {'F1','F2'}, fG = nB22;
    case 'F3',        fG = n230a;
    case 'F5',        fG = nRem;
    case 'F4'
        if o.m <= 0, fG = n230a; elseif o.m >= 1, fG = nRem; else, fG = TOP.nodeF4; end
end

% ---- active node sets (global indices) ----
pn = [1, 2, 4, 5, 6];
% Coupler-open B230_2 (node 3) is a dead floating bus unless the GAT is in
% (its only tee); a zero-branch node would singularise Ybus, so it joins
% the active set only when GAT_in connects it.
if coupOpen && PF.GAT_in, pn = [pn, 3]; end
if useF4node, pn = [pn, 7]; end
pn = sort(pn);
zn = sort(unique([pn(pn ~= 5), 5, 8, 9]));  % zero: node 5 GROUNDED far end + neutrals

[Y1, J1v] = buildPN(pn, true);
[Y2, ~]   = buildPN(pn, false);
Yz        = buildZ(zn);

% ---- no-fault positive solve (grid internal fixed at Eg) ----
Vok = solveKnown(Y1, J1v, pn, 5, Eg);

% ---- prefault-reproduction gate ----
V1csv = (PF.Vt_B22_kV/Rr.machine.Vnom_kV.value)*exp(1j*PF.Ang_B22_deg*pi/180);
V2csv = (PF.V230_1_kV/230)*exp(1j*PF.Ang230_1_deg*pi/180);
V4csv = (PF.Vremote_kV/230)*exp(1j*PF.AngRemote_deg*pi/180);
g2l = glmap(pn);
d1 = abs(Vok(g2l(1)) - V1csv)/abs(V1csv);
d2 = abs(Vok(g2l(n230a)) - V2csv)/abs(V2csv);
d4 = abs(Vok(g2l(nRem)) - V4csv)/abs(V4csv);
pre_res = max([d1, d2, d4]);
% Dominant residual driver unattributed; gate passes with ~2x margin
% (measured: Eg-sign alternative 4.75%->4.48%, UAT-tap variants <1e-4, so
% neither closes it; residual sits at node 1 — tap/modelling detail below
% gate resolution, left as-is per tolerance rationale).
fprintf('phase4_solve %s %s ds=%s m=%.3f: pre_res=%.6f (n1=%.6f n2=%.6f n4=%.6f)\n', ...
    char(string(caseID)), type, ds, o.m, pre_res, d1, d2, d4);
if ~(pre_res <= 0.10)
    error('phase4_solve:prefault', ['Prefault-reproduction gate tripped: pre_res=%.4f > 0.10 ' ...
        '(source/network sign or wiring bug; gate and tolerance are binding).'], pre_res);
end
% ---- B6_6 prefault gate (correction record C3; hypothesis tol below) ----
T_B66 = 0.05;  % MEASURED residual 0.0257 (OUT) after aux+tap fix: 0.65% magnitude +
% ~1.4 deg angle. Hand-check: tap-boosted no-load 1.04545 pu minus loaded drop
% (16.47 MVA through 10.5%/25-MVA Z gives ~4.2%) predicts ~1.003 pu vs CSV
% 1.000909: model structurally correct. Residual is second-order noise
% (UAT R-split approximate marker, Eg approximation). Tol 0.05 = ~2x measured
% with 10-20x headroom below defect signatures (0.50-1.00 demonstrated pre-fix).
Tb66 = readtable(fullfile(root, 'results', 'phase3_loadflow', 'phase3_bus_results.csv'));
jb66o = find(string(Tb66.Case_ID) == string(caseID) & string(Tb66.Bus_Name) == 'B6_6', 1);
if isempty(jb66o)
    error('phase4_solve:b66row', 'No B6_6 row for case ''%s'' in phase3_bus_results.csv.', caseID);
end
V66csv = (Tb66.V_kV(jb66o)/6.6)*exp(1j*Tb66.Angle_deg(jb66o)*pi/180);
g66 = glmap(pn); V66 = Vok(g66(6));
d66 = abs(V66 - V66csv)/abs(V66csv);
fprintf('phase4_solve %s B6_6: solved=%.6f pu target=%.6f pu d6=%.6f tol=%.2f\n', ...
    char(string(caseID)), abs(V66), abs(V66csv), d66, T_B66);
if ~(d66 <= T_B66)
    error('phase4_solve:b66gate', ['B6_6 prefault gate tripped: d6=%.4f > %.2f ' ...
        '(aux-base/tap/wiring bug; see correction record).'], d66, T_B66);
end

% ---- prefault voltage at fault node ----
Vf_nodal = Vok(g2l(fG));
switch loc
    case {'F1','F2'}, Vf_csv = V1csv;
    case 'F3',        Vf_csv = V2csv;
    case 'F5',        Vf_csv = V4csv;
    case 'F4'  % audit-only approximation: linear complex interpolation by m
        Vf_csv = V2csv + o.m*(V4csv - V2csv);
end

% ---- fault solve (one coupled KCL system) ----
% Level base for Zf pu (mirrors Zbase_level table in phase4_stages:48-51):
% F1/F2 22 kV -> 4.84 ohm; F3/F4/F5 230 kV -> 529 ohm. B6_6 needs no entry
% (no fault placement there).
if any(strcmp(loc, {'F1','F2'})), Zbase_level = 4.84; else, Zbase_level = 529; end
Zfpu = Zf_ohm/Zbase_level;
l1 = g2l(fG); lz = glmap(zn); lz_f = lz(fG);
n1n = numel(pn); nzn = numel(zn);
switch type
    case 'LLL'
        if Zfpu > 0
            Yf = Y1; Yf(l1, l1) = Yf(l1, l1) + 1/Zfpu;
            V1f = solveKnown(Yf, J1v, pn, 5, Eg);
            I1 = V1f(l1)/Zfpu;  % INTO fault
            V1F = V1f(l1);
        else
            V1f = solveKnown(Y1, J1v, pn, [5, fG], [Eg, 0]);
            V1F = 0;
            I1 = J1v(l1) - Y1(l1, :)*V1f;  % KCL residual INTO fault
        end
        I2 = 0; I0 = 0; V2F = 0; V0F = 0;
        Vf1 = V1f; Vf2 = zeros(n1n, 1); Vf0 = zeros(nzn, 1);  % OUTPUT-ONLY retain
    case 'LG'
        % unknowns [V1;V2;V0;If]: single shared If INTO fault (series loop)
        nT = 2*n1n + nzn + 1;
        A = zeros(nT); rhs = zeros(nT, 1);
        A(1:n1n, 1:n1n) = Y1;                        A(1:n1n, nT) = eVec(n1n, l1);
        A(n1n+1:2*n1n, n1n+1:2*n1n) = Y2;             A(n1n+1:2*n1n, nT) = eVec(n1n, l1);
        A(2*n1n+1:2*n1n+nzn, 2*n1n+1:2*n1n+nzn) = Yz; A(2*n1n+1:2*n1n+nzn, nT) = eVec(nzn, lz_f);
        A(nT, l1) = 1; A(nT, n1n + l1) = 1; A(nT, 2*n1n + lz_f) = 1; A(nT, nT) = -3*Zfpu;
        rhs(1:n1n) = J1v;
        x = solveCoupled(A, rhs, n1n, nzn, pn);
        V1F = x(l1); V2F = x(n1n + l1); V0F = x(2*n1n + lz_f);
        I1 = x(nT); I2 = x(nT); I0 = x(nT);
        Vf1 = x(1:n1n); Vf2 = x(n1n+1:2*n1n); Vf0 = x(2*n1n+1:2*n1n+nzn);  % OUTPUT-ONLY retain
    case 'LL'
        % unknowns [V1;V2;If]: I1 = If, I2 = -If (INTO fault), I0 = 0
        nT = 2*n1n + 1;
        A = zeros(nT); rhs = zeros(nT, 1);
        A(1:n1n, 1:n1n) = Y1;             A(1:n1n, nT) = eVec(n1n, l1);
        A(n1n+1:2*n1n, n1n+1:2*n1n) = Y2; A(n1n+1:2*n1n, nT) = -eVec(n1n, l1);
        A(nT, l1) = 1; A(nT, n1n + l1) = -1; A(nT, nT) = -Zfpu;
        rhs(1:n1n) = J1v;
        x = solveCoupled(A, rhs, n1n, 0, pn);
        V1F = x(l1); V2F = x(n1n + l1); V0F = 0;
        I1 = x(nT); I2 = -x(nT); I0 = 0;
        Vf1 = x(1:n1n); Vf2 = x(n1n+1:2*n1n); Vf0 = zeros(nzn, 1);  % OUTPUT-ONLY retain
        if ~(abs(I0) < 1e-9)
            error('phase4_solve:llZero', 'LL I0 construction breach.');
        end
    case 'LLG'
        % unknowns [V1;V2;V0;If1;If2;If0;Vc]: explicit common node c
        iF1 = 2*n1n + nzn + 1; iF2 = iF1 + 1; iF0 = iF2 + 1; iVc = iF0 + 1;
        nT = iVc;
        A = zeros(nT); rhs = zeros(nT, 1);
        A(1:n1n, 1:n1n) = Y1;                        A(1:n1n, iF1) = eVec(n1n, l1);
        A(n1n+1:2*n1n, n1n+1:2*n1n) = Y2;             A(n1n+1:2*n1n, iF2) = eVec(n1n, l1);
        A(2*n1n+1:2*n1n+nzn, 2*n1n+1:2*n1n+nzn) = Yz; A(2*n1n+1:2*n1n+nzn, iF0) = eVec(nzn, lz_f);
        A(iF1, l1) = 1;           A(iF1, iVc) = -1;
        A(iF2, n1n + l1) = 1;     A(iF2, iVc) = -1;
        A(iF0, 2*n1n + lz_f) = 1; A(iF0, iVc) = -1; A(iF0, iF0) = -3*Zfpu;
        A(iVc, iF1) = 1; A(iVc, iF2) = 1; A(iVc, iF0) = 1;
        rhs(1:n1n) = J1v;
        x = solveCoupled(A, rhs, n1n, nzn, pn);
        V1F = x(l1); V2F = x(n1n + l1); V0F = x(2*n1n + lz_f);
        I1 = x(iF1); I2 = x(iF2); I0 = x(iF0);
        Vf1 = x(1:n1n); Vf2 = x(n1n+1:2*n1n); Vf0 = x(2*n1n+1:2*n1n+nzn);  % OUTPUT-ONLY retain
end

% ---- Fortescue to phases (INTO fault) ----
a120 = exp(1j*2*pi/3);
Ia = I0 + I1 + I2;
Ib = I0 + a120^2*I1 + a120*I2;
Ic = I0 + a120*I1 + a120^2*I2;

% ---- Thevenin audit (independent path; sources zeroed, 1 pu injected) ----
Zth1 = thev(Y1, pn, l1);
Zth2 = thev(Y2, pn, l1);
Zth0 = thev(Yz, zn, lz_f);
[Is1, Is2, Is0] = scalars(type, Vf_nodal, Zth1, Zth2, Zth0, Zfpu);
audit_res = max([relTerm(I1, Is1), relTerm(I2, Is2), relTerm(I0, Is0)]);

% ---- ip ----
r = real(Zth1)/imag(Zth1);
if ~(r > 0)  % resistive-limit guard
    kappa = 1.02;
else
    kappa = phase4_kappa(r);
end
switch type
    case 'LG',        gov = abs(Ia);
    case {'LL','LLG'}, gov = max(abs(Ib), abs(Ic));
    case 'LLL',       gov = abs(I1);
end
ip = kappa*sqrt(2)*gov;

fprintf(['phase4_solve %s %s %s Zf=%.4g: |I1|=%.6f |I2|=%.6f |I0|=%.6f ' ...
    'Zth1=%.6f%+.6fj audit=%.3g r=%.4f k=%.5f ip=%.6f\n'], ...
    char(string(caseID)), loc, type, Zf_ohm, abs(I1), abs(I2), abs(I0), ...
    real(Zth1), imag(Zth1), audit_res, r, kappa, ip);

F = struct('I1', I1, 'I2', I2, 'I0', I0, 'Ia', Ia, 'Ib', Ib, 'Ic', Ic, ...
    'V1F', V1F, 'V2F', V2F, 'V0F', V0F, 'audit_res', audit_res, ...
    'r', r, 'kappa', kappa, 'ip', ip, 'Vf', Vf_nodal, ...
    'Zth1', Zth1, 'Zth2', Zth2, 'Zth0', Zth0, ...
    'pre_res', pre_res, 'stage', stage, 'Vf_csv', Vf_csv, 'Eg', Eg);
% ---- OUTPUT-ONLY extraction (Task 10: retained vectors + branch table;
% ---- no change to any field above, no change to math/gates/audit) ----
F.Vbus1 = Vf1; F.Vbus2 = Vf2; F.Vbus0 = Vf0;
F.pn = pn; F.zn = zn;
F.GAT_in = PF.GAT_in; F.faultNode = fG; F.isF4 = isF4; F.mF4 = o.m;
F.Vok = Vok;  % OUTPUT-ONLY no-fault positive voltages (local order over pn; V-A leg target, never faulted values)
F.Zaux_pu = Zaux;  % as stamped (LV-zone base; correction record C1)
F.tapUAT_LV = aLVnom;  % applied LV-side tap factor Vwind/Vbase = 6.9/6.6 (correction record C2)
F.tapGAT_LV = aLVnom;  % same nominal tap on GAT LV (0 deg shift both sequences)
F.branch = buildBranch();
% =====================================================================
% ---- nested builders / solvers (capture N,Z,Epp,Eg,Zpp,Z2gen,Zaux,flags)
% =====================================================================
    function B = buildBranch()
        %BUILDBRANCH  OUTPUT-ONLY per-branch sequence currents.
        %   Currents in from->to reference from the retained solved
        %   voltages times the SAME branch admittances as the Ybus build
        %   above (identical expressions over the same workspace N/Z vars;
        %   nothing redefined). GSUT keeps both tap-aware ends (LV = 1->2,
        %   HV = 2->1); zero ground legs are separate rows (GSUT0/UATN/
        %   GATN/GATLOOP/NER); lumped LINE and GRID rows carry their zero
        %   currents folded in (same endpoints); F4 uses S/R/H section rows
        %   (interior m) or F/H direct rows (degenerate m = 0/1).
        g1 = glmap(pn); g0 = glmap(zn);
        V1p = @(g) Vf1(g1(g)); V2n = @(g) Vf2(g1(g)); V0z = @(g) Vf0(g0(g));
        B = struct('name', {}, 'from', {}, 'to', {}, 'I1', {}, 'I2', {}, 'I0', {});
        % machine internal (-1) -> B22
        B = addB(B, 'GEN', -1, 1, (Epp - V1p(1))/Zpp, (0 - V2n(1))/Z2gen, 0);
        % gen zero chain 1->8->earth
        B = addB(B, 'GEN0', 1, 8, 0, 0, (V0z(1) - V0z(8))/Z.Z0gen_pu);
        B = addB(B, 'NER', 8, 0, 0, 0, V0z(8)/Z.Z3ZN_pu);
        % GSUT series ends with complex tap (same yg/a as buildPN)
        yg1 = 1/(N.Z1gsut_R + 1j*N.Z1gsut_X); a1 = exp(1j*pi/6);
        yg2 = 1/(N.Z2gsut_R + 1j*N.Z2gsut_X); a2 = exp(-1j*pi/6);
        B = addB(B, 'GSUT_LV', 1, n230a, yg1*(V1p(1) - V1p(n230a)/a1), yg2*(V2n(1) - V2n(n230a)/a2), 0);
        B = addB(B, 'GSUT_HV', n230a, 1, yg1*(V1p(n230a) - V1p(1)/conj(a1)), yg2*(V2n(n230a) - V2n(1)/conj(a2)), 0);
        B = addB(B, 'GSUT0', n230a, 0, 0, 0, V0z(n230a)/Z.Z0gsut_pu);
        % UAT 1->6 tap-aware (per-sequence complex taps; from->to reference)
        yu1 = 1/(N.Z1uat_R + 1j*N.Z1uat_X);
        yu2 = 1/(N.Z2uat_R + 1j*N.Z2uat_X);
        aUp = (1/aLVnom)*exp(-1j*pi/6); aUn = (1/aLVnom)*exp(+1j*pi/6);
        B = addB(B, 'UAT', 1, 6, (yu1/abs(aUp)^2)*V1p(1) - (yu1/conj(aUp))*V1p(6), (yu2/abs(aUn)^2)*V2n(1) - (yu2/conj(aUn))*V2n(6), 0);
        B = addB(B, 'UAT0', 6, 9, 0, 0, (V0z(6) - V0z(9))/Z.Z0uat_pu);
        B = addB(B, 'UATN', 9, 0, 0, 0, V0z(9)/Z.Z3N_UAT_equiv_pu);
        % GAT HV-tee -> 6 iff case GAT_in (same Z as buildPN/buildZ)
        % Task-12 H3HV envelope: series addition, same Z0gat_eff as buildZ.
        if PF.GAT_in
            ya1 = 1/(N.Z1gat_R + 1j*N.Z1gat_X);
            ya2 = 1/(N.Z2gat_R + 1j*N.Z2gat_X);
            Z0gat_effB = Z.Z0gat_HVLV_pu + Z.ZN_GATHV_pu;
            aGb = 1/aLVnom;
            y0gB = 1/Z0gat_effB;
            B = addB(B, 'GAT_HV', nGatHV, 6, (ya1/abs(aGb)^2)*V1p(nGatHV) - (ya1/conj(aGb))*V1p(6), (ya2/abs(aGb)^2)*V2n(nGatHV) - (ya2/conj(aGb))*V2n(6), 0);
            B = addB(B, 'GAT_LV', 6, nGatHV, ya1*V1p(6) - (ya1/aGb)*V1p(nGatHV), ya2*V2n(6) - (ya2/aGb)*V2n(nGatHV), 0);
            B = addB(B, 'GAT0', nGatHV, 6, 0, 0, (y0gB/abs(aGb)^2)*V0z(nGatHV) - (y0gB/conj(aGb))*V0z(6));
            B = addB(B, 'GATN', 6, 0, 0, 0, V0z(6)/Z.Z3N_GAT_equiv_pu);
            if ~strcmp(o.gatLeg, 'H0') && ~isnan(Z.Z_T0_loop_pu) && Z.Z_T0_loop_pu ~= 0
                B = addB(B, 'GATLOOP', 6, 0, 0, 0, V0z(6)/Z.Z_T0_loop_pu);
            end
        end
        % line / grid (lumped or B-view; same Z as buildPN/buildZ)
        % Task-12 lineScale: same totals scaling as buildPN/buildZ.
        Z0ln = o.lineScale * (Z.Z0line_R_pu + 1j*Z.Z0line_X_pu);
        Z0gr = o.k0g*(N.Z1grid_R + 1j*N.Z1grid_X);
        if ~isF4
            yl1 = 1/(o.lineScale*(N.Z1line_R + 1j*N.Z1line_X));
            yl2 = 1/(o.lineScale*(N.Z2line_R + 1j*N.Z2line_X));
            B = addB(B, 'LINE', n230a, nRem, yl1*(V1p(n230a) - V1p(nRem)), ...
                yl2*(V2n(n230a) - V2n(nRem)), (V0z(n230a) - V0z(nRem))/Z0ln);
        else
            Zln1 = o.lineScale*(N.Z1line_R + 1j*N.Z1line_X); Zln2 = o.lineScale*(N.Z2line_R + 1j*N.Z2line_X);
            Zb1 = 2*Zln1; Zb2 = 2*Zln2; Zb0 = 2*Z0ln;
            yh1 = 1/Zb1; yh2 = 1/Zb2; yh0 = 1/Zb0;
            B = addB(B, 'LINE_H', n230a, nRem, yh1*(V1p(n230a) - V1p(nRem)), ...
                yh2*(V2n(n230a) - V2n(nRem)), yh0*(V0z(n230a) - V0z(nRem)));
            if useF4node
                yS1 = 1/(o.m*Zb1); yS2 = 1/(o.m*Zb2); yS0 = 1/(o.m*Zb0);
                yR1 = 1/((1 - o.m)*Zb1); yR2 = 1/((1 - o.m)*Zb2); yR0 = 1/((1 - o.m)*Zb0);
                B = addB(B, 'LINE_S', n230a, 7, yS1*(V1p(n230a) - V1p(7)), ...
                    yS2*(V2n(n230a) - V2n(7)), yS0*(V0z(n230a) - V0z(7)));
                B = addB(B, 'LINE_R', 7, nRem, yR1*(V1p(7) - V1p(nRem)), ...
                    yR2*(V2n(7) - V2n(nRem)), yR0*(V0z(7) - V0z(nRem)));
            else
                yF1 = 1/Zb1; yF2 = 1/Zb2; yF0 = 1/Zb0;
                B = addB(B, 'LINE_F', n230a, nRem, yF1*(V1p(n230a) - V1p(nRem)), ...
                    yF2*(V2n(n230a) - V2n(nRem)), yF0*(V0z(n230a) - V0z(nRem)));
            end
        end
        % grid internal (5) -> remote (4), all sequences (node 5 = Eg/0/0)
        ygr1 = 1/Z1grid; ygr2 = 1/(N.Z2grid_R + 1j*N.Z2grid_X); ygr0 = 1/Z0gr;
        B = addB(B, 'GRID', 5, 4, ygr1*(V1p(5) - V1p(4)), ...
            ygr2*(V2n(5) - V2n(4)), ygr0*(V0z(5) - V0z(4)));
        % aux constant-Z shunt at 6 (positive only, same Zaux as buildPN)
        B = addB(B, 'AUX', 6, 0, V1p(6)/Zaux, 0, 0);
    end
    function [Y, J] = buildPN(list, withSrc)
        g = glmap(list); n = numel(list);
        Y = zeros(n); J = zeros(n, 1);
        if withSrc
            ypp = 1/Zpp;
            Y(g(1), g(1)) = Y(g(1), g(1)) + ypp;
            J(g(1)) = J(g(1)) + Epp*ypp;
        else
            Y(g(1), g(1)) = Y(g(1), g(1)) + 1/Z2gen;  % zeroed Norton: shunt stays
        end
        if withSrc
            Zgs = N.Z1gsut_R + 1j*N.Z1gsut_X; a = exp(1j*pi/6);   % +30 deg YNd1
            Zus = N.Z1uat_R + 1j*N.Z1uat_X;
            Zln = N.Z1line_R + 1j*N.Z1line_X;
            Zgr = Z1grid;
            Zga = N.Z1gat_R + 1j*N.Z1gat_X;
            aU = (1/aLVnom)*exp(-1j*pi/6);  % UAT Dyn11: LV LEADS HV 30 deg (correction record C2; B6_6 complex gate pins it)
        else
            Zgs = N.Z2gsut_R + 1j*N.Z2gsut_X; a = exp(-1j*pi/6);  % conjugate
            Zus = N.Z2uat_R + 1j*N.Z2uat_X;
            Zln = N.Z2line_R + 1j*N.Z2line_X;
            Zgr = N.Z2grid_R + 1j*N.Z2grid_X;
            Zga = N.Z2gat_R + 1j*N.Z2gat_X;
            aU = (1/aLVnom)*exp(+1j*pi/6);  % conjugate (passive phase-shift theory; mirrors GSUT pair)
        end
        % Task-12 lineScale: multiplies line series totals (all sequences);
        % B-view per-circuit totals and m/(1-m) fractions unchanged in form.
        Zln = o.lineScale * Zln;
        % GSUT 1->2 with complex tap: Y11 += y; Y12 += -y/a; Y21 += -y/conj(a); Y22 += y
        yg = 1/Zgs;
        Y(g(1), g(1)) = Y(g(1), g(1)) + yg;
        Y(g(1), g(n230a)) = Y(g(1), g(n230a)) - yg/a;
        Y(g(n230a), g(1)) = Y(g(n230a), g(1)) - yg/conj(a);
        Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yg;
        % UAT 1->6 with documented nominal LV tap (correction record C2):
        % aU = V_HV/V_LV, magnitude 1/aLVnom = 0.95652, Dyn11 LV-lead shift
        % -30 deg pos / +30 deg neg (aU set per branch above; LV plain
        % node mirrors the verified GSUT pattern Y_LL+=y, Y_LH-=y/a,
        % Y_HL-=y/conj(a), Y_HH+=y/|a|^2). No-load: 22 kV in gives 6.9 kV =
        % 1.04545 pu on the 6.6-kV bus base at +30 deg LV lead.
        % No operating-tap invention: nominal documented ratio only.
        yu = 1/Zus;
        Y(g(6), g(6)) = Y(g(6), g(6)) + yu;
        Y(g(6), g(1)) = Y(g(6), g(1)) - yu/aU;
        Y(g(1), g(6)) = Y(g(1), g(6)) - yu/conj(aU);
        Y(g(1), g(1)) = Y(g(1), g(1)) + yu/abs(aU)^2;
        if withSrc
            Y(g(6), g(6)) = Y(g(6), g(6)) + 1/Zaux;  % aux shunt, positive only
        end
        % GAT HV-tee -> 6 iff case GAT_in (nominal LV tap aG = 1/aLVnom,
        % same GSUT-pattern form as UAT above; 0 deg shift both sequences)
        if PF.GAT_in
            ya = 1/Zga;
            aG = 1/aLVnom;
            Y(g(6), g(6)) = Y(g(6), g(6)) + ya;
            Y(g(6), g(nGatHV)) = Y(g(6), g(nGatHV)) - ya/aG;
            Y(g(nGatHV), g(6)) = Y(g(nGatHV), g(6)) - ya/conj(aG);
            Y(g(nGatHV), g(nGatHV)) = Y(g(nGatHV), g(nGatHV)) + ya/abs(aG)^2;
        end
        % line / grid (lumped or B-view)
        if ~isF4
            yl = 1/Zln;
            Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yl;
            Y(g(n230a), g(nRem)) = Y(g(n230a), g(nRem)) - yl;
            Y(g(nRem), g(n230a)) = Y(g(nRem), g(n230a)) - yl;
            Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + yl;
        else
            Zb = 2*Zln;  % per-circuit totals
            yh = 1/Zb;   % healthy circuit direct 2->4
            Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yh;
            Y(g(n230a), g(nRem)) = Y(g(n230a), g(nRem)) - yh;
            Y(g(nRem), g(n230a)) = Y(g(nRem), g(n230a)) - yh;
            Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + yh;
            if useF4node
                m = o.m;
                yS = 1/(m*Zb); yR = 1/((1-m)*Zb);  % faulted circuit 2->7->4
                Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yS;
                Y(g(n230a), g(7)) = Y(g(n230a), g(7)) - yS;
                Y(g(7), g(n230a)) = Y(g(7), g(n230a)) - yS;
                Y(g(7), g(7)) = Y(g(7), g(7)) + yS + yR;
                Y(g(7), g(nRem)) = Y(g(7), g(nRem)) - yR;
                Y(g(nRem), g(7)) = Y(g(nRem), g(7)) - yR;
                Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + yR;
            elseif o.m <= 0
                yF = 1/Zb;  % faulted circuit also direct (m = 0)
                Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yF;
                Y(g(n230a), g(nRem)) = Y(g(n230a), g(nRem)) - yF;
                Y(g(nRem), g(n230a)) = Y(g(nRem), g(n230a)) - yF;
                Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + yF;
            else
                yF = 1/Zb;  % faulted circuit also direct (m = 1)
                Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + yF;
                Y(g(n230a), g(nRem)) = Y(g(n230a), g(nRem)) - yF;
                Y(g(nRem), g(n230a)) = Y(g(nRem), g(n230a)) - yF;
                Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + yF;
            end
        end
        % grid branch 4->5 (node 5 value imposed by caller)
        ygr = 1/Zgr;
        Y(g(nRem), g(nRem)) = Y(g(nRem), g(nRem)) + ygr;
        Y(g(nRem), g(5)) = Y(g(nRem), g(5)) - ygr;
        Y(g(5), g(nRem)) = Y(g(5), g(nRem)) - ygr;
        Y(g(5), g(5)) = Y(g(5), g(5)) + ygr;
    end

    function Y = buildZ(list)
        g = glmap(list); n = numel(list);
        Y = zeros(n);
        % gen chain 1->8 (Z0gen) -> ground (3ZN)
        Y = stamp2(Y, g, 1, 8, 1/Z.Z0gen_pu);
        Y(g(8), g(8)) = Y(g(8), g(8)) + 1/Z.Z3ZN_pu;
        % GSUT HV leg 2->ground
        Y(g(n230a), g(n230a)) = Y(g(n230a), g(n230a)) + 1/Z.Z0gsut_pu;
        % UAT 6->9 (Z0uat) -> ground (Z3N_UAT_equiv_pu: single x3 upstream,
        % stamped directly here, never multiplied again)
        Y = stamp2(Y, g, 6, 9, 1/Z.Z0uat_pu);
        Y(g(9), g(9)) = Y(g(9), g(9)) + 1/Z.Z3N_UAT_equiv_pu;
        % GAT zero iff GAT_in (best-effort H-leg; see header)
        % Task-12 H3HV envelope: ZN_GATHV_pu adds in series to the HV-LV
        % zero path when IN (additive only; base 0 reproduces exactly).
        % Magnitude tap aG = 1/aLVnom on the HV-LV through path (0 deg;
        % same GSUT-pattern form as positive buildPN).
        if PF.GAT_in
            Z0gat_eff = Z.Z0gat_HVLV_pu + Z.ZN_GATHV_pu;
            y0g = 1/Z0gat_eff;
            aG0 = 1/aLVnom;
            Y(g(6), g(6)) = Y(g(6), g(6)) + y0g;
            Y(g(6), g(nGatHV)) = Y(g(6), g(nGatHV)) - y0g/aG0;
            Y(g(nGatHV), g(6)) = Y(g(nGatHV), g(6)) - y0g/conj(aG0);
            Y(g(nGatHV), g(nGatHV)) = Y(g(nGatHV), g(nGatHV)) + y0g/abs(aG0)^2;
            Y(g(6), g(6)) = Y(g(6), g(6)) + 1/Z.Z3N_GAT_equiv_pu;  % LV neutral to ground (single x3 upstream)
            if ~strcmp(o.gatLeg, 'H0') && ~isnan(Z.Z_T0_loop_pu) && Z.Z_T0_loop_pu ~= 0
                % H1: closed-tertiary 100-MVA loop; H2: explicit 1e-6 short-limit.
                % H0 omits (tertiary open). Correction record C4/C5.
                Y(g(6), g(6)) = Y(g(6), g(6)) + 1/Z.Z_T0_loop_pu;
            end
        end
        % line zero 2->4 (+B-view split) and grid zero 4->5
        % Task-12 lineScale: multiplies zero-band totals (series+shunt);
        % shunt B itself is not stamped (PI shunt omitted, ~1e-5 effect);
        % B-view/m-division fractions unchanged in form.
        Z0ln = o.lineScale * (Z.Z0line_R_pu + 1j*Z.Z0line_X_pu);
        Z0gr = o.k0g*(N.Z1grid_R + 1j*N.Z1grid_X);  % same-angle scaling
        if ~isF4
            Y = stamp2(Y, g, n230a, nRem, 1/Z0ln);
        else
            Zb0 = 2*Z0ln;
            Y = stamp2(Y, g, n230a, nRem, 1/Zb0);
            if useF4node
                m = o.m;
                Y = stamp2(Y, g, n230a, 7, 1/(m*Zb0));
                Y = stamp2(Y, g, 7, nRem, 1/((1-m)*Zb0));
            else
                Y = stamp2(Y, g, n230a, nRem, 1/Zb0);
            end
        end
        Y = stamp2(Y, g, nRem, 5, 1/Z0gr);  % node 5 GROUNDED far end in zero
    end

    function Y = stamp2(Y, g, i, j, y)
        Y(g(i), g(i)) = Y(g(i), g(i)) + y;
        Y(g(i), g(j)) = Y(g(i), g(j)) - y;
        Y(g(j), g(i)) = Y(g(j), g(i)) - y;
        Y(g(j), g(j)) = Y(g(j), g(j)) + y;
    end

    function V = solveKnown(Y, J, list, fixG, fixV)
        % Solve Y*V = J over `list` with global nodes fixG held at fixV.
        g = glmap(list);
        lf = g(fixG);
        fr = setdiff(1:numel(list), lf);
        Vf = zeros(numel(list), 1);
        Vf(lf) = fixV(:);
        Vf(fr) = (Y(fr, fr))\(J(fr) - Y(fr, lf)*Vf(lf));
        V = Vf;
    end

    function x = solveCoupled(A, rhs, n1n, nzn, plist)
        % Substitute known node-5 voltages (Eg pos, 0 neg/zero) in a
        % coupled layer system with per-layer blocks over plist/zn.
        g = glmap(plist); l5 = g(5);
        kn = [l5; n1n + l5];
        kv = [Eg; 0];
        if nzn > 0
            gz = glmap(zn);
            kn = [kn; 2*n1n + gz(5)]; kv = [kv; 0];
        end
        fr = setdiff(1:size(A, 1), kn);
        x = zeros(size(A, 1), 1);
        x(kn) = kv;
        x(fr) = A(fr, fr)\(rhs(fr) - A(fr, kn)*x(kn));
    end

    function Zth = thev(Y, list, lf)
        % Sources zeroed (J = 0; grid far end node 5 GROUNDED, i.e. the
        % series-Z-to-grounded-node Thevenin form): inject 1 pu at fault node.
        fGlo = list(lf);  % fault global node (never 5)
        act = list(list ~= 5);
        gf = glmap(list);   % global -> local over the full list (Y rows/cols)
        ga = glmap(act);    % global -> local over the reduced set
        keep = gf(act);     % surviving rows/cols of Y
        Yt = Y(keep, keep);
        e = zeros(numel(act), 1); e(ga(fGlo)) = 1;
        V = Yt\e;
        Zth = V(ga(fGlo));
    end
end

% =====================================================================
function m = glmap(list)
m = zeros(9, 1);
for k = 1:numel(list), m(list(k)) = k; end
end

function e = eVec(n, k)
e = zeros(n, 1); e(k) = 1;
end

function [s1, s2, s0] = scalars(type, Vf, Z1, Z2, Z0, Zf)
switch type
    case 'LLL'
        s1 = Vf/(Z1 + Zf); s2 = 0; s0 = 0;
    case 'LG'
        s = Vf/(Z1 + Z2 + Z0 + 3*Zf); s1 = s; s2 = s; s0 = s;
    case 'LL'
        s1 = Vf/(Z1 + Z2 + Zf); s2 = -s1; s0 = 0;
    case 'LLG'
        D = Z1*(Z2 + Z0 + 3*Zf) + Z2*(Z0 + 3*Zf);
        s1 = Vf*(Z2 + Z0 + 3*Zf)/D;
        s2 = -Vf*(Z0 + 3*Zf)/D;
        s0 = -Vf*Z2/D;
end
end

function t = relTerm(In, Is)
if abs(In) < 1e-12 && abs(Is) < 1e-12
    t = 0;
else
    t = abs(In - Is)/abs(In);
end
end

function B = addB(B, name, from, to, I1, I2, I0)
%ADDB  Append one OUTPUT-ONLY branch-table row (Task 10).
B(end+1) = struct('name', name, 'from', from, 'to', to, ...
    'I1', I1, 'I2', I2, 'I0', I0);
end
