function R = run_phase4_matrix(legCell, locCell, typeCell, stageCell, tag)
%RUN_PHASE4_MATRIX  Compact-OFAT full-matrix driver (spec Sec 22; NOT full factorial).
%
%   R = RUN_PHASE4_MATRIX(legCell, locCell, typeCell, stageCell, tag)
%   executes the T12 OFAT leg set at F1-F5 (F4 m=0.5 subset; full m-set
%   belongs to production runs) x LLL/LG/LL/LLG x Ikpp/ip (+Ib at t_break 0.06/steady for F3 LG/LLL
%   OUT/IN as duration anchors) and writes the four handoff-schema CSVs
%   under results/phase4_fault/<tag>/ with diary log run_log.txt.
%
%   Default invocation in test = SMALL smoke matrix (2 legs x F3 LLL/LG)
%   to keep runtime sane; the runner supports the full compact set across
%   invocations. Any 'FULL_FACTORIAL' request errors
%   error('phase4_matrix:factorial').
%
%   Leg IDs reuse the phase4_sensitivity leg table verbatim, never
%   redefined: 'base' = base-run descriptor (no variation); 'GAT-IN' =
%   case switch to LF360_GAT_IN (OUT otherwise); 'C-HIGH' etc = the T12
%   OFAT namespace (A-XoR10, A-XoR20, A-S, A-k0g1.0, A-k0g2.0, B-0.5,
%   B-1.0, C-LOW, C-HIGH, C-X1, D1, E2, F-earth, F-phase, G-open, H0, H2,
%   LAM05, LAM20, GZ0low, GZ0high and aliases, E5a, H3a, H3b, H3HV,
%   E5H3joint). Analytic/hand legs (E1/E3/D-series/D5/ZTH0-HAND) are not
%   nodal matrix legs and error 'phase4_matrix:badLeg'. Unknown leg IDs
%   error 'phase4_matrix:badLeg'. All errors are 'phase4'-prefixed.
%
%   F4 SUBSET GUARD: F4 runs use m=0.5 single section (documented); the
%   full m-set belongs to production runs, not to this driver.
%
%   Ib DEFAULT: Ib rows use t_break=0.06 s (chosen study reference time, not a measured breaker clearing time); the
%   column carries the value and the footnote carries the constant-E'
%   reference approximation note. Isteady rows carry the no-AVR note;
%   LLG rows append the single-earth note. Footnote wording mirrors
%   phase4_handoff footnoteFor verbatim.
%
%   Schema, header order, guards and kA rule are identical to
%   phase4_handoff: 25 schema columns in order; currents in kA at fault
%   voltage level (study-pu x Ibase_level, Ibase = 100/(sqrt(3)*Vlevel_kV)
%   kA; F1/F2 22 kV, F3/F4/F5 230 kV); schema check before any write
%   (never writes partial rows); t_break_s exempt from the finite check
%   (NaN unless Ib); header scan errors 'phase4_matrix:forbiddenCol'.
%
%   Contributions: per-leg columns leg_<TAG>_kA derived by introspecting
%   the legs struct of the opts-aware solve (present legs only; absent
%   legs omitted, never zero-filled). The leg split map mirrors
%   phase4_contrib verbatim (toward-fault signs, feeding sets, KCL
%   20-1/20-2/20-3) applied to the leg-specific solve, so varied legs
%   (e.g. C-HIGH) carry honest values; base legs reproduce
%   phase4_contrib exactly (re-checked at runtime by the legDrift guard
%   below on every invocation: base F3 LLL Ikpp, 1e-9 relative).
%   Per-leg ip has no table: 'ip' stage rows
%   appear in currents only (peak magnitude, RMS angle/sequences).
%
%   Bands: one row per (location x fault_type) group across legs (Ikpp
%   rows), with supplying-leg names plus INCOMPLETE flag when a single
%   leg supplies the group. CT file: through-path rows (labels only --
%   no duties, no switching/arc model) with candidate ratios never
%   selected. Q0 is a breaker connection; Q1/Q2/Q9 are disconnector
%   connections; tags are labels only.
%
%   No forbidden columns are written. No substation names. No compliance
%   claims.
%
%   Output struct fields: dir, nCurr, nCon, nBand, nCt, secs.

t0run = tic;
if nargin < 5
    error('phase4_matrix:args', 'Five inputs required: legCell, locCell, typeCell, stageCell, tag.');
end
legs = asCell(legCell, 'legCell');
locs = asCell(locCell, 'locCell');
types = asCell(typeCell, 'typeCell');
stages = asCell(stageCell, 'stageCell');
if isstring(tag), tag = char(tag); end
if ~(ischar(tag) && isrow(tag) && ~isempty(tag))
    error('phase4_matrix:badTag', 'tag must be a non-empty char rowvec (run subdirectory name).');
end
if any(tag == '/' | tag == '\' | tag == ':')
    error('phase4_matrix:badTag', 'tag must not contain path separators.');
end
if isempty(legs) || isempty(locs) || isempty(types) || isempty(stages)
    error('phase4_matrix:badInput', 'legCell, locCell, typeCell and stageCell must be non-empty.');
end
for k = 1:numel(legs)
    if strcmp(legs{k}, 'FULL_FACTORIAL')
        error('phase4_matrix:factorial', 'Full-factorial combinations are forbidden; OFAT legs only.');
    end
end
for k = 1:numel(locs)
    if strcmp(locs{k}, 'FULL_FACTORIAL')
        error('phase4_matrix:factorial', 'Full-factorial combinations are forbidden; OFAT legs only.');
    end
end
for k = 1:numel(types)
    if strcmp(types{k}, 'FULL_FACTORIAL')
        error('phase4_matrix:factorial', 'Full-factorial combinations are forbidden; OFAT legs only.');
    end
end
for k = 1:numel(stages)
    if strcmp(stages{k}, 'FULL_FACTORIAL')
        error('phase4_matrix:factorial', 'Full-factorial combinations are forbidden; OFAT legs only.');
    end
end
% normalize 'steady' alias to solver stage name 'Isteady'
for k = 1:numel(stages)
    if strcmp(stages{k}, 'steady')
        stages{k} = 'Isteady';
    end
end
for k = 1:numel(locs)
    if ~any(strcmp(locs{k}, {'F1','F2','F3','F4','F5'}))
        error('phase4_matrix:badLoc', 'Unknown fault location ''%s'': use F1/F2/F3/F4/F5.', locs{k});
    end
end
for k = 1:numel(types)
    if ~any(strcmp(types{k}, {'LLL','LG','LL','LLG'}))
        error('phase4_matrix:badType', 'Unknown fault type ''%s'': use LLL/LG/LL/LLG.', types{k});
    end
end
for k = 1:numel(stages)
    if ~any(strcmp(stages{k}, {'Ikpp','ip','Ib','Isteady'}))
        error('phase4_matrix:badStage', 'Unknown stage ''%s'': use Ikpp/ip/Ib/Isteady.', stages{k});
    end
end
for k = 1:numel(legs)
    assertKnownLeg(legs{k});
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
logFile = fullfile(dirPath, 'run_log.txt');
if exist(logFile, 'file') == 2
    delete(logFile);
end
diary(logFile);
fprintf('run_phase4_matrix %s: legs=%d locs=%d types=%d stages=%d\n', ...
    tag, numel(legs), numel(locs), numel(types), numel(stages));
fprintf('  legs: %s\n', strjoin(legs, ','));
fprintf('  locs: %s  types: %s  stages: %s\n', strjoin(locs, ','), ...
    strjoin(types, ','), strjoin(stages, ','));
fprintf('  SUBSET GUARD: F4 runs use m=0.5 single section; full m-set belongs to production runs.\n');
fprintf('  Ib DEFAULT: t_break=0.06 s chosen study reference time (not a measured breaker clearing time).\n');

schemaHeaders = {'fault_type','location','m','caseID','grid_dataset','XoR_P', ...
    'zero_band','k0g','XdRole','NER_variant','GAT_variant','ZfMode','Zf_ohm', ...
    'coupler','stage','unit','base','Irms_kA','Iang_deg','Iseq0_kA','Iseq1_kA', ...
    'Iseq2_kA','r_kappa_ip','t_break_s','footnote'};
canonTags = {'GEN','GSUT_LV','GSUT_HV','UAT','GAT_HV','GAT_LV', ...
    'LINE_total','LINE_B1','LINE_B2','GRID','NER_earth'};

FL = deriveFL();

% ---- run accumulation ----
curRows = {};   % cell rows for currents table (25 schema cols)
conRows = {};   % cell rows for contributions schema part
conLegs = {};   % per-row legs struct (|Ia| kA toward fault)
conKcl = [];    % per-row [seq ph earth]
ctRows = {};    % cell rows for CT table (12 cols)
% band collector: key loc|type -> list of (Ik, leg)
bandMap = struct('key', {}, 'loc', {}, 'type', {}, 'Ik', {}, 'leg', {});
try
% loops: legs outermost (OFAT), then locs, types, stages
for li = 1:numel(legs)
    legID = legs{li};
    [caseID, ds, XoR_P, opts, ZfModeLeg, zband] = legDesc(legID);
    for oi = 1:numel(locs)
        loc = locs{oi};
        if any(strcmp(loc, {'F1','F2'})), Vlevel = 22; else, Vlevel = 230; end
        Ibase = 100/(sqrt(3)*Vlevel);
        Zf_ohm = zfFor(ZfModeLeg, loc);
        for ti = 1:numel(types)
            type = types{ti};
            for si = 1:numel(stages)
                stageLabel = stages{si};
                if strcmp(stageLabel, 'ip'), solverStage = 'Ikpp';
                elseif strcmp(stageLabel, 'Ib'), solverStage = 'Ib';
                elseif strcmp(stageLabel, 'Isteady'), solverStage = 'Isteady';
                else, solverStage = 'Ikpp';
                end
                if strcmp(stageLabel, 'Ib'), tbrk = 0.06; else, tbrk = NaN; end
                F = phase4_solve(caseID, ds, XoR_P, loc, type, solverStage, Zf_ohm, opts);
                Ifault = govCurrent(F, type);
                if strcmp(stageLabel, 'ip')
                    Irms = F.ip*Ibase;
                else
                    Irms = abs(Ifault)*Ibase;
                end
                Ang = angle(Ifault)*180/pi;
                s0 = abs(F.I0)*Ibase; s1 = abs(F.I1)*Ibase; s2 = abs(F.I2)*Ibase;
                ipkA = F.ip*Ibase;
                if strcmp(stageLabel, 'Ib'), tcol = 0.06; else, tcol = NaN; end
                fn = footnoteFor(stageLabel, type, ZfModeLeg, F, tbrk);
                mVal = 0.5;
                curRows(end+1,:) = {type, loc, mVal, caseID, ds, XoR_P, ...
                    zband, opts.k0g, opts.XdRole, opts.ner, opts.gatLeg, ...
                    ZfModeLeg, Zf_ohm, opts.coupler, stageLabel, 'kA', ...
                    '100MVA', Irms, Ang, s0, s1, s2, ipkA, tcol, fn};
                if ~strcmp(stageLabel, 'ip')
                    % contributions from the opts-aware solve (map mirrors
                    % phase4_contrib verbatim; absent legs omitted below).
                    [legS, kclS, kclP, kclE, tags] = splitLegs(F, loc, type);
                    conRows(end+1,:) = {type, loc, mVal, caseID, ds, XoR_P, ...
                        zband, opts.k0g, opts.XdRole, opts.ner, opts.gatLeg, ...
                        ZfModeLeg, Zf_ohm, opts.coupler, stageLabel, 'kA', ...
                        '100MVA', Irms, Ang, s0, s1, s2, ipkA, tcol, fn};
                    legK = struct();
                    lfn = fieldnames(legS);
                    for q = 1:numel(lfn)
                        legK.(lfn{q}) = abs(legS.(lfn{q}).Ia)*Ibase;
                    end
                    conLegs{end+1} = legK;
                    conKcl(end+1,:) = [kclS, kclP, kclE];
                    % band collector over Ikpp rows only (peak/others excluded)
                    if strcmp(stageLabel, 'Ikpp')
                        key = [loc '|' type];
                        bi = find(strcmp({bandMap.key}, key), 1);
                        if isempty(bi)
                            bandMap(end+1) = struct('key', key, 'loc', loc, ...
                                'type', type, 'Ik', Irms, 'leg', legID);
                        else
                            bandMap(bi).Ik(end+1) = Irms;
                            if ischar(bandMap(bi).leg)
                                bandMap(bi).leg = {bandMap(bi).leg, legID};
                            else
                                bandMap(bi).leg{end+1} = legID;
                            end
                        end
                    end
                    % CT rows: 5 through-paths x RMS + borrowed-shape PEAK
                    ctPaths = {'GEN_Q','GSUT_HV','GSUT_LV','LINE_Q9','GRID_Q'};
                    for qi = 1:numel(ctPaths)
                        ptag = ctPaths{qi};
                        ph = tags.(ptag);
                        rmskA = abs(ph.Ia)*Ibase;
                        peakkA = rmskA*sqrt(2)*F.kappa;
                        flA = flFor(ptag, FL);
                        ctRows(end+1,:) = {type, loc, caseID, ptag, stageLabel, ...
                            'RMS', rmskA, flA, rmskA*1000/1600, rmskA*1000/800, ...
                            rmskA*1000/400, ...
                            'through-current RMS; ratios are candidates, never selected'};
                        ctRows(end+1,:) = {type, loc, caseID, ptag, 'ip', ...
                            'PEAK', peakkA, flA, peakkA*1000/1600, peakkA*1000/800, ...
                            peakkA*1000/400, ...
                            sprintf('borrowed-shape peak estimate; r=%.4f kappa=%.5f; ratios are candidates, never selected', F.r, F.kappa)};
                    end
                end
            end
        end
    end
end

% ---- mirror-vs-contrib runtime guard (base spec only, cheap) ----
% Independent cross-check: phase4_contrib for the base run spec (F3 LLL
% OUT P15 bolted Ikpp) vs the matrix mirror path (splitLegs on the
% base-opts solve). Every shared leg |Ia| must agree within 1e-9
% relative, else error('phase4_matrix:legDrift'). Guards future
% contrib-map drift.
[gdID, gdDs, gdXoR, gdOpts, gdZfM, ~] = legDesc('base');
gdZf = zfFor(gdZfM, 'F3');
gdIbase = 100/(sqrt(3)*230);
GDF = phase4_solve(gdID, gdDs, gdXoR, 'F3', 'LLL', 'Ikpp', gdZf, gdOpts);
[gdLegS, ~, ~, ~, ~] = splitLegs(GDF, 'F3', 'LLL');
GDC = phase4_contrib(gdID, gdDs, gdXoR, 'F3', 'LLL', 'Ikpp', [], 'bolted');
gdTags = fieldnames(gdLegS);
gdWorst = 0; gdN = 0;
for q = 1:numel(gdTags)
    if isfield(GDC.legs, gdTags{q})
        gdVm = abs(gdLegS.(gdTags{q}).Ia)*gdIbase;
        gdVc = abs(GDC.legs.(gdTags{q}).Ia)*gdIbase;
        gdDd = abs(gdVm - gdVc)/max([abs(gdVc), 1e-30]);
        gdWorst = max(gdWorst, gdDd);
        gdN = gdN + 1;
        if ~(gdDd <= 1e-9)
            error('phase4_matrix:legDrift', 'Mirror leg %s drifts from phase4_contrib (rel %.3g).', gdTags{q}, gdDd);
        end
    end
end
fprintf('legDrift guard: base F3 LLL Ikpp mirror matches phase4_contrib over %d shared legs (worst rel %.3g).\n', gdN, gdWorst);

% ---- dynamic leg columns: union over matrix contrib rows, canonical order ----
presentTags = {};
for q = 1:numel(conLegs)
    presentTags = union(presentTags, fieldnames(conLegs{q}));
end
legTags = canonTags(ismember(canonTags, presentTags));
legHeaders = strcat('leg_', legTags, '_kA');
nCon = size(conRows, 1);
legMat = NaN(nCon, numel(legTags));
for q = 1:nCon
    for j = 1:numel(legTags)
        if isfield(conLegs{q}, legTags{j})
            legMat(q, j) = conLegs{q}.(legTags{j});
        else
            legMat(q, j) = NaN;
        end
    end
end

% ---- tables ----
Tcur = cell2table(curRows, 'VariableNames', schemaHeaders);
if ~isequal(Tcur.Properties.VariableNames, schemaHeaders) || height(Tcur) == 0
    error('phase4_matrix:schema', 'Currents table must carry ALL schema columns in order.');
end
for k = 1:height(Tcur)
    if isempty(Tcur.fault_type{k}) || isempty(Tcur.location{k}) || isempty(Tcur.caseID{k}) ...
            || isempty(Tcur.stage{k}) || isempty(Tcur.footnote{k})
        error('phase4_matrix:schema', 'Every row must carry ALL schema columns (row %d incomplete).', k);
    end
end
magVals = [Tcur.Irms_kA, Tcur.Iseq0_kA, Tcur.Iseq1_kA, Tcur.Iseq2_kA, Tcur.r_kappa_ip];
if any(~isfinite(magVals(:)))
    error('phase4_matrix:badNumeric', 'Fault-currents magnitude columns must be finite (t_break_s exempt).');
end
assertNoForbidden(Tcur.Properties.VariableNames);

conHeaders = [schemaHeaders, legHeaders, {'kcl_seq','kcl_ph','kcl_earth'}];
Tschema = cell2table(conRows, 'VariableNames', schemaHeaders);
Tlegs = array2table(legMat, 'VariableNames', legHeaders);
Tkcl = array2table(conKcl, 'VariableNames', {'kcl_seq','kcl_ph','kcl_earth'});
Tcon = [Tschema, Tlegs, Tkcl];
assertNoForbidden(Tcon.Properties.VariableNames);

% ---- bands ----
bandHeaders = {'group','fault_type','min_Ik_kA','max_Ik_kA','min_leg','max_leg', ...
    'mid_Ik_kA','mid_leg','incomplete','note'};
if isempty(bandMap)
    Brow = cell(0, numel(bandHeaders));
else
    Brow = cell(numel(bandMap), numel(bandHeaders));
    for b = 1:numel(bandMap)
        Iks = bandMap(b).Ik;
        if ischar(bandMap(b).leg), lgs = {bandMap(b).leg}; else, lgs = bandMap(b).leg; end
        [mn, imn] = min(Iks); [mx, imx] = max(Iks);
        if numel(Iks) <= 1
            inc = 1;
            note = 'point without band: single-leg group, no spread band';
        else
            inc = 0;
            note = 'band from OFAT leg spread across matrix legs';
        end
        % mid = base-leg value when present else first leg
        ib = find(strcmp(lgs, 'base'), 1);
        if isempty(ib), ib = 1; end
        Brow(b,:) = {[bandMap(b).loc '_' bandMap(b).type '_' tag], bandMap(b).type, ...
            mn, mx, lgs{imn}, lgs{imx}, Iks(ib), lgs{ib}, inc, note};
    end
end
Tband = cell2table(Brow, 'VariableNames', bandHeaders);
assertNoForbidden(Tband.Properties.VariableNames);

% ---- CT ----
ctHeaders = {'fault_type','location','caseID','through_path','stage','kind', ...
    'primary_kA','FL_anchor_kA','ratio_1600_1_A','ratio_800_1_A','ratio_400_1_A','footnote'};
Tct = cell2table(ctRows, 'VariableNames', ctHeaders);
assertNoForbidden(Tct.Properties.VariableNames);

% ---- writes (only after all checks pass) ----
writetable(Tcur, fullfile(dirPath, 'phase4_fault_currents.csv'));
writetable(Tcon, fullfile(dirPath, 'phase4_contributions.csv'));
writetable(Tband, fullfile(dirPath, 'phase4_bands.csv'));
writetable(Tct, fullfile(dirPath, 'phase4_ct_data.csv'));

if hasForbidden(Tcur.Properties.VariableNames) ...
        || hasForbidden(Tcon.Properties.VariableNames) ...
        || hasForbidden(Tband.Properties.VariableNames) ...
        || hasForbidden(Tct.Properties.VariableNames)
    error('phase4_matrix:forbiddenCol', 'Forbidden column pattern detected in headers.');
end

secs = toc(t0run);
fprintf('run_phase4_matrix %s: %d currents rows, %d contrib rows, %d band rows, %d ct rows in %s (%.1f s)\n', ...
    tag, height(Tcur), height(Tcon), height(Tband), height(Tct), dirPath, secs);
diary off;
R = struct('dir', dirPath, 'nCurr', height(Tcur), 'nCon', height(Tcon), ...
    'nBand', height(Tband), 'nCt', height(Tct), 'secs', secs);
catch ME
    try, diary off; end
    rethrow(ME);
end
end

% =====================================================================
function c = asCell(v, nm)
if isstring(v), v = cellstr(v); end
if ischar(v) && isrow(v), v = {v}; end
if ~iscell(v)
    error('phase4_matrix:badInput', '%s must be a cell array of string scalars.', nm);
end
c = cell(1, numel(v));
for i = 1:numel(v)
    li = v{i};
    if isstring(li), li = char(li); end
    if ~(ischar(li) && isrow(li) && ~isempty(li))
        error('phase4_matrix:badInput', '%s entries must be non-empty string scalars.', nm);
    end
    c{i} = li;
end
end

function assertKnownLeg(legID)
%ASSERTKNOWNLEG  Leg namespace reuse (values in legDesc mirror
%   phase4_sensitivity runLeg verbatim, never redefined).
switch legID
    case {'base','GAT-IN','A-XoR10','A-XoR20','A-S','A-k0g1.0','A-k0g2.0', ...
            'B-0.5','B-1.0','C-LOW','C-HIGH','C-X1','D1','E2','F-earth', ...
            'F-phase','G-open','G-OPEN','H0','H2','LAM05','LAM05_','LAM05b', ...
            'LAM20','LAM20_','GZ0low','GAT-Z0-9.99','GZ0high','GAT-Z0-11.61', ...
            'E5a','H3a','H3b','H3HV','E5H3joint'}
        return;
    otherwise
        error('phase4_matrix:badLeg', 'Unknown leg ID ''%s''.', legID);
end
end

function [caseID, ds, XoR_P, opts, ZfMode, zband] = legDesc(legID)
%LEGDESC  Leg ID to solve descriptor. Deltas mirror phase4_sensitivity
%   runLeg verbatim (base-identical defaults; each leg varies ONLY the
%   named quantity; E5H3joint excepted as documented there).
opts = struct('m', 0.5, 'gatLeg', 'H1', 'coupler', 'closed', ...
    'kR', 3.5, 'kX', 2.75, 'kB', 0.725, 'k0g', 1.5, ...
    'ner', 'primary', 'XdRole', 'sat', 'lambda_T', 1.0, ...
    'lineScale', 1.0, 'gatZ0sel', 'nominal');
opts.ovr = struct('Rloading_tolfrac', 0, 'ZN_UAT_scale', 1, ...
    'ZN_GATLV_scale', 1, 'ZN_GATHV_ohm', 0);
caseID = 'LF360_GAT_OUT'; ds = 'P'; XoR_P = 15; ZfMode = 'bolted';
zband = 'MID';
switch legID
    case 'base'
    case 'GAT-IN', caseID = 'LF360_GAT_IN';
    case 'A-XoR10', XoR_P = 10;
    case 'A-XoR20', XoR_P = 20;
    case 'A-S', ds = 'S';
    case 'A-k0g1.0', opts.k0g = 1.0;
    case 'A-k0g2.0', opts.k0g = 2.0;
    case 'B-0.5', opts.lineScale = 0.71428571;
    case 'B-1.0', opts.lineScale = 1.42857143;
    case 'C-LOW', opts.kR = 2.0; opts.kX = 2.0; opts.kB = 0.60; zband = 'LOW';
    case 'C-HIGH', opts.kR = 5.0; opts.kX = 3.5; opts.kB = 0.85; zband = 'HIGH';
    case 'C-X1', opts.kR = 5.0; opts.kX = 2.0; opts.kB = 0.725;
    case 'D1', opts.XdRole = 'unsat';
    case 'E2', opts.ner = 'quoted60';
    case 'F-earth', ZfMode = 'earth';
    case 'F-phase', ZfMode = 'phase';
    case {'G-open','G-OPEN'}, opts.coupler = 'open';
    case 'H0', opts.gatLeg = 'H0';
    case 'H2', opts.gatLeg = 'H2';
    case {'LAM05','LAM05_','LAM05b'}, opts.lambda_T = 0.5;
    case {'LAM20','LAM20_'}, opts.lambda_T = 2.0;
    case {'GZ0low','GAT-Z0-9.99'}, opts.gatZ0sel = 'low';
    case {'GZ0high','GAT-Z0-11.61'}, opts.gatZ0sel = 'high';
    case 'E5a', opts.ovr.ZN_UAT_scale = 1/3;
    case 'H3a', opts.ovr.ZN_GATLV_scale = 2.0;
    case 'H3b', opts.ovr.ZN_GATLV_scale = 0.5;
    case 'H3HV', opts.ovr.ZN_GATHV_ohm = 1.0;
    case 'E5H3joint'
        caseID = 'LF360_GAT_IN';
        opts.ovr.ZN_UAT_scale = 1/3; opts.ovr.ZN_GATLV_scale = 2.0;
    otherwise
        error('phase4_matrix:badLeg', 'Unknown leg ID ''%s''.', legID);
end
end

function z = zfFor(zfmode, loc)
if any(strcmp(loc, {'F1','F2'})), zb = 4.84; else, zb = 529; end
switch zfmode
    case 'bolted', z = 0;
    case 'earth', z = 0.01*zb;
    case 'phase', z = 0.002*zb;
    otherwise, error('phase4_matrix:badZf', 'Unknown ZfMode.');
end
end

function Ifault = govCurrent(F, type)
%GOVCURRENT  Governing fault current (phase4_stages convention).
if strcmp(type, 'LG')
    Ifault = F.Ia;
elseif strcmp(type, 'LL') || strcmp(type, 'LLG')
    if abs(F.Ib) >= abs(F.Ic)
        Ifault = F.Ib;
    else
        Ifault = F.Ic;
    end
else
    Ifault = F.I1;
end
end

function fn = footnoteFor(stage, type, ZfMode, F, tbrk)
%FOOTNOTEFor  Mirrors phase4_handoff footnoteFor verbatim.
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

function [legs, kcl_seq, kcl_ph, kcl_earth, tags] = splitLegs(F, loc, type)
%SPLITLEGS  Per-leg phasors + KCL + tags. Map mirrors phase4_contrib
%   verbatim (toward-fault signs, feeding sets, 20-1/20-2/20-3); applied
%   here to the leg-specific (opts-aware) solve.
B = F.branch;
isLLL = strcmp(type, 'LLL');
isLG = strcmp(type, 'LG');
isLL = strcmp(type, 'LL');
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
    if hasRow(B, 'LINE_S')
        sRow = getB(B, 'LINE_S'); rRow = getB(B, 'LINE_R');
        legs.LINE_B1 = mkLeg(+sRow.I1, +sRow.I2, +sRow.I0);
        legs.LINE_B2 = mkLeg(-rRow.I1, -rRow.I2, -rRow.I0);
        legs.LINE_total = mkLeg(legs.LINE_B1.I1 + legs.LINE_B2.I1, ...
            legs.LINE_B1.I2 + legs.LINE_B2.I2, legs.LINE_B1.I0 + legs.LINE_B2.I0);
    else
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
if isLG || strcmp(type, 'LLG')
    ner = getB(B, 'NER');
    legs.NER_earth = mkLeg(0, 0, +ner.I0);
end
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
D = max([abs(F.I1), abs(F.I2), abs(F.I0), 1e-30]);
s1 = sumLeg(legs, feed12, 'I1'); s2 = sumLeg(legs, feed12, 'I2'); s0 = sumLeg(legs, feed0, 'I0');
kcl_seq = max([abs(s1 - F.I1)/D, abs(s2 - F.I2)/D, abs(s0 - F.I0)/D]);
Dp = max([abs(F.Ia), abs(F.Ib), abs(F.Ic), 1e-30]);
pa = sumLeg(legs, feed12, 'Ia'); pb = sumLeg(legs, feed12, 'Ib'); pc = sumLeg(legs, feed12, 'Ic');
kcl_ph = max([abs(pa - F.Ia)/Dp, abs(pb - F.Ib)/Dp, abs(pc - F.Ic)/Dp]);
if isLL || isLLL
    kcl_earth = NaN;
else
    kcl_earth = abs(3*s0 - 3*F.I0)/max(abs(3*F.I0), 1e-30);
end
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
end

function r = getB(B, name)
for k = 1:numel(B)
    if strcmp(B(k).name, name)
        r = B(k);
        return;
    end
end
error('phase4_matrix:missingBranch', 'Branch row ''%s'' missing from solver output.', name);
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
    error('phase4_matrix:badPath', 'Unknown through-path ''%s''.', ptag);
end
end

function FL = deriveFL()
%DERIVEFL  Mirrors phase4_handoff deriveFL verbatim (same CSVs, same form).
root = ashuganj_root();
Ts = readtable(fullfile(root, 'results', 'phase3_loadflow', 'phase3_system_summary.csv'));
js = find(string(Ts.Case_ID) == string('LF360_GAT_OUT'), 1);
if isempty(js)
    error('phase4_matrix:missingRow', 'No system-summary row for LF360_GAT_OUT.');
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
    error('phase4_matrix:forbiddenCol', 'Forbidden column pattern detected in headers.');
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
