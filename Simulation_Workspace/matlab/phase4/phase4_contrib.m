function C = phase4_contrib(caseID, ds, XoR_P, loc, type, stageReq, t_break, ZfMode)
%PHASE4_CONTRIB  M5 contribution extraction: per-leg phasors + KCL + tags.
%
%   C = PHASE4_CONTRIB(caseID, ds, XoR_P, loc, type, stageReq, t_break,
%   ZfMode) solves the fault with PHASE4_SOLVE (default opts) and splits
%   the fault current into toward-fault legs. First 8 inputs mirror
%   PHASE4_STAGES (ZfMode 'bolted'/'earth'/'phase' with the same
%   level-base rule: F1/F2 4.84 ohm, F3/F4/F5 529 ohm; earth = 0.01 pu x
%   base, phase = 0.002 pu x base, bolted = 0). stageReq 'Ikpp'/'Ib'/
%   'Isteady' maps to the same solver stage; 'Ib' requires t_break
%   (finite scalar >= 0, input only, never defaulted); t_break is ignored
%   for every other stage.
%
%   'ip' has NO per-leg table (derived magnitude only): stageReq = 'ip'
%   always errors error('phase4_contrib:ipNoTable').
%
%   Branch currents per sequence come from the solver's retained bus
%   voltages times the solver's own branch admittances (F.branch: same
%   impedances as the Ybus build, never redefined here). Every leg is
%   re-signed TOWARD THE FAULT, then phase-reconstructed per leg with
%   Fortescue (17-16): Ia = I0+I1+I2, Ib = I0+a^2*I1+a*I2,
%   Ic = I0+a*I1+a^2*I2, a = exp(j*2*pi/3).
%
%   LEG MAP (stored branch rows are from->to; s = toward-fault sign):
%     GEN      machine internal (-1) -> B22, s = +1 all locs
%              (machine->network feeds the fault from behind the stage
%              source; I0 = generator-chain 1->8 current referenced 8->1,
%              i.e. minus the stored 1->8 row).
%     GSUT_LV  series LV end 1->2, s = -1 at F1/F2 (fault at B22: toward
%              is 2->1), +1 at F3/F4/F5; I0 = 0 (LV delta blocks zero).
%     GSUT_HV  series HV end 2->1, s = -sLV (opposite end of the same
%              branch; tap makes the ends differ, both kept honestly);
%              I0 = HV-neutral ground-leg current with the same s
%              (LV delta blocks series zero; solid-neutral position per
%              phase4_seqZ). Away-pointing load components keep their
%              negative real part -- CORRECT, never rectified.
%     UAT      aux branch 1->6, s = -1 all locs (fault never at B6_6;
%              passive draw, signed toward fault, normally negative --
%              never a source, no motor infeed); I0 = 0 (HV delta blocks).
%     GAT_HV   HV-tee -> 6 series end, s = -1 all locs, iff GAT IN
%              (OUT: fields ABSENT, never zero-filled); I0 = GAT zero
%              series end with the same s.
%     GAT_LV   6 -> HV-tee series end, s = +1 all locs, iff GAT IN
%              (coincides with GAT_HV: series branch, no tap; both kept,
%              sum uses the HV end only).
%     LINE_total (non-F4) line 2->4, s = +1 at F5, -1 at F1/F2/F3;
%              I0 = line zero series current with the same s.
%     F4: LINE_B1 = faulted-circuit GIS-side section toward fault
%              (2->7, +stored; degenerate m = 0/1: faulted direct 2->4
%              signed toward the fault node), LINE_B2 = faulted-circuit
%              remote-side section toward fault (-stored 7->4; degenerate:
%              healthy direct signed likewise), LINE_total = B1+B2.
%     GRID     equivalent internal (5) -> remote (4), s = +1 all locs
%              (equivalent->fault); all three sequences folded in.
%     NER_earth neutral (8) -> earth, LG/LLG ONLY (absent otherwise);
%              I1 = I2 = 0, I0 = stored neutral current: part of the I0
%              return, never a separate parallel fault current (at F1 it
%              equals GEN.I0 by series construction; at 230-kV faults it
%              is ~0 by delta block).
%
%   KCL SUMS (20-1/20-2/20-3) run over the feeding-leg set per location
%   (the incident toward-fault currents; through-legs are reported but
%   excluded, otherwise series elements would double-count):
%     F1/F2: seq1/2 {GEN, GSUT_LV, UAT}, seq0 {GEN} (NER excluded: same
%              series current as GEN zero).
%     F3:    {GSUT_HV, LINE_total} + GAT_HV iff IN, all sequences.
%     F4:    {LINE_B1, LINE_B2}, all sequences (degenerate m = 0 -> F3
%              sets, m = 1 -> F5 sets).
%     F5:    {LINE_total, GRID}, all sequences.
%   kcl_seq = worst per-sequence |sum - fault| over fault-magnitude
%   scale; kcl_ph = worst per-phase ditto (feeding seq1/2 set, zero
%   included via Fortescue); kcl_earth = |3*sum0 - 3*I0|/|3*I0| for
%   LG/LLG, NaN with comment for LL/LLL (zero network DEAD).
%   diag carries (20-4) symmetry identities (NaN where not applicable).
%
%   tags maps through-current labels to leg phasors (labels only -- no
%   duties, no switching/arc model, no IEC 60909 compliance claim):
%   GEN_Q/GSUT_HV/GSUT_LV/LINE_Q9[/LINE_B1/LINE_B2]/GRID_Q/GAT_HV(iff IN).
%   LINE_Q9 uses the GIS->remote through convention (positive GIS->remote;
%   KCL legs use toward-fault values instead). F4 LINE_Q9 = GIS outfeed
%   (faulted GIS-side + healthy). Q0 is a breaker connection; Q1/Q2/Q9
%   are disconnector connections.
%
%   b66_split: B6_6 auxiliary split from positive-sequence node-6-end
%   currents (UAT 1->6 plus GAT HV->6 iff IN): UAT_share/GAT_share plus
%   ratio = IUAT_6/IGAT_6 (complex, no pre-judged dominant labels --
%   dominance is determined numerically downstream). GAT OUT: UAT-only
%   (UAT_share = 1, GAT_share = NaN, ratio = NaN).
%
%   Output fields (exact names): legs (each leg I1/I2/I0/Ia/Ib/Ic complex
%   TOWARD fault), kcl_seq, kcl_ph, kcl_earth, tags, b66_split
%   (UAT_share/GAT_share/ratio); plus diag ((20-4) fields) and meta
%   (request echo + feeding sets + Zf_ohm).

if isstring(caseID), caseID = char(caseID); end
if isstring(ds), ds = char(ds); end
if isstring(loc), loc = char(loc); end
if isstring(type), type = char(type); end
if isstring(stageReq), stageReq = char(stageReq); end
if isstring(ZfMode), ZfMode = char(ZfMode); end

if ~(ischar(stageReq) && isrow(stageReq) && any(strcmp(stageReq, {'Ikpp','ip','Ib','Isteady'})))
    error('phase4_contrib:badStage', 'Unknown stageReq: use ''Ikpp''/''ip''/''Ib''/''Isteady''.');
end
if strcmp(stageReq, 'ip')
    error('phase4_contrib:ipNoTable', ['Per-leg ip is forbidden: ip is a derived magnitude ' ...
        '(kappa*sqrt(2)*governing) with no contribution table; request an RMS stage instead.']);
end
if ~(ischar(ZfMode) && isrow(ZfMode) && any(strcmp(ZfMode, {'bolted','earth','phase'})))
    error('phase4_contrib:badZfMode', 'Unknown ZfMode ''%s'': use ''bolted''/''earth''/''phase''.', ZfMode);
end
if ~any(strcmp(loc, {'F1','F2','F3','F4','F5'}))
    error('phase4_contrib:badLoc', 'Unknown fault location ''%s'': use F1/F2/F3/F4/F5.', loc);
end
if ~any(strcmp(type, {'LLL','LG','LL','LLG'}))
    error('phase4_contrib:badType', 'Unknown fault type ''%s'': use LLL/LG/LL/LLG.', type);
end
if strcmp(stageReq, 'Ib')
    if nargin < 7 || isempty(t_break) || ~(isnumeric(t_break) && isscalar(t_break) && isfinite(t_break) && t_break >= 0)
        error('phase4_contrib:missingTbreak', 'Ib requires a finite scalar t_break >= 0 (input only, never defaulted).');
    end
end

if any(strcmp(loc, {'F1','F2'}))
    Zbase_level = 4.84;
else
    Zbase_level = 529;
end
switch ZfMode
    case 'bolted'
        Zf_ohm = 0;
    case 'earth'
        Zf_ohm = 0.01*Zbase_level;
    case 'phase'
        Zf_ohm = 0.002*Zbase_level;
end

F = phase4_solve(caseID, ds, XoR_P, loc, type, stageReq, Zf_ohm);
B = F.branch;
isLLL = strcmp(type, 'LLL');
isLG = strcmp(type, 'LG');
isLL = strcmp(type, 'LL');
isLLG = strcmp(type, 'LLG');

% ---- toward-fault signs per leg map ----
if any(strcmp(loc, {'F1','F2'})), sLV = -1; else, sLV = +1; end
sHV = -sLV;
if strcmp(loc, 'F5'), sL = +1; else, sL = -1; end

legs = struct();
g = getB(B, 'GEN'); gen0 = getB(B, 'GEN0');
legs.GEN = mkLeg(+g.I1, +g.I2, -gen0.I0);
gl = getB(B, 'GSUT_LV'); gh = getB(B, 'GSUT_HV'); gs0 = getB(B, 'GSUT0');
legs.GSUT_LV = mkLeg(sLV*gl.I1, sLV*gl.I2, 0);
legs.GSUT_HV = mkLeg(sHV*gh.I1, sHV*gh.I2, sHV*gs0.I0);
u = getB(B, 'UAT');
legs.UAT = mkLeg(-u.I1, -u.I2, 0);
if F.GAT_in
    ghv = getB(B, 'GAT_HV'); glv = getB(B, 'GAT_LV'); gz0 = getB(B, 'GAT0');
    legs.GAT_HV = mkLeg(-ghv.I1, -ghv.I2, -gz0.I0);
    legs.GAT_LV = mkLeg(+glv.I1, +glv.I2, -gz0.I0);
end
grd = getB(B, 'GRID');
legs.GRID = mkLeg(+grd.I1, +grd.I2, +grd.I0);
if F.isF4
    if hasRow(B, 'LINE_S')  % interior m: faulted sections + healthy
        sRow = getB(B, 'LINE_S'); rRow = getB(B, 'LINE_R');
        legs.LINE_B1 = mkLeg(+sRow.I1, +sRow.I2, +sRow.I0);
        legs.LINE_B2 = mkLeg(-rRow.I1, -rRow.I2, -rRow.I0);
        legs.LINE_total = mkLeg(legs.LINE_B1.I1 + legs.LINE_B2.I1, ...
            legs.LINE_B1.I2 + legs.LINE_B2.I2, legs.LINE_B1.I0 + legs.LINE_B2.I0);
    else  % degenerate m = 0/1: faulted + healthy directs toward fault node
        fRow = getB(B, 'LINE_F'); hRow = getB(B, 'LINE_H');
        if F.mF4 <= 0, sD = -1; else, sD = +1; end
        legs.LINE_B1 = mkLeg(sD*fRow.I1, sD*fRow.I2, sD*fRow.I0);
        legs.LINE_B2 = mkLeg(sD*hRow.I1, sD*hRow.I2, sD*hRow.I0);
        legs.LINE_total = mkLeg(legs.LINE_B1.I1 + legs.LINE_B2.I1, ...
            legs.LINE_B1.I2 + legs.LINE_B2.I2, legs.LINE_B1.I0 + legs.LINE_B2.I0);
    end
else
    ln = getB(B, 'LINE');
    legs.LINE_total = mkLeg(sL*ln.I1, sL*ln.I2, sL*ln.I0);
end
if isLG || isLLG
    ner = getB(B, 'NER');
    legs.NER_earth = mkLeg(0, 0, +ner.I0);
end

% ---- feeding sets (documented above; through-legs excluded) ----
switch loc
    case {'F1','F2'}
        feed12 = {'GEN','GSUT_LV','UAT'};
        feed0 = {'GEN'};
    case 'F3'
        feed12 = {'GSUT_HV','LINE_total'};
        if F.GAT_in, feed12{end+1} = 'GAT_HV'; end
        feed0 = feed12;
    case 'F4'
        if F.isF4 && ~hasRow(B, 'LINE_S') && F.mF4 <= 0
            feed12 = {'GSUT_HV','LINE_total'};
            if F.GAT_in, feed12{end+1} = 'GAT_HV'; end
        elseif F.isF4 && ~hasRow(B, 'LINE_S') && F.mF4 >= 1
            feed12 = {'LINE_total','GRID'};
        else
            feed12 = {'LINE_B1','LINE_B2'};
        end
        feed0 = feed12;
    case 'F5'
        feed12 = {'LINE_total','GRID'};
        feed0 = feed12;
end

% ---- KCL residuals (20-1/20-2/20-3) ----
D = max([abs(F.I1), abs(F.I2), abs(F.I0), 1e-30]);
s1 = sumLeg(legs, feed12, 'I1'); s2 = sumLeg(legs, feed12, 'I2'); s0 = sumLeg(legs, feed0, 'I0');
kcl_seq = max([abs(s1 - F.I1)/D, abs(s2 - F.I2)/D, abs(s0 - F.I0)/D]);
Dp = max([abs(F.Ia), abs(F.Ib), abs(F.Ic), 1e-30]);
pa = sumLeg(legs, feed12, 'Ia'); pb = sumLeg(legs, feed12, 'Ib'); pc = sumLeg(legs, feed12, 'Ic');
kcl_ph = max([abs(pa - F.Ia)/Dp, abs(pb - F.Ib)/Dp, abs(pc - F.Ic)/Dp]);
if isLL || isLLL
    kcl_earth = NaN;  % zero network DEAD for LL/LLL: no earth return to assert
else
    kcl_earth = abs(3*s0 - 3*F.I0)/max(abs(3*F.I0), 1e-30);
end

% ---- (20-4) symmetry diagnostics (NaN where not applicable) ----
diag = struct();
if isLLL
    diag.LLL_sym = max([abs(abs(F.Ia) - abs(F.I1)), abs(abs(F.Ib) - abs(F.I1)), abs(abs(F.Ic) - abs(F.I1))])/max(abs(F.I1), 1e-30);
else
    diag.LLL_sym = NaN;
end
if isLL
    diag.LL_opp = abs(F.Ib + F.Ic)/max([abs(F.Ib), abs(F.Ic), 1e-30]);
else
    diag.LL_opp = NaN;
end
if isLG
    diag.LG_branch0 = max(abs(F.Ib), abs(F.Ic))/max(abs(F.Ia), 1e-30);
else
    diag.LG_branch0 = NaN;
end
if isLLG
    Ie = F.Ia + F.Ib + F.Ic;
    diag.LLG_earth = abs(Ie - 3*F.I0)/max(abs(Ie), 1e-30);
else
    diag.LLG_earth = NaN;
end

% ---- through-current tags (labels only; LINE_Q9 GIS->remote positive) ----
tags = struct();
tags.GEN_Q = legs.GEN;
tags.GSUT_HV = legs.GSUT_HV;
tags.GSUT_LV = legs.GSUT_LV;
if F.isF4
    tags.LINE_B1 = legs.LINE_B1;
    tags.LINE_B2 = legs.LINE_B2;
    if hasRow(B, 'LINE_S')
        hRow = getB(B, 'LINE_H'); sRow = getB(B, 'LINE_S');
        tags.LINE_Q9 = mkLeg(sRow.I1 + hRow.I1, sRow.I2 + hRow.I2, sRow.I0 + hRow.I0);
    else
        fRow = getB(B, 'LINE_F'); hRow = getB(B, 'LINE_H');
        tags.LINE_Q9 = mkLeg(fRow.I1 + hRow.I1, fRow.I2 + hRow.I2, fRow.I0 + hRow.I0);
    end
else
    ln = getB(B, 'LINE');
    tags.LINE_Q9 = mkLeg(+ln.I1, +ln.I2, +ln.I0);
end
tags.GRID_Q = legs.GRID;
if F.GAT_in
    tags.GAT_HV = legs.GAT_HV;
end

% ---- B6_6 split (positive-sequence node-6 ends; shares + ratio) ----
Iu6 = +u.I1;
if F.GAT_in
    Ig6 = getB(B, 'GAT_HV');
    Ig6 = +Ig6.I1;
    tot = Iu6 + Ig6;
    if abs(tot) < 1e-30
        UAT_share = NaN; GAT_share = NaN;
    else
        UAT_share = Iu6/tot; GAT_share = Ig6/tot;
    end
    if abs(Ig6) < 1e-30
        ratio = NaN;
    else
        ratio = Iu6/Ig6;
    end
else
    UAT_share = 1; GAT_share = NaN; ratio = NaN;  % UAT-only, noted
end
b66_split = struct('UAT_share', UAT_share, 'GAT_share', GAT_share, 'ratio', ratio);

if nargin < 7
    tbEcho = NaN;
elseif isempty(t_break)
    tbEcho = NaN;
else
    tbEcho = t_break;
end
meta = struct('caseID', caseID, 'ds', ds, 'XoR_P', XoR_P, 'loc', loc, ...
    'type', type, 'stageReq', stageReq, 't_break', tbEcho, ...
    'ZfMode', ZfMode, 'Zf_ohm', Zf_ohm);
meta.feeders12 = feed12;
meta.feeders0 = feed0;

C = struct('legs', legs, 'kcl_seq', kcl_seq, 'kcl_ph', kcl_ph, ...
    'kcl_earth', kcl_earth, 'tags', tags, 'b66_split', b66_split, ...
    'diag', diag, 'meta', meta);
end

% =====================================================================
function r = getB(B, name)
for k = 1:numel(B)
    if strcmp(B(k).name, name)
        r = B(k);
        return;
    end
end
error('phase4_contrib:missingBranch', 'Branch row ''%s'' missing from solver output.', name);
end

function ok = hasRow(B, name)
ok = false;
for k = 1:numel(B)
    if strcmp(B(k).name, name)
        ok = true;
        return;
    end
end
end

function L = mkLeg(I1, I2, I0)
%MKLEG  Per-leg Fortescue (17-16) reconstruction (complex, toward fault).
a = exp(1j*2*pi/3);
L = struct('I1', I1, 'I2', I2, 'I0', I0, 'Ia', I0 + I1 + I2, ...
    'Ib', I0 + a^2*I1 + a*I2, 'Ic', I0 + a*I1 + a^2*I2);
end

function s = sumLeg(legs, names, field)
s = 0;
for k = 1:numel(names)
    s = s + legs.(names{k}).(field);
end
end
