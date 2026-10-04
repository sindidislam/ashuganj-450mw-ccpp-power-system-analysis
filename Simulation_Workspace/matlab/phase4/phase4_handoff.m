function H = phase4_handoff(tag, FL)
%PHASE4_HANDOFF  Full-schema writer M8, Sec-26 schema CSVs, data only.
%
%   H = PHASE4_HANDOFF(tag) writes four CSVs under results/phase4_fault/<tag>/
%   via ashuganj_root; directory created if missing.
%
%   H = PHASE4_HANDOFF(tag, FL) uses caller FL anchors; single-arg smoke
%   derives FL from Phase-3 solved flows (see FL DERIVATION below).
%
%   Smoke content: F3 LLL+LG OUT P15 bolted Ikpp plus ip rows (one per fault
%   type) -- small but schema-complete.
%
%   Schema columns (exact headers, this order): fault_type,location,m,caseID,
%   grid_dataset,XoR_P,zero_band,k0g,XdRole,NER_variant,GAT_variant,ZfMode,
%   Zf_ohm,coupler,stage,unit,base,Irms_kA,Iang_deg,Iseq0_kA,Iseq1_kA,
%   Iseq2_kA,r_kappa_ip,t_break_s,footnote.
%
%   Currents in kA at fault voltage level (study-pu x Ibase_level:
%   Ibase = 100/(sqrt(3)*Vlevel_kV) kA; Vlevel from loc: F1/F2 22 kV,
%   F3/F4/F5 230 kV).
%
%   Contributions file adds per-leg columns leg_<TAG>_kA for the present leg
%   set plus kcl_seq,kcl_ph,kcl_earth residuals. CONSUMERS MUST USE THE
%   REPORTED FEEDER PARTITION (meta.feeders12/feeders0 via phase4_contrib);
%   NAIVE ALL-LEGS SUMS WILL NOT CLOSE (through-legs excluded to avoid
%   series double-count).
%
%   Bands file: min/max Ik per LG/LLG group with supplying-leg names plus MID
%   representative plus INCOMPLETE flag when band legs missing. Smoke bands
%   are point bands (min=max=mid=base MID value, incomplete=1) since no OFAT
%   spread is run in smoke; full spread comes from the sensitivity runner.
%
%   CT file: through-path, stage, primary kA (RMS; ip peak where applicable
%   with kind column RMS/PEAK), candidate ratios 1600/1,800/1,400/1 as
%   CANDIDATES never selected, secondary A (= primary*1000/ratio), FL anchor
%   kA. Q0 is a breaker connection; Q1/Q2/Q9 are disconnector connections;
%   tags are labels only.
%
%   FL DERIVATION (no invented numbers): FL anchors from Phase-3 CSV solved
%   flows for LF360_GAT_OUT (same CSVs as solver prefault):
%   GEN_Q anchor = |Sgen|/(sqrt(3)*V22) with Sgen = Gen_P+j*Gen_Q, V22 = 22 kV
%   (Gen_V_kV); GSUT_LV anchor = |Sgen-Saux|/(sqrt(3)*V22) with
%   Saux = Paux+j*Qaux (gen minus aux at 22 kV, losses neglected for anchor
%   only); GSUT_HV anchor = same power at 230 kV (V230_1_kV); LINE_Q9 anchor
%   = |Sexp|/(sqrt(3)*V230_1_kV) with Sexp = Export_P+j*Export_Q (GIS to
%   remote through); GRID_Q anchor = |Sexp|/(sqrt(3)*Vremote_kV) (remote to
%   grid). V values are actual CSV voltages. Line export MW to kA at 230 kV
%   is the core step; other anchors use the same form at their voltage level.
%   Caller FL (frozen Phase-3 flows passed in, never P1A values) overrides
%   when supplied as second arg.
%
%   Footnotes: ip rows carry r/kappa plus borrowed-shape note; Ib rows carry
%   t_break plus constant-E prime reference approximation note; LLG rows
%   carry single-earth note; steady rows carry no-AVR note.
%
%   No forbidden columns are written; header scan errors
%   'phase4_handoff:forbiddenCol' if a forbidden pattern is ever introduced.
%
%   Output fields (exact names): dir, schemaOK, hasSettingsCols. schemaOK is
%   true only when every row carries ALL schema columns (else error before
%   write -- never writes partial rows). hasSettingsCols is false; true only
%   if a forbidden column name pattern is detected in headers (detection,
%   not content).

if isstring(tag), tag = char(tag); end
if ~(ischar(tag) && isrow(tag) && ~isempty(tag))
    error('phase4_handoff:badTag', 'tag must be a non-empty char rowvec (run subdirectory name).');
end
if any(tag == '/' | tag == '\' | tag == ':')
    error('phase4_handoff:badTag', 'tag must not contain path separators.');
end

root = ashuganj_root();
dirPath = fullfile(root, 'results', 'phase4_fault', tag);
if exist(dirPath, 'dir') ~= 7
    parentDir = fullfile(root, 'results', 'phase4_fault');
    if exist(parentDir, 'dir') ~= 7
        mkdir(fullfile(root, 'results'), 'phase4_fault');
    end
    mkdir(parentDir, tag);
end

if nargin < 2 || isempty(FL)
    FL = deriveFL();
else
    if ~isstruct(FL) || ~isscalar(FL)
        error('phase4_handoff:badFL', 'FL (2nd arg) must be a scalar struct of per-path anchors in kA.');
    end
end

schemaHeaders = {'fault_type','location','m','caseID','grid_dataset','XoR_P', ...
    'zero_band','k0g','XdRole','NER_variant','GAT_variant','ZfMode','Zf_ohm', ...
    'coupler','stage','unit','base','Irms_kA','Iang_deg','Iseq0_kA','Iseq1_kA', ...
    'Iseq2_kA','r_kappa_ip','t_break_s','footnote'};

caseID = 'LF360_GAT_OUT'; ds = 'P'; XoR_P = 15; k0gV = 1.5;
XdRole = 'sat'; NERv = 'primary'; GATv = 'H1'; ZfMode = 'bolted'; Zf_ohm = 0;
couplerV = 'closed'; mVal = 0.5; loc = 'F3'; zband = 'MID';
unitStr = 'kA'; baseStr = '100MVA';

Vlevel = 230;
Ibase = 100/(sqrt(3)*Vlevel);

% ---- fault solves (Ikpp base, default opts) ----
FLLL = phase4_solve(caseID, ds, XoR_P, loc, 'LLL', 'Ikpp', Zf_ohm);
FLG = phase4_solve(caseID, ds, XoR_P, loc, 'LG', 'Ikpp', Zf_ohm);
FLLGmid = phase4_solve(caseID, ds, XoR_P, loc, 'LLG', 'Ikpp', Zf_ohm);

% ---- currents rows: LLL Ikpp, LG Ikpp, LLL ip, LG ip ----
[IrmsLLL, AngLLL, s0LLL, s1LLL, s2LLL, ipLLL] = kArow(FLLL, 'LLL', Ibase);
[IrmsLG, AngLG, s0LG, s1LG, s2LG, ipLG] = kArow(FLG, 'LG', Ibase);

fnLLL = footnoteFor('Ikpp', 'LLL', ZfMode, FLLL, NaN);
fnLG = footnoteFor('Ikpp', 'LG', ZfMode, FLG, NaN);
fnIpLLL = footnoteFor('ip', 'LLL', ZfMode, FLLL, NaN);
fnIpLG = footnoteFor('ip', 'LG', ZfMode, FLG, NaN);

cFault = {'LLL';'LG';'LLL';'LG'};
cLoc = {'F3';'F3';'F3';'F3'};
cM = [mVal;mVal;mVal;mVal];
cCase = {caseID;caseID;caseID;caseID};
cDs = {ds;ds;ds;ds};
cXoR = [XoR_P;XoR_P;XoR_P;XoR_P];
cZb = {zband;zband;zband;zband};
cK0g = [k0gV;k0gV;k0gV;k0gV];
cXd = {XdRole;XdRole;XdRole;XdRole};
cNER = {NERv;NERv;NERv;NERv};
cGAT = {GATv;GATv;GATv;GATv};
cZfM = {ZfMode;ZfMode;ZfMode;ZfMode};
cZfO = [Zf_ohm;Zf_ohm;Zf_ohm;Zf_ohm];
cCoup = {couplerV;couplerV;couplerV;couplerV};
cStage = {'Ikpp';'Ikpp';'ip';'ip'};
cUnit = {unitStr;unitStr;unitStr;unitStr};
cBase = {baseStr;baseStr;baseStr;baseStr};
cIrms = [IrmsLLL;IrmsLG;ipLLL;ipLG];
cAng = [AngLLL;AngLG;AngLLL;AngLG];
cS0 = [s0LLL;s0LG;s0LLL;s0LG];
cS1 = [s1LLL;s1LG;s1LLL;s1LG];
cS2 = [s2LLL;s2LG;s2LLL;s2LG];
cIp = [ipLLL;ipLG;ipLLL;ipLG];
cTbrk = [NaN;NaN;NaN;NaN];
cFn = {fnLLL;fnLG;fnIpLLL;fnIpLG};

Tcur = table(cFault,cLoc,cM,cCase,cDs,cXoR,cZb,cK0g,cXd,cNER,cGAT,cZfM,cZfO, ...
    cCoup,cStage,cUnit,cBase,cIrms,cAng,cS0,cS1,cS2,cIp,cTbrk,cFn, ...
    'VariableNames', schemaHeaders);

% ---- schema check before any write (never writes partial rows) ----
if ~isequal(Tcur.Properties.VariableNames, schemaHeaders) || height(Tcur) == 0
    error('phase4_handoff:schema', 'Currents table must carry ALL schema columns in order.');
end
for k = 1:height(Tcur)
    if isempty(Tcur.fault_type{k}) || isempty(Tcur.location{k}) || isempty(Tcur.caseID{k}) ...
            || isempty(Tcur.stage{k}) || isempty(Tcur.footnote{k})
        error('phase4_handoff:schema', 'Every row must carry ALL schema columns (row %d incomplete).', k);
    end
end
magVals = [Tcur.Irms_kA, Tcur.Iseq0_kA, Tcur.Iseq1_kA, Tcur.Iseq2_kA, Tcur.r_kappa_ip];
if any(~isfinite(magVals(:)))
    error('phase4_handoff:badNumeric', 'Fault-currents magnitude columns must be finite (t_break_s exempt).');
end
assertNoForbidden(Tcur.Properties.VariableNames);

% ---- contributions rows (Ikpp only; per-leg ip has no table) ----
CLLL = phase4_contrib(caseID, ds, XoR_P, loc, 'LLL', 'Ikpp', [], 'bolted');
CLG = phase4_contrib(caseID, ds, XoR_P, loc, 'LG', 'Ikpp', [], 'bolted');

% Dynamic leg columns (additive T14): introspect the contrib legs structs for
% the present leg set (union over the smoke rows); absent legs are omitted,
% never zero-filled. Canonical order below reproduces the prior hardcoded
% OUT order exactly (GEN,GSUT_LV,GSUT_HV,UAT,LINE_total,GRID,NER_earth) and
% admits GAT_HV/GAT_LV (IN runs) plus LINE_B1/LINE_B2 (F4 runs) in place.
canonTags = {'GEN','GSUT_LV','GSUT_HV','UAT','GAT_HV','GAT_LV', ...
    'LINE_total','LINE_B1','LINE_B2','GRID','NER_earth'};
presentTags = union(fieldnames(CLLL.legs), fieldnames(CLG.legs));
legTags = canonTags(ismember(canonTags, presentTags));
legHeaders = strcat('leg_', legTags, '_kA');

legMat = NaN(2, numel(legTags));
legMat(1,:) = legRow(CLLL, Ibase, legTags);
legMat(2,:) = legRow(CLG, Ibase, legTags);

% contributions carry full schema (Ikpp rows) plus legs plus kcl
bFault = {'LLL';'LG'};
bLoc = {'F3';'F3'};
bM = [mVal;mVal];
bCase = {caseID;caseID};
bDs = {ds;ds};
bXoR = [XoR_P;XoR_P];
bZb = {zband;zband};
bK0g = [k0gV;k0gV];
bXd = {XdRole;XdRole};
bNER = {NERv;NERv};
bGAT = {GATv;GATv};
bZfM = {ZfMode;ZfMode};
bZfO = [Zf_ohm;Zf_ohm];
bCoup = {couplerV;couplerV};
bStage = {'Ikpp';'Ikpp'};
bUnit = {unitStr;unitStr};
bBase = {baseStr;baseStr};
bIrms = [IrmsLLL;IrmsLG];
bAng = [AngLLL;AngLG];
bS0 = [s0LLL;s0LG];
bS1 = [s1LLL;s1LG];
bS2 = [s2LLL;s2LG];
bIp = [ipLLL;ipLG];
bTbrk = [NaN;NaN];
bFn = {fnLLL;fnLG};
bkclS = [CLLL.kcl_seq;CLG.kcl_seq];
bkclP = [CLLL.kcl_ph;CLG.kcl_ph];
bkclE = [CLLL.kcl_earth;CLG.kcl_earth];

conHeaders = [schemaHeaders, legHeaders, {'kcl_seq','kcl_ph','kcl_earth'}];
% NaN in leg columns means legitimately-absent leg (GAT OUT, NER on LLL) and is correct per spec -- do not extend the currents finite check here.
Tschema = table(bFault,bLoc,bM,bCase,bDs,bXoR,bZb,bK0g,bXd,bNER,bGAT,bZfM,bZfO, ...
    bCoup,bStage,bUnit,bBase,bIrms,bAng,bS0,bS1,bS2,bIp,bTbrk,bFn, ...
    'VariableNames', schemaHeaders);
Tlegs = array2table(legMat, 'VariableNames', legHeaders);
Tkcl = table(bkclS,bkclP,bkclE, 'VariableNames', {'kcl_seq','kcl_ph','kcl_earth'});
Tcon = [Tschema, Tlegs, Tkcl];
assertNoForbidden(Tcon.Properties.VariableNames);

% ---- bands (point bands, incomplete=1) ----
[IrmsLLGmid, ~, ~, ~, ~, ~] = kArow(FLLGmid, 'LLG', Ibase);
bandHeaders = {'group','fault_type','min_Ik_kA','max_Ik_kA','min_leg','max_leg', ...
    'mid_Ik_kA','mid_leg','incomplete','note'};
bGroup = {'F3_LG_OUT_P15_bolted';'F3_LLG_OUT_P15_bolted'};
bType = {'LG';'LLG'};
bMin = [IrmsLG;IrmsLLGmid];
bMax = [IrmsLG;IrmsLLGmid];
bMinLeg = {'base_LF360_OUT_P15';'base_LF360_OUT_P15'};
bMaxLeg = {'base_LF360_OUT_P15';'base_LF360_OUT_P15'};
bMid = [IrmsLG;IrmsLLGmid];
bMidLeg = {'base_LF360_OUT_P15';'base_LF360_OUT_P15'};
bInc = [1;1];
bNote = {'point without band: single-leg smoke, no spread band'; ...
    'point without band: single-leg smoke, no spread band'};
Tband = table(bGroup,bType,bMin,bMax,bMinLeg,bMaxLeg,bMid,bMidLeg,bInc,bNote, ...
    'VariableNames', bandHeaders);
assertNoForbidden(Tband.Properties.VariableNames);

% ---- CT data (through-paths, RMS + borrowed-shape PEAK) ----
ctPaths = {'GEN_Q','GSUT_HV','GSUT_LV','LINE_Q9','GRID_Q'};
ctHeaders = {'fault_type','location','caseID','through_path','stage','kind', ...
    'primary_kA','FL_anchor_kA','ratio_1600_1_A','ratio_800_1_A','ratio_400_1_A','footnote'};
nCt = 2*numel(ctPaths)*2;
ctFault = cell(nCt,1); ctLoc = cell(nCt,1); ctCase = cell(nCt,1);
ctPath = cell(nCt,1); ctStage = cell(nCt,1); ctKind = cell(nCt,1);
ctPrim = zeros(nCt,1); ctFL = zeros(nCt,1);
ctS1600 = zeros(nCt,1); ctS800 = zeros(nCt,1); ctS400 = zeros(nCt,1);
ctFn = cell(nCt,1);
ri = 0;
faultList = {'LLL','LG'};
contribList = {CLLL, CLG};
solveList = {FLLL, FLG};
for fi = 1:2
    ftype = faultList{fi};
    Cc = contribList{fi};
    Fs = solveList{fi};
    kap = Fs.kappa; rr = Fs.r;
    for pi = 1:numel(ctPaths)
        ptag = ctPaths{pi};
        ph = tagPhasor(Cc, ptag);
        rmsPu = abs(ph.Ia);
        rmskA = rmsPu*Ibase;
        peakkA = rmskA*sqrt(2)*kap;
        flA = flFor(ptag, FL);
        % Ikpp RMS row
        ri = ri+1;
        ctFault{ri} = ftype; ctLoc{ri} = loc; ctCase{ri} = caseID;
        ctPath{ri} = ptag; ctStage{ri} = 'Ikpp'; ctKind{ri} = 'RMS';
        ctPrim(ri) = rmskA; ctFL(ri) = flA;
        ctS1600(ri) = rmskA*1000/1600; ctS800(ri) = rmskA*1000/800; ctS400(ri) = rmskA*1000/400;
        ctFn{ri} = 'through-current RMS; ratios are candidates, never selected';
        % ip PEAK row (borrowed-shape)
        ri = ri+1;
        ctFault{ri} = ftype; ctLoc{ri} = loc; ctCase{ri} = caseID;
        ctPath{ri} = ptag; ctStage{ri} = 'ip'; ctKind{ri} = 'PEAK';
        ctPrim(ri) = peakkA; ctFL(ri) = flA;
        ctS1600(ri) = peakkA*1000/1600; ctS800(ri) = peakkA*1000/800; ctS400(ri) = peakkA*1000/400;
        ctFn{ri} = sprintf('borrowed-shape peak estimate; r=%.4f kappa=%.5f; ratios are candidates, never selected', rr, kap);
    end
end
Tct = table(ctFault,ctLoc,ctCase,ctPath,ctStage,ctKind,ctPrim,ctFL, ...
    ctS1600,ctS800,ctS400,ctFn, 'VariableNames', ctHeaders);
assertNoForbidden(Tct.Properties.VariableNames);

% ---- writes (only after all checks pass) ----
writetable(Tcur, fullfile(dirPath, 'phase4_fault_currents.csv'));
writetable(Tcon, fullfile(dirPath, 'phase4_contributions.csv'));
writetable(Tband, fullfile(dirPath, 'phase4_bands.csv'));
writetable(Tct, fullfile(dirPath, 'phase4_ct_data.csv'));

hasSettingsCols = hasForbidden(Tcur.Properties.VariableNames) ...
    || hasForbidden(Tcon.Properties.VariableNames) ...
    || hasForbidden(Tband.Properties.VariableNames) ...
    || hasForbidden(Tct.Properties.VariableNames);
if hasSettingsCols
    error('phase4_handoff:forbiddenCol', 'Forbidden column pattern detected in headers.');
end

schemaOK = true;
H = struct('dir', dirPath, 'schemaOK', schemaOK, 'hasSettingsCols', hasSettingsCols);
fprintf('phase4_handoff %s: %d currents rows, %d contrib rows, %d band rows, %d ct rows in %s\n', ...
    tag, height(Tcur), height(Tcon), height(Tband), height(Tct), dirPath);
end

% =====================================================================
function [Irms, Ang, s0, s1, s2, ipkA] = kArow(F, type, Ibase)
if strcmp(type, 'LG')
    Ifault = F.Ia;
elseif strcmp(type, 'LLG')
    if abs(F.Ib) >= abs(F.Ic)
        Ifault = F.Ib;
    else
        Ifault = F.Ic;
    end
else
    Ifault = F.I1;
end
Irms = abs(Ifault)*Ibase;
Ang = angle(Ifault)*180/pi;
s0 = abs(F.I0)*Ibase;
s1 = abs(F.I1)*Ibase;
s2 = abs(F.I2)*Ibase;
ipkA = F.ip*Ibase;
end

function fn = footnoteFor(stage, type, ZfMode, F, tbrk)
%FOOTNOTEFor  Additive T14 footnote branches (Ikpp/ip strings unchanged).
%   Ib rows carry t_break plus the constant-E' reference approximation note;
%   Isteady rows carry the no-AVR note; LLG rows append the single-earth
%   note. Ikpp/ip non-LLG strings reproduce the prior literals exactly.
if strcmp(stage, 'Ib')
    fn = sprintf('constant-E'' reference approximation at t_break=%.2f s (chosen study reference time, not a measured breaker clearing time); ZfMode=%s', tbrk, ZfMode);
    if strcmp(type, 'LLG')
        fn = [fn '; LLG single-earth path'];
    end
elseif strcmp(stage, 'Isteady')
    fn = sprintf('constant-field synchronous (constant-Eq) steady reference; no-AVR action modelled; ZfMode=%s', ZfMode);
    if strcmp(type, 'LLG')
        fn = [fn '; LLG single-earth path'];
    end
elseif strcmp(stage, 'ip')
    fn = sprintf('ip peak = kappa*sqrt(2)*governing RMS; r=%.4f kappa=%.5f borrowed-shape peak estimate; ZfMode=%s', F.r, F.kappa, ZfMode);
    if strcmp(type, 'LLG')
        fn = [fn '; LLG single-earth path'];
    end
else
    if strcmp(type, 'LLG')
        fn = sprintf('LLG single-earth path; bolted-baseline comparison; ZfMode=%s', ZfMode);
    else
        fn = sprintf('bolted-baseline reference; ZfMode=%s', ZfMode);
    end
end
end

function row = legRow(C, Ibase, tags)
row = NaN(1, numel(tags));
for k = 1:numel(tags)
    if isfield(C.legs, tags{k})
        row(k) = abs(C.legs.(tags{k}).Ia)*Ibase;
    else
        row(k) = NaN;
    end
end
end

function ph = tagPhasor(C, ptag)
if strcmp(ptag, 'GEN_Q')
    ph = C.tags.GEN_Q;
elseif strcmp(ptag, 'GSUT_HV')
    ph = C.tags.GSUT_HV;
elseif strcmp(ptag, 'GSUT_LV')
    ph = C.tags.GSUT_LV;
elseif strcmp(ptag, 'LINE_Q9')
    ph = C.tags.LINE_Q9;
elseif strcmp(ptag, 'GRID_Q')
    ph = C.tags.GRID_Q;
else
    error('phase4_handoff:badPath', 'Unknown through-path ''%s''.', ptag);
end
end

function a = flFor(ptag, FL)
if strcmp(ptag, 'GEN_Q')
    a = FL.GEN_Q;
elseif strcmp(ptag, 'GSUT_HV')
    a = FL.GSUT_HV;
elseif strcmp(ptag, 'GSUT_LV')
    a = FL.GSUT_LV;
elseif strcmp(ptag, 'LINE_Q9')
    a = FL.LINE_Q9;
elseif strcmp(ptag, 'GRID_Q')
    a = FL.GRID_Q;
else
    error('phase4_handoff:badPath', 'Unknown through-path ''%s''.', ptag);
end
end

function FL = deriveFL()
root = ashuganj_root();
Ts = readtable(fullfile(root, 'results', 'phase3_loadflow', 'phase3_system_summary.csv'));
js = find(string(Ts.Case_ID) == string('LF360_GAT_OUT'), 1);
if isempty(js)
    error('phase4_handoff:missingRow', 'No system-summary row for LF360_GAT_OUT.');
end
GenP = Ts.Gen_P_MW(js); GenQ = Ts.Gen_Q_MVAr(js); V22 = Ts.Gen_V_kV(js);
V230_1 = Ts.V230_1_kV(js); Vrem = Ts.V_REMOTE_kV(js);
Paux = Ts.Paux_MW(js); Qaux = Ts.Qaux_MVAr(js);
ExpP = Ts.Export_P_MW(js); ExpQ = Ts.Export_Q_MVAr(js);
Sgen = GenP + 1j*GenQ;
Saux = Paux + 1j*Qaux;
Sgsut = Sgen - Saux;
Sexp = ExpP + 1j*ExpQ;
FL = struct('GEN_Q', abs(Sgen)/(sqrt(3)*V22), ...
    'GSUT_LV', abs(Sgsut)/(sqrt(3)*V22), ...
    'GSUT_HV', abs(Sgsut)/(sqrt(3)*V230_1), ...
    'LINE_Q9', abs(Sexp)/(sqrt(3)*V230_1), ...
    'GRID_Q', abs(Sexp)/(sqrt(3)*Vrem));
end

function assertNoForbidden(headers)
if hasForbidden(headers)
    error('phase4_handoff:forbiddenCol', 'Forbidden column pattern detected in headers.');
end
end

function tf = hasForbidden(headers)
pats = {'pickup','tms','grading','differential','duty','verdict','rating'};
tf = false;
for i = 1:numel(headers)
    h = lower(char(headers{i}));
    for j = 1:numel(pats)
        if ~isempty(strfind(h, pats{j}))
            tf = true;
            return;
        end
    end
end
end
