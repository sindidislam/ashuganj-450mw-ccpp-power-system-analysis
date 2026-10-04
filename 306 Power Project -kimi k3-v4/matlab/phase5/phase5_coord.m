function [Mtrx, Mrg] = phase5_coord(devices, Tsec)
%PHASE5_COORD  Coordination matrix + margin engine (Phase-5 Task 8, branch-current correction).
%   [Mtrx, Mrg] = PHASE5_COORD(devices, Tsec) builds the protection
%   coordination matrix from registry devices and the phase5_import backbone
%   table (2 cases x 5 locs x 4 types, first-per-key Ikpp rows).
%
%   Hierarchy (topology-built, from phase5_registry upstream/downstream):
%     F1/F2 (generator zone): GEN-51 -> GSUT-HV-51 -> GIS-Q0-51, i.e. pairs
%       (GEN-51, GSUT-HV-51) and (GSUT-HV-51, GIS-Q0-51), emitted for EVERY
%       fault type (LLL/LG/LL/LLG). Earth rows (LG/LLG) use GEN-51N (ANSI 51N)
%       as the downstream device of an ADDITIONAL earth pair set (see below).
%     F3/F4/F5 (grid zone): chain LINE-side -> GIS-Q0-51 -> GRID-boundary.
%       LINE-21-note is NOTE-only (no OC settings invented) and
%       REMOTE-GRID-boundary is monitoring-only: one PHASE row per combo with
%       downstream GIS-Q0-51, upstream REMOTE-GRID-boundary, verdict NO-PAIR
%       (topology) and the backup t_down still reported. Never silently
%       dropped (Task-13 coverage). Earth LG/LLG combos additionally carry
%       two EARTH rows (same pair labels as the generator-zone earth set).
%
%   Relay currents (BRANCH-CURRENT CORRECTION, controller-verified F1 LG OUT:
%   total Irms 0.007272 kA vs legs GEN 8.4141 / GSUT_HV 8.0155 / LINE 8.0155 /
%   GRID 8.0155 kA, KCL ~1e-12; branch magnitudes are the real CT-visible
%   currents, signed phasors cancelling to the net total):
%     Phase rows (LLL/LG/LL/LLG - ALL types): relay primary = BRANCH
%       through-current leg for that (case,loc,type), per device:
%         GEN-51     (all locs) -> GEN_Q leg (Tsec leg_GEN_kA, SOURCE-BACKED
%           import join of phase4_contributions; identical to ct_data GEN_Q).
%         GSUT-HV-51 (all locs) -> GSUT_HV leg (Tsec leg_GSUT_HV_kA).
%         GIS-Q0-51  F1/F2      -> GRID_Q leg (Tsec leg_GRID_kA, grid infeed
%           toward generator fault); F3/F4/F5 -> LINE_Q9 leg via the T3-joined
%           LINE proxy leg_LINE_total_kA (see F4 caveat below).
%       Each side of a pair therefore uses its OWN branch (I_down and I_up in
%       one row generally differ). I_fault_kA column still carries the net
%       backbone total for reference/regression; I_down_A/I_up_A are
%       SECONDARY amperes (branch primary / device CT).
%       GIS rows stamp 'infeed-branch assumption, see registry equipment
%       field' with the registry equipment value.
%       F4 CAVEAT (honest limitation, flagged): for F4 LLL OUT the import
%       LINE proxy leg_LINE_total_kA (51.058 = net total) diverges from
%       ct_data LINE_Q9 through-current (3.1721 = GSUT_HV infeed via Q0);
%       F4 LL shows LINE_total ~0 vs LINE_Q9 0.773. The coord uses the
%       T3-joined leg per contract (files limited to coord+test, no import
%       change); F1/F3/F5 LINE_Q9 == LINE_total within phasor tolerance.
%       When a leg column is absent (legacy synthetic tables) or NaN, the
%       side falls back to the net total with tag
%       'total-fallback-no-leg (synthetic/no-leg-join)' so all prior margin-
%       arithmetic unit tests (leg-free DT synthetics) remain exact.
%     Earth rows (LG/LLG, additional rows alongside the phase rows):
%       GEN-51N F1/F2 -> 3 x Iseq0 FAULT TOTAL (neutral counted ONCE:
%         Iearth = 3*I0, I0 = Iseq0_kA*1000 when present/finite else LG-exact
%         If/3; LLG without Iseq0 -> NaN, never invented; leg_NER_earth is
%         NEVER added on top and no second 3ZN scaling is applied anywhere -
%         asserted by unit test I_down*ct/3 == Iseq0).
%       GEN-51N F3/F4/F5 -> 3 x leg_NER_earth (≈0 by validated delta block)
%         -> honest NO-TRIP (genuine below pickup) with reason 'delta block,
%         generator NER carries no HV-fault earth current'.
%       GSUT-HV-51 / GIS-Q0-51 earth elements: NO residual CT in registry ->
%         current NaN, time NaN, ct NaN, margin NaN, verdict
%         'NOT DETERMINABLE FROM AVAILABLE DATA' (never NO-TRIP-by-threshold,
%         never invented). Earth pair 1 (GEN-51N > GSUT-HV-51): downstream
%         reported honestly; upstream missing -> NOT DETERMINABLE when the
%         downstream trips, NO-TRIP when the downstream itself is below
%         pickup or missing (genuine/missing-data, never forced PASS; LLG-
%         without-Iseq0 downstream-missing preserved as NO-TRIP for backward
%         compat, reason notes the NOT DETERMINABLE detail). Earth pair 2
%         (GSUT-HV-51 > GIS-Q0-51): both sides missing -> always
%         NOT DETERMINABLE (never NO-TRIP-by-threshold).
%
%   Settings per device (T6 rules + registry fields): unchanged from Task 8
%   (pickup from device.pickup_A else phase5_pickup fallback with rated_A
%   Iload proxy / 0 for GEN-51N; Imin phase from backbone TOTALS over
%   LLL/LL/LLG per pickup methodology 'never LG earth', Imin earth from 3I0;
%   TMS registry else 0.1/0.2/0.3 study defaults; curve registry else SI).
%   Imin anchors stay totals-based so T6-fallback pickups are pinned
%   (GEN-51 15023.75 A, GEN-51N 5 A); branch currents affect OPERATING TIMES
%   only, never pickup settings (no tuning to force PASS).
%   GIS-Q0-50 (ANSI 50, DISABLED-unless-justified) is never a pair member.
%
%   Margin dt = t_up - t_down (s, each side from its OWN branch); CTI = 0.3 s
%   ENGINEERING_ASSUMPTION study threshold. PASS iff dt >= 0.3 else FAIL +
%   reason (honest shortfall, never tuned). Either side Inf (genuine below
%   pickup) -> NO-TRIP (never forced PASS). Missing-Ct earth side (NaN) ->
%   NOT DETERMINABLE (never NO-TRIP-by-threshold). No computable upstream
%   device (REMOTE-GRID-boundary phase) -> NO-PAIR.
%
%   Mtrx cols (locked, 15): downstream, upstream, fault_location,
%     fault_type, caseID, I_fault_kA, I_down_A, I_up_A, t_down_s, t_up_s,
%     ct_down, ct_up, margin_s, verdict, reason.
%   Mrg cols: pair ('DOWN>UP'), fault_location, fault_type, caseID,
%     margin_s, verdict, reason.
%   Verdict domain: PASS / FAIL / NO-TRIP / NO-PAIR /
%     NOT DETERMINABLE FROM AVAILABLE DATA.
%   All errors are 'phase5'-prefixed.
if nargin ~= 2
    error('phase5_coord:args', 'usage: [Mtrx, Mrg] = phase5_coord(devices, Tsec).');
end
if ~isstruct(devices) || isempty(devices) || ~isfield(devices, 'device_id')
    error('phase5_coord:devices', 'devices must be a non-empty struct array with device_id (phase5_registry output).');
end
reqDev = {'device_id', 'ct_ratio', 'rated_A', 'pickup_A', 'tms', 'curve', 'ansi', 'device_type'};
for k = 1:numel(reqDev)
    if ~isfield(devices, reqDev{k})
        error('phase5_coord:schema', 'devices missing locked registry field %s.', reqDev{k});
    end
end
if ~istable(Tsec) || height(Tsec) < 1
    error('phase5_coord:args', 'Tsec must be a non-empty table (phase5_import output).');
end
reqT = {'fault_location', 'fault_type', 'caseID'};
for k = 1:numel(reqT)
    if ~any(strcmp(Tsec.Properties.VariableNames, reqT{k}))
        error('phase5_coord:schema', 'Tsec missing required column %s.', reqT{k});
    end
end
hasKA = any(strcmp(Tsec.Properties.VariableNames, 'I_primary_kA'));
hasA = any(strcmp(Tsec.Properties.VariableNames, 'I_primary_A'));
if ~hasKA && ~hasA
    error('phase5_coord:schema', 'Tsec needs I_primary_kA and/or I_primary_A (phase5_import output).');
end
locs = tocell(Tsec.fault_location);
typs = tocell(Tsec.fault_type);
cases = tocell(Tsec.caseID);
n = height(Tsec);
If_kA = NaN(n, 1); If_A = NaN(n, 1);
if hasKA, If_kA = double(Tsec.I_primary_kA(:)); end
if hasA, If_A = double(Tsec.I_primary_A(:)); end
if ~hasKA, If_kA = If_A / 1000; end
if ~hasA, If_A = If_kA * 1000; end
if any(~isfinite(If_A))
    error('phase5_coord:current', 'Tsec fault currents must be finite (I_primary_kA/A).');
end
hasIseq0 = any(strcmp(Tsec.Properties.VariableNames, 'Iseq0_kA'));
if hasIseq0
    Iseq0_kA = double(Tsec.Iseq0_kA(:));
else
    Iseq0_kA = NaN(n, 1);
end
% Branch legs (kA, NaN vector when the column is absent = legacy synthetic).
legGEN = legcol(Tsec, 'leg_GEN_kA', n);
legHV = legcol(Tsec, 'leg_GSUT_HV_kA', n);
legLINE = legcol(Tsec, 'leg_LINE_total_kA', n);
legGRID = legcol(Tsec, 'leg_GRID_kA', n);
legNER = legcol(Tsec, 'leg_NER_earth_kA', n);
phaseMask = strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG');
earthMask = strcmp(typs, 'LG') | strcmp(typs, 'LLG');
if any(~(phaseMask | strcmp(typs, 'LG')))
    bad = typs(~(phaseMask | strcmp(typs, 'LG')));
    error('phase5_coord:faulttype', 'unsupported fault_type %s (need LLL/LG/LL/LLG).', bad{1});
end
if any(~(strcmp(locs, 'F1') | strcmp(locs, 'F2') | strcmp(locs, 'F3') | strcmp(locs, 'F4') | strcmp(locs, 'F5')))
    bad = locs(~(strcmp(locs, 'F1') | strcmp(locs, 'F2') | strcmp(locs, 'F3') | strcmp(locs, 'F4') | strcmp(locs, 'F5')));
    error('phase5_coord:topology', 'unknown fault_location %s (need F1..F5).', bad{1});
end
% Imin anchors from Tsec TOTALS (pickup methodology; branch affects times only).
if any(phaseMask)
    IminPhase = min(If_A(phaseMask));
else
    IminPhase = min(If_A);
end
I0_A = NaN(n, 1); i0src = repmat({''}, n, 1);
for i = 1:n
    if strcmp(typs{i}, 'LG') || strcmp(typs{i}, 'LLG')
        if isfinite(Iseq0_kA(i))
            I0_A(i) = Iseq0_kA(i) * 1000;
            i0src{i} = 'Iseq0-SOURCE-BACKED';
        elseif strcmp(typs{i}, 'LG')
            I0_A(i) = If_A(i) / 3;
            i0src{i} = 'LG-exact-I/3-DERIVED';
        else
            i0src{i} = 'MISSING-no-Iseq0-LLG';
        end
    end
end
finE = isfinite(I0_A(earthMask));
if any(finE)
    tmp = 3 * I0_A(earthMask); IminEarth = min(tmp(finE));
else
    IminEarth = 7.27200442799167;  % F1-LG-OUT T1 identity fallback (SOURCE-BACKED constant)
end
% Registry equipment labels for infeed-branch reason stamps.
gisEquip = equipment_of(devices, 'GIS-Q0-51');
gsutEquip = equipment_of(devices, 'GSUT-HV-51');
% Resolve protection-device settings once (lazy per id, cached).
cache.ids = {}; cache.set = {};
    function s = setting(id)
        for q = 1:numel(cache.ids)
            if strcmp(cache.ids{q}, id), s = cache.set{q}; return; end
        end
        s = resolve_device(devices, id, IminPhase, IminEarth);
        cache.ids{end + 1} = id; cache.set{end + 1} = s;
    end
CTI = 0.3;  % s, ENGINEERING_ASSUMPTION study threshold (Task-8 contract)
% Output accumulators.
oDown = {}; oUp = {}; oLoc = {}; oTyp = {}; oCase = {};
oIf = []; oId = []; oIu = []; oTd = []; oTu = []; oCd = []; oCu = [];
oMg = []; oVd = {}; oRs = {};
    function push(dIdp, uIdp, loc, typ, cs, IfkA, IdownA, IupA, tdown, tup, ctd, ctu, mg, vd, rs)
        oDown{end + 1} = dIdp; oUp{end + 1} = uIdp;
        oLoc{end + 1} = loc; oTyp{end + 1} = typ; oCase{end + 1} = cs;
        oIf(end + 1) = IfkA; oId(end + 1) = IdownA; oIu(end + 1) = IupA;
        oTd(end + 1) = tdown; oTu(end + 1) = tup;
        oCd(end + 1) = ctd; oCu(end + 1) = ctu;
        oMg(end + 1) = mg; oVd{end + 1} = vd; oRs{end + 1} = rs;
    end
    function [primA, tag] = branchA(legkA_i, pathTag, fallbackA)
        %BRANCHA  Through-current primary A: leg when finite else net-total fallback.
        if isfinite(legkA_i)
            primA = legkA_i * 1000;
            tag = sprintf(';branch-through-current:%s-SOURCE-BACKED', pathTag);
        else
            primA = fallbackA;
            tag = ';total-fallback-no-leg (synthetic/no-leg-join)';
        end
    end
for i = 1:n
    loc = locs{i}; typ = typs{i}; cs = cases{i};
    isEarth = strcmp(typ, 'LG') || strcmp(typ, 'LLG');
    isGenZone = strcmp(loc, 'F1') || strcmp(loc, 'F2');
    % ---- Branch primaries for this combo (fallback to net total if no leg) ----
    [bGEN, tagGEN] = branchA(legGEN(i), 'GEN_Q-leg_GEN_kA', If_A(i));
    [bHV, tagHV] = branchA(legHV(i), 'GSUT_HV-leg_GSUT_HV_kA', If_A(i));
    if isGenZone
        [bGIS, tagGIS] = branchA(legGRID(i), 'GRID_Q-leg_GRID_kA', If_A(i));
    else
        [bGIS, tagGISln] = branchA(legLINE(i), 'LINE_Q9-proxy-leg_LINE_total_kA', If_A(i));
        tagGIS = [tagGISln ';infeed-branch assumption, see registry equipment field (' gisEquip ')'];
    end
    if isGenZone
        tagGIS = [tagGIS ';infeed-branch assumption, see registry equipment field (' gisEquip ')'];
    end
    % ---- PHASE rows: every fault type, every location ----
    if isGenZone
        % Pair 1: GEN-51 (GEN_Q) > GSUT-HV-51 (GSUT_HV).
        sd = setting('GEN-51'); su = setting('GSUT-HV-51');
        IdownP = bGEN; IupP = bHV;
        Idown = IdownP / sd.ct; Iup = IupP / su.ct;
        tdown = otime(IdownP, sd); tup = otime(IupP, su);
        curTag = [tagGEN ';+;' tagHV ';branch-pair-GEN_Q-vs-GSUT_HV'];
        if ~isfinite(tdown) || ~isfinite(tup)
            vd = 'NO-TRIP'; mg = NaN;
            rs = [notrip_reason2('GEN-51', 'GSUT-HV-51', IdownP, IupP, sd, su, tdown, tup) curTag];
        else
            mg = tup - tdown;
            if mg >= CTI
                vd = 'PASS';
                rs = sprintf('PASS: margin %.3f s >= CTI 0.3 s (ENGINEERING_ASSUMPTION)%s', mg, curTag);
            else
                vd = 'FAIL';
                rs = sprintf(['FAIL: margin %.3f s < CTI 0.3 s (ENGINEERING_ASSUMPTION);' ...
                    'honest-shortfall-never-tuned%s'], mg, curTag);
            end
        end
        rs = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rs, sd.psrc, sd.tsrc, sd.curve);
        push('GEN-51', 'GSUT-HV-51', loc, typ, cs, If_kA(i), Idown, Iup, tdown, tup, sd.ct, su.ct, mg, vd, rs);
        % Pair 2: GSUT-HV-51 (GSUT_HV) > GIS-Q0-51 (GRID_Q / LINE proxy).
        sd2 = setting('GSUT-HV-51'); su2 = setting('GIS-Q0-51');
        IdownP2 = bHV; IupP2 = bGIS;
        Idown2 = IdownP2 / sd2.ct; Iup2 = IupP2 / su2.ct;
        tdown2 = otime(IdownP2, sd2); tup2 = otime(IupP2, su2);
        curTag2 = [tagHV ';+;' tagGIS ';branch-pair-GSUT_HV-vs-GRID_Q'];
        if ~isfinite(tdown2) || ~isfinite(tup2)
            vd2 = 'NO-TRIP'; mg2 = NaN;
            rs2 = [notrip_reason2('GSUT-HV-51', 'GIS-Q0-51', IdownP2, IupP2, sd2, su2, tdown2, tup2) curTag2];
        else
            mg2 = tup2 - tdown2;
            if mg2 >= CTI
                vd2 = 'PASS';
                rs2 = sprintf('PASS: margin %.3f s >= CTI 0.3 s (ENGINEERING_ASSUMPTION)%s', mg2, curTag2);
            else
                vd2 = 'FAIL';
                rs2 = sprintf(['FAIL: margin %.3f s < CTI 0.3 s (ENGINEERING_ASSUMPTION);' ...
                    'honest-shortfall-never-tuned%s'], mg2, curTag2);
            end
        end
        rs2 = sprintf('%s;pickup-%s/%s;TMS-%s/%s;curve-%s', rs2, sd2.psrc, su2.psrc, sd2.tsrc, su2.tsrc, sd2.curve);
        push('GSUT-HV-51', 'GIS-Q0-51', loc, typ, cs, If_kA(i), Idown2, Iup2, tdown2, tup2, sd2.ct, su2.ct, mg2, vd2, rs2);
    else
        % Grid-zone phase row: GIS-Q0-51 (LINE_Q9 proxy) vs REMOTE boundary.
        sdg = setting('GIS-Q0-51');
        IdownPg = bGIS;
        IdownG = IdownPg / sdg.ct;
        tdownG = otime(IdownPg, sdg);
        rsG = sprintf(['NO-PAIR (topology): %s chain LINE-side->GIS-Q0-51->GRID-boundary;' ...
            'LINE-21 NOTE-only no-OC-settings;no-upstream-OC-device-beyond-Q0;' ...
            'backup-t_down=%.3fs-reported-no-margin-asserted%s'], loc, tdownG, tagGIS);
        rsG = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsG, sdg.psrc, sdg.tsrc, sdg.curve);
        push('GIS-Q0-51', 'REMOTE-GRID-boundary', loc, typ, cs, If_kA(i), IdownG, NaN, tdownG, NaN, sdg.ct, NaN, NaN, 'NO-PAIR', rsG);
    end
    % ---- EARTH rows: LG/LLG only, additional rows alongside the phase rows ----
    if isEarth
        if isGenZone
            % F1/F2 earth: downstream 3xIseq0 fault total, neutral counted ONCE.
            % Single-count identity: Iearth = 3*I0 exactly once; NER leg never
            % added; no second 3ZN scaling anywhere (unit-tested).
            Iearth = 3 * I0_A(i);
            earthTag = sprintf([';3I0-path I0-%s neutral-counted-once' ...
                ' (neutral counted ONCE, no second 3ZN scaling, no NER add-on)'], i0src{i});
            sN = setting('GEN-51N');
            if ~isfinite(Iearth)
                % Missing I0 (LLG without Iseq0): preserved NO-TRIP (never
                % invented); reason carries the NOT DETERMINABLE detail.
                IdownE = NaN; tdownE = NaN;
                vdE = 'NO-TRIP'; mgE = NaN;
                rsE = sprintf(['NO-TRIP: relay current NOT DETERMINABLE (I0 missing: %s; ' ...
                    'NOT DETERMINABLE FROM AVAILABLE DATA detail) - never-forced-PASS%s'], i0src{i}, earthTag);
                rsE = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsE, sN.psrc, sN.tsrc, sN.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), NaN, NaN, NaN, NaN, sN.ct, NaN, mgE, vdE, rsE);
            elseif ~isfinite(otime(Iearth, sN))
                IdownE = Iearth / sN.ct; tdownE = Inf;
                vdE = 'NO-TRIP'; mgE = NaN;
                rsE = sprintf(['NO-TRIP: downstream GEN-51N below pickup (I=%.6gA<Is=%.6gA primary)' ...
                    ' - never-forced-PASS%s'], Iearth, sN.pickupPrim, earthTag);
                rsE = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsE, sN.psrc, sN.tsrc, sN.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), IdownE, NaN, tdownE, NaN, sN.ct, NaN, mgE, vdE, rsE);
            else
                IdownE = Iearth / sN.ct; tdownE = otime(Iearth, sN);
                vdE = 'NOT DETERMINABLE FROM AVAILABLE DATA'; mgE = NaN;
                rsE = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: upstream GSUT-HV-51 earth element' ...
                    ' has no residual CT in registry (equipment %s); downstream GEN-51N 3I0 trips' ...
                    ' (t_down=%.3fs) but backup coordination cannot be asserted; never NO-TRIP-by-threshold,' ...
                    ' never invented%s'], gsutEquip, tdownE, earthTag);
                rsE = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsE, sN.psrc, sN.tsrc, sN.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), IdownE, NaN, tdownE, NaN, sN.ct, NaN, mgE, vdE, rsE);
            end
            % Earth pair 2: both sides missing residual CT -> always NOT DETERMINABLE.
            rsE2 = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: no residual CT in registry for' ...
                ' GSUT-HV-51 (equipment %s) / GIS-Q0-51 (equipment %s) on %s %s %s earth;' ...
                ' never NO-TRIP-by-threshold, never invented;3I0-path neutral-counted-once N/A-to-missing-sides'], ...
                gsutEquip, gisEquip, loc, typ, cs);
            rsE2 = [rsE2 ';pickup-N/A-earth-no-residual-CT;TMS-N/A;curve-N/A'];
            push('GSUT-HV-51', 'GIS-Q0-51', loc, typ, cs, If_kA(i), NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                'NOT DETERMINABLE FROM AVAILABLE DATA', rsE2);
        else
            % F3/F4/F5 earth: generator NER monitoring + missing-CT HV earth.
            % 3 x leg_NER_earth: validated delta block (~0 for HV faults).
            if isfinite(legNER(i))
                Ine = 3 * legNER(i) * 1000;
                neTag = [';3I0-path 3xleg_NER_earth neutral-counted-once' ...
                    ' (neutral counted ONCE, no second 3ZN scaling)' ...
                    ';delta block, generator NER carries no HV-fault earth current'];
            else
                Ine = NaN;
                neTag = [';3I0-path 3xleg_NER_earth-MISSING neutral-counted-once' ...
                    ';delta block, generator NER carries no HV-fault earth current (leg missing)'];
            end
            sNg = setting('GEN-51N');
            if ~isfinite(Ine)
                vdEg = 'NOT DETERMINABLE FROM AVAILABLE DATA'; mgEg = NaN;
                rsEg = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: NER leg missing for %s %s %s;' ...
                    ' generator earth current cannot be determined, never invented%s'], loc, typ, cs, neTag);
                rsEg = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsEg, sNg.psrc, sNg.tsrc, sNg.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), NaN, NaN, NaN, NaN, sNg.ct, NaN, mgEg, vdEg, rsEg);
            elseif ~isfinite(otime(Ine, sNg))
                IdownEg = Ine / sNg.ct;
                vdEg = 'NO-TRIP'; mgEg = NaN;
                rsEg = sprintf(['NO-TRIP: downstream GEN-51N below pickup (I=%.6gA<Is=%.6gA primary;' ...
                    ' HV-fault earth) - never-forced-PASS%s'], Ine, sNg.pickupPrim, neTag);
                rsEg = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsEg, sNg.psrc, sNg.tsrc, sNg.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), IdownEg, NaN, Inf, NaN, sNg.ct, NaN, mgEg, vdEg, rsEg);
            else
                IdownEg = Ine / sNg.ct; tdownEg = otime(Ine, sNg);
                vdEg = 'NOT DETERMINABLE FROM AVAILABLE DATA'; mgEg = NaN;
                rsEg = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: upstream GSUT-HV-51 earth element' ...
                    ' has no residual CT in registry (equipment %s); downstream GEN-51N NER trips' ...
                    ' (t_down=%.3fs) but backup cannot be asserted; never NO-TRIP-by-threshold%s'], ...
                    gsutEquip, tdownEg, neTag);
                rsEg = sprintf('%s;pickup-%s;TMS-%s;curve-%s', rsEg, sNg.psrc, sNg.tsrc, sNg.curve);
                push('GEN-51N', 'GSUT-HV-51', loc, typ, cs, If_kA(i), IdownEg, NaN, tdownEg, NaN, sNg.ct, NaN, mgEg, vdEg, rsEg);
            end
            rsE2g = sprintf(['NOT DETERMINABLE FROM AVAILABLE DATA: no residual CT in registry for' ...
                ' GSUT-HV-51 (equipment %s) / GIS-Q0-51 (equipment %s) on %s %s %s earth;' ...
                ' never NO-TRIP-by-threshold, never invented;3I0-path neutral-counted-once N/A-to-missing-sides'], ...
                gsutEquip, gisEquip, loc, typ, cs);
            rsE2g = [rsE2g ';pickup-N/A-earth-no-residual-CT;TMS-N/A;curve-N/A'];
            push('GSUT-HV-51', 'GIS-Q0-51', loc, typ, cs, If_kA(i), NaN, NaN, NaN, NaN, NaN, NaN, NaN, ...
                'NOT DETERMINABLE FROM AVAILABLE DATA', rsE2g);
        end
    end
end
Mtrx = table(oDown', oUp', oLoc', oTyp', oCase', oIf', oId', oIu', ...
    oTd', oTu', oCd', oCu', oMg', oVd', oRs', ...
    'VariableNames', {'downstream', 'upstream', 'fault_location', 'fault_type', ...
    'caseID', 'I_fault_kA', 'I_down_A', 'I_up_A', 't_down_s', 't_up_s', ...
    'ct_down', 'ct_up', 'margin_s', 'verdict', 'reason'});
pair = strcat(oDown', '>', oUp');
Mrg = table(pair, oLoc', oTyp', oCase', oMg', oVd', oRs', ...
    'VariableNames', {'pair', 'fault_location', 'fault_type', 'caseID', ...
    'margin_s', 'verdict', 'reason'});
end

function s = resolve_device(devices, id, IminPhase, IminEarth)
%RESOLVE_DEVICE  Pickup/TMS/curve/CT per device (T6 rules + registry fields).
hit = false;
for k = 1:numel(devices)
    did = devices(k).device_id;
    if isstring(did) && isscalar(did), did = char(did); end
    if ischar(did) && strcmp(strtrim(did), id), d = devices(k); hit = true; break; end
end
if ~hit
    error('phase5_coord:devices', 'device %s not found in registry devices.', id);
end
ct = double(d.ct_ratio);
if ~(isscalar(ct) && isfinite(ct) && ct > 0)
    error('phase5_coord:ct', 'device %s needs finite ct_ratio > 0 (protection CT).', id);
end
isEF = strcmp(id, 'GEN-51N');
if ~isEF
    a = d.ansi; if isstring(a) && isscalar(a), a = char(a); end
    if ischar(a) && strcmp(strtrim(a), '51N'), isEF = true; end
end
if ~isEF
    dt2 = d.device_type; if isstring(dt2) && isscalar(dt2), dt2 = char(dt2); end
    if ischar(dt2) && strcmp(strtrim(dt2), 'ef'), isEF = true; end
end
pk = double(d.pickup_A);
if isscalar(pk) && isfinite(pk) && pk > 0
    pickupPrim = pk; psrc = 'T6-registry';
else
    if isEF
        P = phase5_pickup(d, 0, IminEarth);
    else
        rA = double(d.rated_A);
        if ~(isscalar(rA) && isfinite(rA) && rA > 0)
            error('phase5_coord:load', ['phase5_coord: %s needs finite rated_A as Iload proxy ', ...
                'for T6 fallback (NOT DETERMINABLE otherwise).'], id);
        end
        P = phase5_pickup(d, rA, IminPhase);
    end
    pickupPrim = P.setting; psrc = 'T6-fallback(Iload-proxy-rated)';
end
tm = double(d.tms);
if isscalar(tm) && isfinite(tm) && tm > 0
    TMS = tm; tsrc = 'registry';
else
    % ENGINEERING_ASSUMPTION study grading defaults (Task-8 contract).
    if strncmp(id, 'GEN', 3)
        TMS = 0.1;
    elseif strncmp(id, 'GSUT', 4)
        TMS = 0.2;
    elseif strncmp(id, 'GIS', 3)
        TMS = 0.3;
    else
        error('phase5_coord:tms', 'no TMS default for device %s (registry tms NaN).', id);
    end
    tsrc = 'ENGINEERING_ASSUMPTION-study-default';
end
cv = d.curve;
if isstring(cv) && isscalar(cv), cv = char(cv); end
if ischar(cv) && ~isempty(strtrim(cv))
    cv = upper(strtrim(cv));
    if ~any(strcmp(cv, {'SI', 'VI', 'EI', 'DT'}))
        error('phase5_coord:curve', 'device %s curve %s unsupported (need SI/VI/EI/DT).', id, cv);
    end
else
    cv = 'SI';
end
s = struct('id', id, 'ct', ct, 'pickupPrim', pickupPrim, 'psrc', psrc, ...
    'TMS', TMS, 'tsrc', tsrc, 'curve', cv);
end

function t = otime(Iprim_A, s)
%OTIME  Operating time in seconds (secondary vs secondary pickup).
%   Non-finite relay current (I0 NOT DETERMINABLE / missing residual CT) ->
%   NaN, never invented. Iprim == 0 (delta-blocked NER) -> Inf via phase5_time.
if ~isscalar(Iprim_A) || ~isreal(Iprim_A) || ~isfinite(Iprim_A) || Iprim_A < 0
    t = NaN;
    return;
end
t = phase5_time(Iprim_A / s.ct, s.pickupPrim / s.ct, s.TMS, s.curve);
end

function rs = notrip_reason2(dId, uId, IdownPrim, IupPrim, sd, su, tdown, tup, curTag)
%NOTRIP_REASON2  Below-pickup audit string for branch pairs (never forced PASS).
if nargin < 9, curTag = ''; end
if ~isfinite(tdown) && ~isfinite(tup)
    rs = sprintf(['NO-TRIP: both sides below pickup (Idown=%.6gA-primary;Is-down=%.6gA;' ...
        'Iup=%.6gA-primary;Is-up=%.6gA) - never-forced-PASS%s'], ...
        IdownPrim, sd.pickupPrim, IupPrim, su.pickupPrim, curTag);
elseif ~isfinite(tdown)
    rs = sprintf('NO-TRIP: downstream %s below pickup (I=%.6gA<Is=%.6gA primary) - never-forced-PASS%s', ...
        dId, IdownPrim, sd.pickupPrim, curTag);
else
    rs = sprintf('NO-TRIP: upstream %s below pickup (I=%.6gA<Is=%.6gA primary) - never-forced-PASS%s', ...
        uId, IupPrim, su.pickupPrim, curTag);
end
end

function v = legcol(Tsec, name, n)
%LEGCOL  Branch-leg column (kA) or NaN vector when absent (legacy synthetic).
if any(strcmp(Tsec.Properties.VariableNames, name))
    v = double(Tsec.(name)(:));
    if numel(v) ~= n, v = NaN(n, 1); end
else
    v = NaN(n, 1);
end
end

function eq = equipment_of(devices, id)
% EQUIPMENT_OF  Registry equipment label for reason stamps (fallback hardcoded).
eq = '';
for k = 1:numel(devices)
    did = devices(k).device_id;
    if isstring(did) && isscalar(did), did = char(did); end
    if ischar(did) && strcmp(strtrim(did), id) && isfield(devices, 'equipment')
        e = devices(k).equipment;
        if isstring(e) && isscalar(e), e = char(e); end
        if ischar(e) && ~isempty(strtrim(e)), eq = strtrim(e); end
        return;
    end
end
if strcmp(id, 'GIS-Q0-51'), eq = '230kV-GIS';
elseif strcmp(id, 'GSUT-HV-51'), eq = 'GSUT-HV-230kV';
end
end

function c = tocell(v)
%TOCELL  Normalize table text column (cellstr/string/char) to cellstr.
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
    error('phase5_coord:schema', 'text column must be cell/string/char.');
end
end
