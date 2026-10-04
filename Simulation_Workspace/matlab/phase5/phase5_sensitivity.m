function S = phase5_sensitivity(T40, devices)
%PHASE5_SENSITIVITY  Fenced CT sensitivity runner (Phase-5 Task 14).
%   S = PHASE5_SENSITIVITY(T40, devices) recomputes GEN-zone relay-currents
%   + operating times + coordination margins under LEGACY-16000/1, where
%   T40 is the phase5_import backbone table (40 rows: 2 cases x 5 locs x
%   4 types, Ikpp) and devices is the phase5_registry devices struct array.
%
%   GEN-zone scope: GEN-51 (phase, all 40 combos) + GEN-51N (earth, LG/LLG
%   combos only, 20 rows) = 60 rows. GSUT/GIS 2000/1 STUDY CTs are
%   untouched: the upstream GSUT-HV-51 backup time is computed once with
%   its own 2000/1 branch and shared by the primary/sensitivity margin
%   pair, so the margin delta isolates the GEN CT change.
%
%   Delegation (nothing reimplemented, nothing modified):
%     relay secondaries via phase5_ct (+ phase5_ct_table(T40, 16000,
%       'LEGACY-16000/1') as the fenced net-total audit reference);
%     pickup settings via phase5_pickup (GEN-51 1.25x rated = 15023.75 A
%       primary; GEN-51N 5 A primary SENSITIVE study setting);
%     operating times via phase5_time (inverse SI, study defaults TMS
%       0.1 GEN / 0.2 GSUT where the registry carries NaN).
%
%   Fixed-dial convention (honest slower direction): the relay pickup dial
%   is set once from the PRIMARY scheme, i.e. Is_fixed = P_primary/15000
%   in secondary amperes. The 16k fault secondary I/16000 is compared
%   against that fixed dial, so M_sens = M_prim*15/16 and t_sens >=
%   t_primary (slower-or-unchanged, never faster). Re-deriving the pickup
%   through 16000 would cancel the ratio and hide the conflict, so this
%   function deliberately does not do that.
%
%   Relay primaries mirror phase5_coord branch parity (times comparable):
%     GEN-51 phase  -> GEN_Q branch leg_GEN_kA when finite, else net total;
%     GEN-51N F1/F2 -> 3xI0 fault total, neutral counted ONCE (Iseq0 when
%       present/finite, else LG-exact If/3; LLG without Iseq0 -> NaN,
%       never invented);
%     GEN-51N F3/F4/F5 -> 3x leg_NER_earth (validated delta block ~0 ->
%       honest NO-TRIP; missing leg -> NaN, never invented).
%   Margins dt = t_up - t_down with CTI 0.3 s study threshold for F1/F2
%   phase pairs (PASS iff dt >= 0.3 else FAIL, honest shortfall never
%   tuned). Either time side Inf -> NO-TRIP. F3/F4/F5 GEN rows carry no
%   pair (topology) -> NO-PAIR with backup t reported. Earth rows carry
%   no residual-CT upstream -> NOT DETERMINABLE FROM AVAILABLE DATA when
%   the downstream trips, NO-TRIP when it does not (LLG-without-Iseq0
%   preserved as NO-TRIP with the detail in reason).
%
%   Purity: inputs in, new table out. This function performs no output
%   calls and keeps no shared workspace state; caller PRIMARY-scope data
%   is never modified (value semantics; asserted by test via isequal).
%
%   S cols (28): fault_location, fault_type, caseID, device_id,
%     I_primary_A, I_primary_kA, relay_path, I_sec_primary_A,
%     I_sec_sens_A, ct_primary, ct_legacy, ct_tag, pickup_primary_A, tms,
%     curve, t_primary_s, t_sens_s, dt_s, direction, margin_primary_s,
%     margin_sens_s, dmargin_s, margin_direction, verdict_primary,
%     verdict_sens, scope ('SENSITIVITY' every row), provenance
%     (LEGACY-tagged every row), reason.
%   All errors are 'phase5'-prefixed.
if nargin ~= 2
    error('phase5_sensitivity:args', 'usage: S = phase5_sensitivity(T40, devices).');
end
if ~istable(T40) || height(T40) < 1
    error('phase5_sensitivity:args', 'T40 must be a non-empty table (phase5_import output, 40 backbone rows).');
end
reqT = {'fault_location', 'fault_type', 'caseID', 'I_primary_A', 'I_primary_kA'};
for k = 1:numel(reqT)
    if ~any(strcmp(T40.Properties.VariableNames, reqT{k}))
        error('phase5_sensitivity:schema', 'T40 missing required column %s.', reqT{k});
    end
end
if ~isstruct(devices) || isempty(devices) || ~isfield(devices, 'device_id')
    error('phase5_sensitivity:devices', 'devices must be a non-empty struct array with device_id (phase5_registry output).');
end
d51 = finddev(devices, 'GEN-51');
d51N = finddev(devices, 'GEN-51N');
dUp = finddev(devices, 'GSUT-HV-51');

locs = tocell(T40.fault_location);
typs = tocell(T40.fault_type);
cases = tocell(T40.caseID);
n = height(T40);
If_A = double(T40.I_primary_A(:));
If_kA = double(T40.I_primary_kA(:));
if any(~isfinite(If_A)) || any(~isfinite(If_kA))
    error('phase5_sensitivity:current', 'T40 fault currents must be finite (I_primary_kA/A).');
end
if any(~(strcmp(typs, 'LLL') | strcmp(typs, 'LG') | strcmp(typs, 'LL') | strcmp(typs, 'LLG')))
    error('phase5_sensitivity:faulttype', 'unsupported fault_type (need LLL/LG/LL/LLG).');
end
if any(~(strcmp(locs, 'F1') | strcmp(locs, 'F2') | strcmp(locs, 'F3') | strcmp(locs, 'F4') | strcmp(locs, 'F5')))
    error('phase5_sensitivity:topology', 'unknown fault_location (need F1..F5).');
end
hasIseq0 = any(strcmp(T40.Properties.VariableNames, 'Iseq0_kA'));
if hasIseq0
    Iseq0_kA = double(T40.Iseq0_kA(:));
else
    Iseq0_kA = NaN(n, 1);
end
legGEN = legcol(T40, 'leg_GEN_kA', n);
legHV = legcol(T40, 'leg_GSUT_HV_kA', n);
legNER = legcol(T40, 'leg_NER_earth_kA', n);

% Imin anchors from net totals (pickup methodology; branch legs affect
% operating times only, never pickup settings, per coord convention).
phaseMask = strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG');
if any(phaseMask)
    IminPhase = min(If_A(phaseMask));
else
    IminPhase = min(If_A);
end
earthMask = strcmp(typs, 'LG') | strcmp(typs, 'LLG');
I0_A = NaN(n, 1);
for i = 1:n
    if strcmp(typs{i}, 'LG') || strcmp(typs{i}, 'LLG')
        if isfinite(Iseq0_kA(i))
            I0_A(i) = Iseq0_kA(i) * 1000;
        elseif strcmp(typs{i}, 'LG')
            I0_A(i) = If_A(i) / 3;
        end
    end
end
finE = isfinite(I0_A(earthMask));
if any(finE)
    tmp = 3 * I0_A(earthMask);
    IminEarth = min(tmp(finE));
else
    IminEarth = 7.27200442799167;
end

% Settings via phase5_pickup (registry value respected when finite).
[pk51, ~] = resolve_pickup(d51, IminPhase, IminEarth);
[pkN, ~] = resolve_pickup(d51N, IminPhase, IminEarth);
[pkUp, ~] = resolve_pickup(dUp, IminPhase, IminEarth);
[tms51, cv51] = resolve_tc(d51, 'GEN-51', 0.1);
[tmsN, cvN] = resolve_tc(d51N, 'GEN-51N', 0.1);
[tmsUp, cvUp] = resolve_tc(dUp, 'GSUT-HV-51', 0.2);
IsFix51 = pk51 / 15000;
IsFixN = pkN / 15000;
IsUp = pkUp / 2000;
CTI = 0.3;

% Fenced net-total audit reference (contract use; branch/3I0 relay
% primaries below are the CT-visible currents per coord parity).
Tleg = phase5_ct_table(T40, 16000, 'LEGACY-16000/1');
if height(Tleg) ~= n
    error('phase5_sensitivity:current', 'legacy audit table row count diverged from T40.');
end

nEarth = sum(earthMask);
total = n + nEarth;
oLoc = cell(total, 1); oTyp = cell(total, 1); oCase = cell(total, 1);
oDev = cell(total, 1); oPath = cell(total, 1);
oIprim = NaN(total, 1); oIk = NaN(total, 1);
oIsecP = NaN(total, 1); oIsecS = NaN(total, 1);
oCtP = repmat(15000, total, 1); oCtL = repmat(16000, total, 1);
oTag = repmat({'LEGACY-16000/1'}, total, 1);
oPk = NaN(total, 1); oTms = NaN(total, 1); oCv = cell(total, 1);
oTp = NaN(total, 1); oTs = NaN(total, 1); oDt = NaN(total, 1);
oDir = cell(total, 1);
oMgP = NaN(total, 1); oMgS = NaN(total, 1); oDmg = NaN(total, 1);
oMdir = cell(total, 1);
oVp = cell(total, 1); oVs = cell(total, 1);
oScope = repmat({'SENSITIVITY'}, total, 1);
oProv = repmat({'LEGACY:CT-16000/1-fenced-sensitivity-vs-PRIMARY-15000/1-SOURCE-BACKED-Phase-4-import'}, total, 1);
oReason = cell(total, 1);
j = 0;
for i = 1:n
    loc = locs{i};
    typ = typs{i};
    cs = cases{i};
    isGenZone = strcmp(loc, 'F1') || strcmp(loc, 'F2');
    % ---- GEN-51 phase row (every combo) ----
    if isfinite(legGEN(i)) && legGEN(i) >= 0
        prim51 = legGEN(i) * 1000;
        path51 = 'GEN_Q-branch-leg_GEN_kA-SOURCE-BACKED';
    else
        prim51 = If_A(i);
        path51 = 'net-total-fallback-no-leg-join';
    end
    secP51 = phase5_ct(prim51, 15000).Isec_A;
    secS51 = phase5_ct(prim51, 16000).Isec_A;
    tP51 = sidetime(secP51, IsFix51, tms51, cv51);
    tS51 = sidetime(secS51, IsFix51, tms51, cv51);
    if isGenZone
        if isfinite(legHV(i)) && legHV(i) >= 0
            primUp = legHV(i) * 1000;
            upTag = 'GSUT_HV-branch-leg_GSUT_HV_kA-SOURCE-BACKED';
        else
            primUp = If_A(i);
            upTag = 'net-total-fallback-no-leg-join';
        end
        tUp = sidetime(primUp / 2000, IsUp, tmsUp, cvUp);
        [mgP, vP] = pairverdict(tP51, tUp, CTI);
        [mgS, vS] = pairverdict(tS51, tUp, CTI);
        mgNote = sprintf([';upstream-GSUT-HV-51-2000/1-untouched(t_up=%.3fs;%s);' ...
            'CTI-0.3s-study-threshold'], tUp, upTag);
    else
        tUp = NaN;
        [mgP, vP] = nopairverdict(tP51);
        [mgS, vS] = nopairverdict(tS51);
        mgNote = [';NO-PAIR (topology): GEN backup not in grid-zone chain;' ...
            'backup-t_down-reported-no-margin-asserted'];
    end
    [dt51, dir51] = classdir(tP51, tS51);
    [dmg51, mdir51] = classmargin(mgP, mgS);
    j = j + 1;
    oLoc{j} = loc; oTyp{j} = typ; oCase{j} = cs; oDev{j} = 'GEN-51';
    oPath{j} = path51; oIprim(j) = prim51; oIk(j) = prim51 / 1000;
    oIsecP(j) = secP51; oIsecS(j) = secS51;
    oPk(j) = pk51; oTms(j) = tms51; oCv{j} = cv51;
    oTp(j) = tP51; oTs(j) = tS51; oDt(j) = dt51; oDir{j} = dir51;
    oMgP(j) = mgP; oMgS(j) = mgS; oDmg(j) = dmg51; oMdir{j} = mdir51;
    oVp{j} = vP; oVs{j} = vS;
    oReason{j} = sprintf(['GEN-51 %s %s %s: relay-primary %.6g A (%s);' ...
        'pickup %.2f A-primary dial-fixed %.6g A-sec;' ...
        'TMS %.3g %s;t_prim %.3fs t_sens %.3fs dt %.3fs (%s)%s;' ...
        'LEGACY-16000/1 fenced vs PRIMARY-15000/1'], ...
        loc, typ, cs, prim51, path51, pk51, IsFix51, ...
        tms51, cv51, tP51, tS51, dt51, dir51, mgNote);
    % ---- GEN-51N earth row (LG/LLG only) ----
    if strcmp(typ, 'LG') || strcmp(typ, 'LLG')
        if isGenZone
            if isfinite(Iseq0_kA(i))
                primN = 3 * Iseq0_kA(i) * 1000;
                pathN = '3I0-fault-total-Iseq0-SOURCE-BACKED-neutral-counted-once';
                missN = false;
            elseif strcmp(typ, 'LG')
                primN = If_A(i);
                pathN = '3I0-LG-exact-If-over-3-DERIVED-neutral-counted-once';
                missN = false;
            else
                primN = NaN;
                pathN = 'MISSING-no-Iseq0-LLG-neutral-counted-once-N/A';
                missN = true;
            end
        else
            if isfinite(legNER(i)) && legNER(i) >= 0
                primN = 3 * legNER(i) * 1000;
                pathN = '3xleg_NER_earth-delta-block-neutral-counted-once';
                missN = false;
            else
                primN = NaN;
                pathN = '3xleg_NER_earth-MISSING-neutral-counted-once-N/A';
                missN = true;
            end
        end
        if isfinite(primN) && primN >= 0
            secPN = phase5_ct(primN, 15000).Isec_A;
            secSN = phase5_ct(primN, 16000).Isec_A;
            tPN = sidetime(secPN, IsFixN, tmsN, cvN);
            tSN = sidetime(secSN, IsFixN, tmsN, cvN);
        else
            secPN = NaN;
            secSN = NaN;
            tPN = NaN;
            tSN = NaN;
        end
        [vPN, vSN, eNote] = earthverdicts(tPN, tSN, missN, isGenZone, loc, typ, cs);
        [dtN, dirN] = classdir(tPN, tSN);
        j = j + 1;
        oLoc{j} = loc; oTyp{j} = typ; oCase{j} = cs; oDev{j} = 'GEN-51N';
        oPath{j} = pathN; oIprim(j) = primN; oIk(j) = primN / 1000;
        oIsecP(j) = secPN; oIsecS(j) = secSN;
        oPk(j) = pkN; oTms(j) = tmsN; oCv{j} = cvN;
        oTp(j) = tPN; oTs(j) = tSN; oDt(j) = dtN; oDir{j} = dirN;
        oMgP(j) = NaN; oMgS(j) = NaN; oDmg(j) = NaN; oMdir{j} = 'N/A';
        oVp{j} = vPN; oVs{j} = vSN;
        oReason{j} = sprintf(['GEN-51N %s %s %s: relay-primary %.6g A (%s);' ...
            'pickup %.2f A-primary dial-fixed %.6g A-sec;' ...
            'TMS %.3g %s;t_prim %.3fs t_sens %.3fs dt %.3fs (%s);%s;' ...
            'LEGACY-16000/1 fenced vs PRIMARY-15000/1'], ...
            loc, typ, cs, primN, pathN, pkN, IsFixN, ...
            tmsN, cvN, tPN, tSN, dtN, dirN, eNote);
    end
end
S = table(oLoc, oTyp, oCase, oDev, oIprim, oIk, oPath, oIsecP, oIsecS, ...
    oCtP, oCtL, oTag, oPk, oTms, oCv, oTp, oTs, oDt, oDir, ...
    oMgP, oMgS, oDmg, oMdir, oVp, oVs, oScope, oProv, oReason, ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'device_id', ...
    'I_primary_A', 'I_primary_kA', 'relay_path', 'I_sec_primary_A', ...
    'I_sec_sens_A', 'ct_primary', 'ct_legacy', 'ct_tag', 'pickup_primary_A', ...
    'tms', 'curve', 't_primary_s', 't_sens_s', 'dt_s', 'direction', ...
    'margin_primary_s', 'margin_sens_s', 'dmargin_s', 'margin_direction', ...
    'verdict_primary', 'verdict_sens', 'scope', 'provenance', 'reason'});
end

function d = finddev(devices, id)
d = [];
for k = 1:numel(devices)
    did = devices(k).device_id;
    if isstring(did) && isscalar(did), did = char(did); end
    if ischar(did) && strcmp(strtrim(did), id), d = devices(k); return; end
end
error('phase5_sensitivity:devices', 'device %s not found in registry devices.', id);
end

function [pk, psrc] = resolve_pickup(d, IminPhase, IminEarth)
pkv = double(d.pickup_A);
if isscalar(pkv) && isfinite(pkv) && pkv > 0
    pk = pkv;
    psrc = 'registry';
    return;
end
id = d.device_id;
if isstring(id) && isscalar(id), id = char(id); end
id = strtrim(id);
isEF = strcmp(id, 'GEN-51N');
if ~isEF
    a = d.ansi;
    if isstring(a) && isscalar(a), a = char(a); end
    if ischar(a) && strcmp(strtrim(a), '51N'), isEF = true; end
end
if isEF
    P = phase5_pickup(d, 0, IminEarth);
else
    rA = double(d.rated_A);
    if ~(isscalar(rA) && isfinite(rA) && rA > 0)
        error('phase5_sensitivity:load', ['phase5_sensitivity: %s needs finite rated_A ', ...
            'as Iload proxy for pickup fallback.'], id);
    end
    P = phase5_pickup(d, rA, IminPhase);
end
pk = P.setting;
psrc = 'T6-fallback';
end

function [tms, cv] = resolve_tc(d, id, defTms)
tm = double(d.tms);
if isscalar(tm) && isfinite(tm) && tm > 0
    tms = tm;
else
    tms = defTms;
end
cv = d.curve;
if isstring(cv) && isscalar(cv), cv = char(cv); end
if ischar(cv) && ~isempty(strtrim(cv))
    cv = upper(strtrim(cv));
    if ~any(strcmp(cv, {'SI', 'VI', 'EI', 'DT'}))
        error('phase5_sensitivity:curve', 'device %s curve %s unsupported (need SI/VI/EI/DT).', id, cv);
    end
else
    cv = 'SI';
end
end

function t = sidetime(Isec, IsSec, tms, cv)
if ~isscalar(Isec) || ~isreal(Isec) || ~isfinite(Isec) || Isec < 0
    t = NaN;
    return;
end
t = phase5_time(Isec, IsSec, tms, cv);
end

function [mg, vd] = pairverdict(tDown, tUp, CTI)
if ~isfinite(tDown) || ~isfinite(tUp)
    mg = NaN;
    vd = 'NO-TRIP';
    return;
end
mg = tUp - tDown;
if mg >= CTI
    vd = 'PASS';
else
    vd = 'FAIL';
end
end

function [mg, vd] = nopairverdict(tDown)
mg = NaN;
if ~isfinite(tDown)
    vd = 'NO-TRIP';
else
    vd = 'NO-PAIR';
end
end

function [vP, vS, note] = earthverdicts(tP, tS, missN, isGenZone, loc, typ, cs)
if missN
    if isGenZone
        vP = 'NO-TRIP';
        vS = 'NO-TRIP';
        note = sprintf(['NO-TRIP: relay current NOT DETERMINABLE (I0 missing for %s %s %s;' ...
            ' NOT DETERMINABLE FROM AVAILABLE DATA detail)-never-forced-PASS;' ...
            'upstream earth element has no residual CT'], loc, typ, cs);
    else
        vP = 'NOT DETERMINABLE FROM AVAILABLE DATA';
        vS = 'NOT DETERMINABLE FROM AVAILABLE DATA';
        note = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: NER leg missing for %s %s %s;' ...
            ' generator earth current cannot be determined, never invented'], loc, typ, cs);
    end
    return;
end
if isfinite(tP)
    vP = 'NOT DETERMINABLE FROM AVAILABLE DATA';
else
    vP = 'NO-TRIP';
end
if isfinite(tS)
    vS = 'NOT DETERMINABLE FROM AVAILABLE DATA';
else
    vS = 'NO-TRIP';
end
if strcmp(vP, 'NOT DETERMINABLE FROM AVAILABLE DATA') || strcmp(vS, 'NOT DETERMINABLE FROM AVAILABLE DATA')
    note = ['NOT DETERMINABLE FROM AVAILABLE DATA: upstream earth element has no residual CT;' ...
        ' downstream 3I0 trip cannot assert backup coordination, never invented'];
else
    note = ['NO-TRIP: downstream below pickup (HV-fault earth delta block or light earth)' ...
        ' - never-forced-PASS'];
end
end

function [dt, dir] = classdir(tP, tS)
if isnan(tP) && isnan(tS)
    dt = NaN;
    dir = 'NOT-DETERMINABLE';
elseif isnan(tP) || isnan(tS)
    dt = NaN;
    dir = 'NOT-DETERMINABLE';
elseif isinf(tP) && isinf(tS)
    dt = 0;
    dir = 'unchanged-no-trip';
elseif isfinite(tP) && isinf(tS)
    dt = Inf;
    dir = 'slower-no-trip';
elseif isinf(tP) && isfinite(tS)
    dt = -Inf;
    dir = 'faster-trip';
else
    dt = tS - tP;
    if abs(dt) <= 1e-9
        dir = 'unchanged';
    elseif dt > 0
        dir = 'slower';
    else
        dir = 'faster';
    end
end
end

function [dmg, mdir] = classmargin(mgP, mgS)
if isfinite(mgP) && isfinite(mgS)
    dmg = mgS - mgP;
    if abs(dmg) <= 1e-9
        mdir = 'unchanged';
    elseif dmg < 0
        mdir = 'tighter';
    else
        mdir = 'wider';
    end
else
    dmg = NaN;
    mdir = 'N/A';
end
end

function v = legcol(Tsec, name, n)
if any(strcmp(Tsec.Properties.VariableNames, name))
    v = double(Tsec.(name)(:));
    if numel(v) ~= n, v = NaN(n, 1); end
else
    v = NaN(n, 1);
end
end

function c = tocell(v)
if iscell(v)
    c = v(:);
    for k = 1:numel(c)
        if isstring(c{k}) && isscalar(c{k}), c{k} = char(c{k}); end
    end
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = cellstr(v);
else
    error('phase5_sensitivity:schema', 'text column must be cell/string/char.');
end
end
