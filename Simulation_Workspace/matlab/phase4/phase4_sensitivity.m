function S = phase4_sensitivity(baseID, legCell)
%PHASE4_SENSITIVITY  Sensitivity runner M7 OFAT + analytic bounds.
%
%   S = PHASE4_SENSITIVITY('base_LF360_OUT_P15', legCell) runs one-factor-
%   at-a-time sensitivity legs from the H1-base run. Each leg equals base
%   with ONLY the named change (E5H3joint excepted: F3 LG IN with UAT +
%   GAT LV scales jointly; the IN scope is documented and honest because
%   B6_6-direct faults are out of solver scope and the same UAT/GAT LV
%   neutral branches participate through the GAT HV-LV path when IN).
%
%   H1-base run descriptor:
%     caseID LF360_GAT_OUT, ds P, XoR_P 15, k0g 1.5, kR 3.5, kX 2.75,
%     kB 0.725, XdRole sat, gatLeg H1, lambda_T 1.0, gatZ0sel nominal,
%     ner primary, lineScale 1.0, ZfMode bolted, coupler closed.
%
%   Nodal OFAT legs (full nodal solves via phase4_solve; never Thevenin-only):
%     A-XoR10 (XoR_P 15->10), A-XoR20 (15->20), A-S (ds P->S profile),
%     A-k0g1.0 (k0g->1.0), A-k0g2.0 (k0g->2.0; k0g legs run F3 LG + F3 LLG
%     plus F3 LLL for LG/LLG weighting), B-0.5 (lineScale 0.71428571),
%     B-1.0 (lineScale 1.42857143) at MID ratios, C-LOW (2.0,2.0,0.60),
%     C-HIGH (5.0,3.5,0.85) engineering envelope (never proof),
%     C-X1 cross (5.0,2.0,0.725, conditional-demo), D1 (XdRole unsat),
%     E2 (ner quoted60), F-earth/F-phase (ZfMode), G-open (coupler open),
%     H0/H2 (gatLeg; H2 is a limiting sensitivity / stress case, never a
%     bracket proof), LAM05 (lambda_T 0.5), LAM20 (lambda_T 2.0),
%     GZ0low/GZ0high and aliases GAT-Z0-9.99/GAT-Z0-11.61 (gatZ0sel low/high;
%     SOURCE status kept, never relabelled), E5a (ZN_UAT_scale 1/3),
%     H3a (ZN_GATLV_scale 2.0), H3b (0.5), H3HV (ZN_GATHV_ohm 1.0),
%     E5H3joint (F3 LG IN: ZN_UAT_scale 1/3 + ZN_GATLV_scale 2.0 jointly).
%   H1-base/H0/H2/LAM/GZ0/E5/H3/E5H3joint wording only.
%
%   Analytic legs (local documented functions below, labelled; never
%   presented as nodal runs):
%     E1 (R_loading +-5% ENGINEERING_ASSUMPTION band to 3ZN band, F1 LG
%       EXACT re-evaluation), E3 (NGT bound resistive-assumed
%       ENGINEERING_ASSUMPTION, same F1-exact evaluator, EXACT),
%     D4 (X0x0.9/X0x1.1 bounded-tolerance reading + X0:=0.2248 error-check,
%       same F1-exact evaluator, EXACT; joint D4+E combined evaluator at
%       F1 LG, EXACT), D2/D3/D5 (INPUT-spread bounds, APPROXIMATION with
%       inheritance statement for generator-dominated F1/F2 faults).
%   F1-exact evaluator: Ifault = 3Vf/(Zth1+Zth2+Z0adj) with Zth from base
%   nodal audit outputs and Z0adj = Zth0_base - 3ZN_base + 3ZN_new (E1) or
%   analogous Z0gen/NGT substitution. Exactness holds because the F1 zero
%   path is the series-only generator chain by delta-block topology
%   (GSUT LV delta blocks the grid/line side; UAT HV delta leaves the LV
%   branch isolated; only gen Z0gen + 3ZN remain in series).
%
%   ZTH0-HAND: hand parallel-formula check Zth0(F3,OUT,P15,MID) =
%   Z0gsut || (Z0line + Z0grid) recomputed INDEPENDENTLY from registry
%   values (never solver internals) vs solver Zth0; returns relerr.
%   UAT LV dead branch + GSUT-LV/gen chains correctly excluded by delta
%   topology: UAT HV delta is open in zero so node 6 floats OUT with no
%   path to the F3 HV node; GSUT LV delta blocks the generator chain and
%   GSUT LV series zero from the HV node; only the GSUT HV leg to ground
%   parallels the line-plus-grid series path to the grounded far end.
%
%   Output: S.runs struct array with per-run legID, variedValues,
%   currents, kcl residuals plus echo fields (kR/kX/kB/lineScale/gatLeg/
%   gatZ0sel/gatZ0status/relerr/label); S.minmax for LG/LLG Ik with
%   supplying-leg names; point LG/LLG without band flagged incomplete in
%   S.incomplete. 'FULL_FACTORIAL' in legCell errors
%   error('phase4_sensitivity:factorial'). Only 'base_LF360_OUT_P15'
%   supported (else 'phase4'-prefixed error). No IEC 60909 compliance claim.
%
%   GAT-Z0 tolerance keeps SOURCE status (never ENGINEERING_ASSUMPTION).
%   H2 is a limiting sensitivity / stress case. HIGH corner is an
%   engineering envelope.

if nargin < 2
    error('phase4_sensitivity:args', 'baseID and legCell required.');
end
if isstring(baseID), baseID = char(baseID); end
if ~(ischar(baseID) && isrow(baseID) && strcmp(baseID, 'base_LF360_OUT_P15'))
    error('phase4_sensitivity:badBase', 'Only base ''base_LF360_OUT_P15'' supported.');
end
if isstring(legCell), legCell = cellstr(legCell); end
if ischar(legCell), legCell = {legCell}; end
if ~iscell(legCell) || isempty(legCell)
    error('phase4_sensitivity:badLegs', 'legCell must be a non-empty cell array of leg IDs.');
end
legs = cell(1, numel(legCell));
for i = 1:numel(legCell)
    li = legCell{i};
    if isstring(li), li = char(li); end
    if ~(ischar(li) && isrow(li))
        error('phase4_sensitivity:badLeg', 'Leg ID must be a string scalar.');
    end
    legs{i} = li;
    if strcmp(li, 'FULL_FACTORIAL')
        error('phase4_sensitivity:factorial', 'Full-factorial combinations are forbidden; OFAT legs only.');
    end
end

% ---- H1-base descriptor (binding) ----
base = struct('caseID','LF360_GAT_OUT','ds','P','XoR_P',15,'k0g',1.5, ...
    'kR',3.5,'kX',2.75,'kB',0.725,'XdRole','sat','gatLeg','H1', ...
    'lambda_T',1.0,'gatZ0sel','nominal','ner','primary', ...
    'lineScale',1.0,'ZfMode','bolted','coupler','closed');

nr = numel(legs);
runs = repmat(emptyRun(), 1, nr);
for i = 1:nr
    runs(i) = runLeg(base, legs{i});
end

% ---- min/max collector over nodal LG/LLG OFAT runs ----
minmax = collectMinmax(runs);
% point LG/LLG without band flagged incomplete
if nr <= 1
    incomplete = true;
    incompleteNote = 'point LG/LLG without band: single-leg call, no spread band';
else
    hasNodal = false;
    for i = 1:nr
        if strcmp(runs(i).label, 'NODAL'), hasNodal = true; end
    end
    if hasNodal
        incomplete = false;
        incompleteNote = 'band from nodal OFAT LG/LLG spread';
    else
        incomplete = true;
        incompleteNote = 'point LG/LLG without band: no nodal legs in call';
    end
end

S = struct('baseID', baseID, 'runs', runs, 'minmax', minmax, ...
    'incomplete', incomplete, 'incompleteNote', incompleteNote, 'base', base);
fprintf('phase4_sensitivity %s: %d legs OFAT (min LG %.6f max LG %.6f)\n', ...
    baseID, nr, minmax.LG_min, minmax.LG_max);
end

% =====================================================================
function r = emptyRun()
r = struct('legID','', 'variedValues', struct(), ...
    'currents', struct('LG_Ia', NaN, 'LG_I1', NaN, 'LG_I0', NaN, ...
        'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN), ...
    'kcl', NaN, 'kR', NaN, 'kX', NaN, 'kB', NaN, ...
    'lineScale', NaN, 'gatLeg', '', 'gatZ0sel', '', ...
    'gatZ0status', '', 'relerr', NaN, 'label', '', ...
    'IkLG', NaN, 'IkLLG', NaN, 'caseID', '', 'ds', '', 'XoR_P', NaN);
end

function r = runLeg(base, legID)
%RUNLEG  One OFAT leg: base with ONLY the named change (joint excepted).
d = base;
ovr = struct('Rloading_tolfrac', 0, 'ZN_UAT_scale', 1, ...
    'ZN_GATLV_scale', 1, 'ZN_GATHV_ohm', 0);
vv = struct('baseID','base_LF360_OUT_P15');
kind = 'NODAL';
label = 'NODAL';
needLLL = false;

switch legID
    case 'A-XoR10', d.XoR_P = 10; vv = struct('XoR_P',10);
    case 'A-XoR20', d.XoR_P = 20; vv = struct('XoR_P',20);
    case 'A-S', d.ds = 'S'; vv = struct('ds','S');
    case 'A-k0g1.0', d.k0g = 1.0; vv = struct('k0g',1.0); needLLL = true;
    case 'A-k0g2.0', d.k0g = 2.0; vv = struct('k0g',2.0); needLLL = true;
    case 'B-0.5', d.lineScale = 0.71428571; vv = struct('lineScale',0.71428571);
    case 'B-1.0', d.lineScale = 1.42857143; vv = struct('lineScale',1.42857143);
    case 'C-LOW', d.kR = 2.0; d.kX = 2.0; d.kB = 0.60; vv = struct('kR',2.0,'kX',2.0,'kB',0.60);
    case 'C-HIGH', d.kR = 5.0; d.kX = 3.5; d.kB = 0.85; vv = struct('kR',5.0,'kX',3.5,'kB',0.85);
    case 'C-X1', d.kR = 5.0; d.kX = 2.0; d.kB = 0.725; vv = struct('kR',5.0,'kX',2.0,'kB',0.725,'note','conditional-demo');
    case 'D1', d.XdRole = 'unsat'; vv = struct('XdRole','unsat');
    case 'E2', d.ner = 'quoted60'; vv = struct('ner','quoted60');
    case 'F-earth', d.ZfMode = 'earth'; vv = struct('ZfMode','earth');
    case 'F-phase', d.ZfMode = 'phase'; vv = struct('ZfMode','phase');
    case {'G-open','G-OPEN'}, d.coupler = 'open'; vv = struct('coupler','open');
    case 'H0', d.gatLeg = 'H0'; vv = struct('gatLeg','H0');
    case 'H2', d.gatLeg = 'H2'; vv = struct('gatLeg','H2');
    case {'LAM05','LAM05_'}, d.lambda_T = 0.5; vv = struct('lambda_T',0.5);
    case {'LAM20','LAM20_'}, d.lambda_T = 2.0; vv = struct('lambda_T',2.0);
    case {'LAM05b'}, d.lambda_T = 0.5; vv = struct('lambda_T',0.5);
    case {'GZ0low','GAT-Z0-9.99'}, d.gatZ0sel = 'low'; vv = struct('gatZ0sel','low');
    case {'GZ0high','GAT-Z0-11.61'}, d.gatZ0sel = 'high'; vv = struct('gatZ0sel','high');
    case 'E5a', ovr.ZN_UAT_scale = 1/3; vv = struct('ZN_UAT_scale',1/3);
    case 'H3a', ovr.ZN_GATLV_scale = 2.0; vv = struct('ZN_GATLV_scale',2.0);
    case 'H3b', ovr.ZN_GATLV_scale = 0.5; vv = struct('ZN_GATLV_scale',0.5);
    case 'H3HV', ovr.ZN_GATHV_ohm = 1.0; vv = struct('ZN_GATHV_ohm',1.0);
    case 'E5H3joint'
        d.caseID = 'LF360_GAT_IN';
        ovr.ZN_UAT_scale = 1/3; ovr.ZN_GATLV_scale = 2.0;
        vv = struct('caseID','LF360_GAT_IN','ZN_UAT_scale',1/3,'ZN_GATLV_scale',2.0,'note','F3 LG IN joint');
    case 'ZTH0-HAND'
        r = handLeg(base, legID);
        return;
    case {'E1','E3','D4','D4E','D4+E','D4+E-JOINT','D2','D3','D5'}
        r = analyticLeg(base, legID);
        return;
    case {'E1-LOW','E1-HIGH','E3-LOW','E3-HIGH','D4-LOW','D4-HIGH','D4-ERR', ...
            'D3-LOW','D3-HIGH','D3-ERR'}
        r = analyticLeg(base, legID);
        return;
    otherwise
        error('phase4_sensitivity:badLeg', 'Unknown leg ID ''%s''.', legID);
end

% ---- nodal solves at F3 (OUT unless joint IN), Ikpp ----
ZfLG = zfFor(d.ZfMode, 'F3');
ZfLLG = ZfLG;
opts = struct('m',0.5,'gatLeg',d.gatLeg,'coupler',d.coupler, ...
    'kR',d.kR,'kX',d.kX,'kB',d.kB,'k0g',d.k0g,'ner',d.ner, ...
    'XdRole',d.XdRole,'lambda_T',d.lambda_T, ...
    'lineScale',d.lineScale,'gatZ0sel',d.gatZ0sel,'ovr',ovr);
FLG = phase4_solve(d.caseID, d.ds, d.XoR_P, 'F3', 'LG', 'Ikpp', ZfLG, opts);
FLLG = phase4_solve(d.caseID, d.ds, d.XoR_P, 'F3', 'LLG', 'Ikpp', ZfLLG, opts);
kclLG = kclF3(FLG);
kclLLG = kclF3(FLLG);
kcl = max([kclLG, kclLLG, FLG.audit_res, FLLG.audit_res]);
IkLG = abs(FLG.Ia);
IgovLLG = max(abs(FLLG.Ib), abs(FLLG.Ic));
IkLLG = IgovLLG;
cur = struct('LG_Ia', FLG.Ia, 'LG_I1', FLG.I1, 'LG_I0', FLG.I0, ...
    'LLG_Igov', IgovLLG, 'LLG_I1', FLLG.I1, 'LLG_I0', FLLG.I0, 'LLL_I1', NaN);
if needLLL
    ZfLLL = zfFor('bolted','F3');
    FLLL = phase4_solve(d.caseID, d.ds, d.XoR_P, 'F3', 'LLL', 'Ikpp', ZfLLL, opts);
    cur.LLL_I1 = FLLL.I1;
    kcl = max([kcl, kclF3ll(FLLL)]);
end

r = emptyRun();
r.legID = legID;
r.variedValues = vv;
r.currents = cur;
r.kcl = kcl;
r.kR = d.kR; r.kX = d.kX; r.kB = d.kB;
r.lineScale = d.lineScale;
r.gatLeg = d.gatLeg;
r.gatZ0sel = d.gatZ0sel;
r.gatZ0status = 'SOURCE';
r.relerr = NaN;
r.label = label;
r.IkLG = IkLG; r.IkLLG = IkLLG;
r.caseID = d.caseID; r.ds = d.ds; r.XoR_P = d.XoR_P;
end

function z = zfFor(zfmode, loc)
if any(strcmp(loc, {'F1','F2'})), zb = 4.84; else, zb = 529; end
switch zfmode
    case 'bolted', z = 0;
    case 'earth', z = 0.01*zb;
    case 'phase', z = 0.002*zb;
    otherwise, error('phase4_sensitivity:badZf', 'Unknown ZfMode.');
end
end

function k = kclF3(F)
%KCLF3  Feeding-leg KCL for F3 from solver branch rows (leg-specific).
%   Feeders: GSUT_HV + LINE (+ GAT_HV iff IN), all sequences, signed
%   TOWARD the fault (F3: s=-1 for both GIS-side legs, matching
%   phase4_contrib leg signs). Zero of GSUT_HV comes from the GSUT0
%   ground leg (LV delta blocks series zero); GAT zero from GAT0.
B = F.branch;
gh = getRow(B,'GSUT_HV'); gs0 = getRow(B,'GSUT0'); ln = getRow(B,'LINE');
s1 = -gh.I1 - ln.I1; s2 = -gh.I2 - ln.I2; s0 = -gs0.I0 - ln.I0;
if F.GAT_in
    ghv = getRow(B,'GAT_HV'); gz0 = getRow(B,'GAT0');
    s1 = s1 - ghv.I1; s2 = s2 - ghv.I2; s0 = s0 - gz0.I0;
end
D = max([abs(F.I1),abs(F.I2),abs(F.I0),1e-30]);
k = max([abs(s1-F.I1)/D, abs(s2-F.I2)/D, abs(s0-F.I0)/D]);
end

function k = kclF3ll(F)
B = F.branch;
gh = getRow(B,'GSUT_HV'); ln = getRow(B,'LINE');
s1 = -gh.I1 - ln.I1;
if F.GAT_in
    ghv = getRow(B,'GAT_HV');
    s1 = s1 - ghv.I1;
end
D = max(abs(F.I1),1e-30);
k = abs(s1-F.I1)/D;
end

function b = getRow(B, nm)
for q = 1:numel(B)
    if strcmp(B(q).name, nm), b = B(q); return; end
end
error('phase4_sensitivity:missingBranch', 'Branch row ''%s'' missing.', nm);
end

function r = handLeg(base, legID)
%HANDLEG  ZTH0-HAND independent parallel-formula check.
%   Zth0(F3,OUT,P15,MID) = Z0gsut || (Z0line + Z0grid) from registry
%   values only; solver Zth0 from the base nodal run.
R = phase4_registry();
Zbase = R.frozen.Zbase_ohm.value;
R_eq = R.frozen.R_eq_ohm.value;
X_eq = R.frozen.X_eq_ohm.value;
Z0g_pct = R.gsut.Z0_pct.value;
Rg_pct = R.gsut.R_pct.value;
X0g_pct = sqrt(Z0g_pct^2 - Rg_pct^2);
kG0 = 100/515;
Z0gsut = (Rg_pct/100)*kG0 + 1j*(X0g_pct/100)*kG0;
Z0line = 3.5*R_eq/Zbase + 1j*2.75*X_eq/Zbase;
Zmag = R.grid.P.Zmag_ohm.value;
Rg_ohm = Zmag/sqrt(15^2+1);
Xg_ohm = 15*Rg_ohm;
Z1grid = (Rg_ohm + 1j*Xg_ohm)/Zbase;
Z0grid = 1.5*Z1grid;
Zhand = (Z0gsut*(Z0line+Z0grid))/(Z0gsut+Z0line+Z0grid);
Fs = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0);
Zsol = Fs.Zth0;
relerr = abs(Zhand-Zsol)/max(abs(Zsol),1e-30);
r = emptyRun();
r.legID = legID;
r.variedValues = struct('formula','Z0gsut||(Z0line+Z0grid)','loc','F3','ds','P');
r.currents = struct('LG_Ia', Fs.Ia, 'LG_I1', Fs.I1, 'LG_I0', Fs.I0, ...
    'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
r.kcl = Fs.audit_res;
r.kR = base.kR; r.kX = base.kX; r.kB = base.kB;
r.lineScale = base.lineScale;
r.gatLeg = base.gatLeg;
r.gatZ0sel = base.gatZ0sel;
r.gatZ0status = 'SOURCE';
r.relerr = relerr;
r.label = 'HAND';
r.IkLG = abs(Fs.Ia); r.IkLLG = NaN;
r.caseID = 'LF360_GAT_OUT'; r.ds = 'P'; r.XoR_P = 15;
fprintf('phase4_sensitivity ZTH0-HAND: Zhand=%.6f%+.6fj Zsol=%.6f%+.6fj relerr=%.3g\n', ...
    real(Zhand), imag(Zhand), real(Zsol), imag(Zsol), relerr);
end

function r = analyticLeg(base, legID)
%ANALYTICLEG  Local analytic bounds (labelled; never nodal runs).
baseF1 = phase4_solve('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',0);
Zth1 = baseF1.Zth1; Zth2 = baseF1.Zth2; Zth0 = baseF1.Zth0; Vf = baseF1.Vf;
switch legID
    case 'E1'
        [iLo,iHi,vv] = e1Band(Zth1,Zth2,Zth0,Vf);
        cur = struct('LG_Ia', (iLo+iHi)/2, 'LG_I1', (iLo+iHi)/6, 'LG_I0', (iLo+iHi)/6, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, (abs(iHi-iLo)/max(abs((iLo+iHi)/2),1e-30)), 'EXACT');
    case {'E1-LOW','E1-HIGH'}
        [iLo,iHi,vv] = e1Band(Zth1,Zth2,Zth0,Vf);
        if strcmp(legID,'E1-LOW'), v = iLo; else, v = iHi; end
        cur = struct('LG_Ia', v, 'LG_I1', v/3, 'LG_I0', v/3, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, 0, 'EXACT');
    case 'E3'
        [iLo,iHi,vv] = e3Band(Zth1,Zth2,Zth0,Vf);
        cur = struct('LG_Ia', (iLo+iHi)/2, 'LG_I1', (iLo+iHi)/6, 'LG_I0', (iLo+iHi)/6, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, (abs(iHi-iLo)/max(abs((iLo+iHi)/2),1e-30)), 'EXACT');
    case {'E3-LOW','E3-HIGH'}
        [iLo,iHi,vv] = e3Band(Zth1,Zth2,Zth0,Vf);
        if ~isempty(strfind(legID,'LOW')), v = iLo; else, v = iHi; end
        cur = struct('LG_Ia', v, 'LG_I1', v/3, 'LG_I0', v/3, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, 0, 'EXACT');
    case 'D4'
        [iLo,iHi,iErr,vv] = d4Band(Zth1,Zth2,Zth0,Vf);
        cur = struct('LG_Ia', (iLo+iHi)/2, 'LG_I1', (iLo+iHi)/6, 'LG_I0', (iLo+iHi)/6, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, (abs(iHi-iLo)/max(abs((iLo+iHi)/2),1e-30)), 'EXACT');
    case {'D4-LOW','D4-HIGH','D4-ERR'}
        [iLo,iHi,iErr,vv] = d4Band(Zth1,Zth2,Zth0,Vf);
        if strcmp(legID,'D4-LOW'), v = iLo; elseif strcmp(legID,'D4-HIGH'), v = iHi; else, v = iErr; end
        cur = struct('LG_Ia', v, 'LG_I1', v/3, 'LG_I0', v/3, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, 0, 'EXACT');
    case {'D4E','D4+E','D4+E-JOINT'}
        [v,vv] = d4eJoint(Zth1,Zth2,Zth0,Vf);
        cur = struct('LG_Ia', v, 'LG_I1', v/3, 'LG_I0', v/3, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, 0, 'EXACT');
    case 'D2'
        [spE,spZ,vv] = d2Spread();
        cur = struct('LG_Ia', NaN, 'LG_I1', NaN, 'LG_I0', NaN, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, max(spE,spZ), 'APPROXIMATION');
    case 'D3'
        [sp,vv] = d3Spread();
        cur = struct('LG_Ia', NaN, 'LG_I1', NaN, 'LG_I0', NaN, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, sp, 'APPROXIMATION');
    case {'D3-LOW','D3-HIGH','D3-ERR'}
        [sp,vv] = d3Spread();
        cur = struct('LG_Ia', NaN, 'LG_I1', NaN, 'LG_I0', NaN, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, sp, 'APPROXIMATION');
    case 'D5'
        [rel,vv] = d5Spread();
        cur = struct('LG_Ia', NaN, 'LG_I1', NaN, 'LG_I0', NaN, ...
            'LLG_Igov', NaN, 'LLG_I1', NaN, 'LLG_I0', NaN, 'LLL_I1', NaN);
        r = mkAnalytic(legID, vv, cur, rel, 'APPROXIMATION');
    otherwise
        error('phase4_sensitivity:badLeg', 'Unknown analytic leg ''%s''.', legID);
end
r.kR = base.kR; r.kX = base.kX; r.kB = base.kB;
r.lineScale = base.lineScale;
r.gatLeg = base.gatLeg;
r.gatZ0sel = base.gatZ0sel;
r.gatZ0status = 'SOURCE';
r.caseID = base.caseID; r.ds = base.ds; r.XoR_P = base.XoR_P;
end

function r = mkAnalytic(legID, vv, cur, relerr, label)
r = emptyRun();
r.legID = legID;
r.variedValues = vv;
r.currents = cur;
r.kcl = NaN;
r.relerr = relerr;
r.label = label;
if isfield(cur,'LG_Ia') && ~isnan(abs(cur.LG_Ia)), r.IkLG = abs(cur.LG_Ia); end
end

function [iLo,iHi,vv] = e1Band(Zth1,Zth2,Zth0,Vf)
%E1BAND  R_loading +-5% ENGINEERING_ASSUMPTION band to 3ZN band, F1 LG EXACT.
Gb = phase4_grounding('primary');
Glo = phase4_grounding('primary', struct('Rloading_tolfrac',-0.05,'ZN_UAT_scale',1,'ZN_GATLV_scale',1,'ZN_GATHV_ohm',0));
Ghi = phase4_grounding('primary', struct('Rloading_tolfrac',0.05,'ZN_UAT_scale',1,'ZN_GATLV_scale',1,'ZN_GATHV_ohm',0));
Zb = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
Zlo = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary','ovr',struct('Rloading_tolfrac',-0.05,'ZN_UAT_scale',1,'ZN_GATLV_scale',1,'ZN_GATHV_ohm',0)));
Zhi = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary','ovr',struct('Rloading_tolfrac',0.05,'ZN_UAT_scale',1,'ZN_GATLV_scale',1,'ZN_GATHV_ohm',0)));
Z0lo = Zth0 - Zb.Z3ZN_pu + Zlo.Z3ZN_pu;
Z0hi = Zth0 - Zb.Z3ZN_pu + Zhi.Z3ZN_pu;
iLo = 3*Vf/(Zth1+Zth2+Z0lo);
iHi = 3*Vf/(Zth1+Zth2+Z0hi);
vv = struct('Rloading_tolfrac_low',-0.05,'Rloading_tolfrac_high',0.05, ...
    'Z3ZN_base_ohm',Gb.Z3ZN_ohm,'Z3ZN_low_ohm',Glo.Z3ZN_ohm,'Z3ZN_high_ohm',Ghi.Z3ZN_ohm, ...
    'Ifault_low',iLo,'Ifault_high',iHi,'label','EXACT');
end

function [iLo,iHi,vv] = e3Band(Zth1,Zth2,Zth0,Vf)
%E3BAND  NGT bound resistive-assumed ENGINEERING_ASSUMPTION, F1-exact, EXACT.
Zngt_ohm = 0.05*(((22000/sqrt(3))^2)/135000);
Zngt_study = Zngt_ohm*((230/22)^2)/529;
Z0lo = Zth0 - Zngt_study;
Z0hi = Zth0 + Zngt_study;
iLo = 3*Vf/(Zth1+Zth2+Z0lo);
iHi = 3*Vf/(Zth1+Zth2+Z0hi);
vv = struct('ZNGT_bound_ohm',Zngt_ohm,'ZNGT_study_pu',Zngt_study, ...
    'Ifault_low',iLo,'Ifault_high',iHi,'label','EXACT');
end

function [iLo,iHi,iErr,vv] = d4Band(Zth1,Zth2,Zth0,Vf)
%D4BAND  X0x0.9/X0x1.1 bounded-tolerance + X0:=0.2248 error-check, F1-exact, EXACT.
R = phase4_registry();
Ra_ohm = R.machine.Ra_ohm.value;
Snom_m = R.machine.Snom_MVA.value;
Vnom_m = R.machine.Vnom_kV.value;
kM = 100/Snom_m;
Ra_pu = (Ra_ohm/(Vnom_m^2/Snom_m))*kM;
X0b = R.machine.X0.value;
XdppS4 = R.machine.Xdpp_sat.value;
Zg_b = Ra_pu + 1j*(X0b*kM);
Zg_lo = Ra_pu + 1j*((X0b*0.9)*kM);
Zg_hi = Ra_pu + 1j*((X0b*1.1)*kM);
Zg_err = Ra_pu + 1j*(XdppS4*kM);
Z0lo = Zth0 - Zg_b + Zg_lo;
Z0hi = Zth0 - Zg_b + Zg_hi;
Z0err = Zth0 - Zg_b + Zg_err;
iLo = 3*Vf/(Zth1+Zth2+Z0lo);
iHi = 3*Vf/(Zth1+Zth2+Z0hi);
iErr = 3*Vf/(Zth1+Zth2+Z0err);
vv = struct('X0_base',X0b,'X0_low',X0b*0.9,'X0_high',X0b*1.1,'X0_err',XdppS4, ...
    'Ifault_low',iLo,'Ifault_high',iHi,'Ifault_err',iErr,'label','EXACT');
end

function [v,vv] = d4eJoint(Zth1,Zth2,Zth0,Vf)
%D4EJOINT  Combined D4+E evaluator at F1 LG, EXACT.
R = phase4_registry();
Ra_ohm = R.machine.Ra_ohm.value;
kM = 100/R.machine.Snom_MVA.value;
Vnom_m = R.machine.Vnom_kV.value;
Ra_pu = (Ra_ohm/(Vnom_m^2/R.machine.Snom_MVA.value))*kM;
X0b = R.machine.X0.value;
Zg_b = Ra_pu + 1j*(X0b*kM);
Zg_hi = Ra_pu + 1j*((X0b*1.1)*kM);
Zb = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
Zhi = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary','ovr',struct('Rloading_tolfrac',0.05,'ZN_UAT_scale',1,'ZN_GATLV_scale',1,'ZN_GATHV_ohm',0)));
Z0j = Zth0 - Zg_b - Zb.Z3ZN_pu + Zg_hi + Zhi.Z3ZN_pu;
v = 3*Vf/(Zth1+Zth2+Z0j);
vv = struct('X0_joint',X0b*1.1,'Rloading_joint',0.05,'Ifault_joint',v,'label','EXACT');
end

function [spE,spZ,vv] = d2Spread()
%D2SPREAD  Xqpp=0.2593 substitution INPUT-spread, APPROXIMATION.
%   Nodal propagation inherits at most the input spread for
%   generator-dominated F1/F2 faults (stated inheritance, not a nodal proof).
S = phase4_sources('LF360_GAT_OUT','sat');
R = phase4_registry();
Ra_ohm = R.machine.Ra_ohm.value;
kM = R.frozen.Sbase_MVA.value/R.machine.Snom_MVA.value;
Zbm = R.machine.Vnom_kV.value^2/R.machine.Snom_MVA.value;
Ra_pu = (Ra_ohm/Zbm)*kM;
Xdpp = R.machine.Xdpp_sat.value;
Xqpp = R.machine.Xqpp.value;
Zpp = Ra_pu + 1j*(Xdpp*kM);
Zpp2 = Ra_pu + 1j*(Xqpp*kM);
Epp = S.Vt_pu + Zpp*S.It_pu;
Epp2 = S.Vt_pu + Zpp2*S.It_pu;
spE = abs(Epp2-Epp)/max(abs(Epp),1e-30);
spZ = abs(Zpp2-Zpp)/max(abs(Zpp),1e-30);
vv = struct('Xqpp',Xqpp,'Xdpp',Xdpp,'dEpp_rel',spE,'dZpp_rel',spZ,'label','APPROXIMATION');
end

function [sp,vv] = d3Spread()
%D3SPREAD  X2 +-10% + X2:=Xdpp_sat error-check INPUT-spread, APPROXIMATION.
R = phase4_registry();
Ra_ohm = R.machine.Ra_ohm.value;
kM = R.frozen.Sbase_MVA.value/R.machine.Snom_MVA.value;
Zbm = R.machine.Vnom_kV.value^2/R.machine.Snom_MVA.value;
Ra_pu = (Ra_ohm/Zbm)*kM;
X2b = R.machine.X2.value;
Zb = Ra_pu + 1j*(X2b*kM);
Zlo = Ra_pu + 1j*((X2b*0.9)*kM);
Zhi = Ra_pu + 1j*((X2b*1.1)*kM);
XdppS = R.machine.Xdpp_sat.value;
Zerr = Ra_pu + 1j*(XdppS*kM);
sp = max([abs(Zlo-Zb),abs(Zhi-Zb),abs(Zerr-Zb)])/max(abs(Zb),1e-30);
vv = struct('X2_base',X2b,'X2_low',X2b*0.9,'X2_high',X2b*1.1,'X2_err',XdppS,'dZ2_rel',sp,'label','APPROXIMATION');
end

function [rel,vv] = d5Spread()
%D5SPREAD  Saliency error bound into Ib, APPROXIMATION.
S = phase4_sources('LF360_GAT_OUT','sat');
R5 = phase4_registry();
Etwo = sqrt(S.Edp^2 + S.Eqp^2);
ref = abs(S.Vt_pu + 1j*R5.machine.Xdp.value*S.It_pu);
rel = abs(Etwo-ref)/max(ref,1e-30);
vv = struct('Etwo',Etwo,'Efallback',ref,'rel',rel,'label','APPROXIMATION');
end

function mm = collectMinmax(runs)
%COLLECTMINMAX  Min/max over nodal LG/LLG OFAT Ik with supplying-leg names.
lgV = []; lgN = {}; llgV = []; llgN = {};
for i = 1:numel(runs)
    if strcmp(runs(i).label,'NODAL')
        if ~isnan(runs(i).IkLG)
            lgV(end+1) = runs(i).IkLG; lgN{end+1} = runs(i).legID;
        end
        if ~isnan(runs(i).IkLLG)
            llgV(end+1) = runs(i).IkLLG; llgN{end+1} = runs(i).legID;
        end
    end
end
if isempty(lgV), lgMin = NaN; lgMax = NaN; lgMinL = ''; lgMaxL = '';
else, [lgMin,k] = min(lgV); lgMinL = lgN{k}; [lgMax,k] = max(lgV); lgMaxL = lgN{k}; end
if isempty(llgV), llgMin = NaN; llgMax = NaN; llgMinL = ''; llgMaxL = '';
else, [llgMin,k] = min(llgV); llgMinL = llgN{k}; [llgMax,k] = max(llgV); llgMaxL = llgN{k}; end
mm = struct('LG_min',lgMin,'LG_max',lgMax,'LG_minLeg',lgMinL,'LG_maxLeg',lgMaxL, ...
    'LLG_min',llgMin,'LLG_max',llgMax,'LLG_minLeg',llgMinL,'LLG_maxLeg',llgMaxL);
end
