function R = run_phase4_production(tag, varargin)
%RUN_PHASE4_PRODUCTION  Immutable production archive C9/C10: full matrix + manifest + hashes.
%
%   R = RUN_PHASE4_PRODUCTION(tag) drives RUN_PHASE4_MATRIX over the compact
%   OFAT production run list (base backbone F1-F5 x LLL/LG/LL/LLG x OUT/IN
%   Ikpp plus ip rows; 27-leg OFAT at F3/F4/F5 LG/LLG; Ib/Isteady anchors
%   at F3 LG/LLL OUT/IN with t_break 0.06 s) plus an F4 m-section block via
%   PHASE4_SOLVE base-opts solves, and writes under
%   results/phase4_fault/<tag>/:
%     phase4_fault_currents.csv / phase4_contributions.csv /
%     phase4_bands.csv / phase4_ct_data.csv (merged matrix segments, schema
%     identical to the handoff writer path),
%     analytic_bounds.csv (E1/E3/D4-joint/D2/D3/D5 recomputed from the
%     PHASE4_SENSITIVITY analytic locals; method EXACT/APPROXIMATION),
%     manifest.json (timestamp, base descriptor, leg/loc/type/case/stage
%     list, row counts, code SHA-256 of every matlab/phase4/*.m, adopted
%     tolerances, validation reference),
%     sha256.txt (SHA-256 of the 4 CSVs + manifest + analytic bounds + run log),
%     run_log.txt (solver settings, per-segment/leg completion, totals).
%
%   R = RUN_PHASE4_PRODUCTION(tag, 'overwrite', true) re-runs into an
%   existing tag directory. Without the flag, an existing tag directory
%   errors error('phase4_production:exists'). Default tag 'production'.
%
%   Name-value options (test scoping; defaults = full production list):
%     'legs', 'locs', 'types', 'stages' (cell string arrays),
%     'mVals' (default [0 0.25 0.75 1.0]; m=0.5 is covered by matrix rows),
%     'skipValidate' (default false), 'analyticLegs' (default the 7 bounds).
%
%   Scope rules (compact OFAT, never full factorial):
%     - backbone segment: {base,GAT-IN} x all locs x all types x {Ikpp,ip}.
%     - OFAT segment: other legs x {F3,F4,F5} x {LG,LLG} x {Ikpp,ip}.
%     - anchor segment: {base,GAT-IN} x {F3} x {LG,LLL} x {Ib,Isteady}.
%     - F4 m-section: base-opts PHASE4_SOLVE rows (currents table only),
%       m in mVals x requested types x OUT/IN cases present.
%   Per-leg IN-case OFAT is not expressible via run_phase4_matrix (case is
%   fixed per leg there; only the backbone and E5H3joint carry IN scope);
%   this is recorded in the manifest notes. All errors 'phase4'-prefixed.
%
%   No relay/TMS/grading/duty/verdict content; no substation names; no
%   compliance claims.

t0run = tic;
if nargin < 1 || isempty(tag)
    tag = 'production';
end
if isstring(tag), tag = char(tag); end
if ~(ischar(tag) && isrow(tag) && ~isempty(tag))
    error('phase4_production:badTag', 'tag must be a non-empty char rowvec (run subdirectory name).');
end
if any(tag == '/' | tag == '\' | tag == ':')
    error('phase4_production:badTag', 'tag must not contain path separators.');
end

legsFull = {'base', 'GAT-IN', 'A-XoR10', 'A-XoR20', 'A-S', 'A-k0g1.0', 'A-k0g2.0', ...
    'B-0.5', 'B-1.0', 'C-LOW', 'C-HIGH', 'C-X1', 'D1', 'E2', 'F-earth', ...
    'F-phase', 'G-open', 'H0', 'H2', 'LAM05', 'LAM20', 'GZ0low', 'GZ0high', ...
    'E5a', 'H3a', 'H3b', 'H3HV', 'E5H3joint'};
locsFull = {'F1', 'F2', 'F3', 'F4', 'F5'};
typesFull = {'LLL', 'LG', 'LL', 'LLG'};
stagesFull = {'Ikpp', 'ip', 'Ib', 'Isteady'};
mValsDef = [0, 0.25, 0.75, 1.0];
analyticDef = {'E1', 'E3', 'D4', 'D4+E-JOINT', 'D2', 'D3', 'D5'};

overwrite = false;
legs = legsFull; locs = locsFull; types = typesFull; stages = stagesFull;
mVals = mValsDef; skipValidate = false; analyticLegs = analyticDef;
for k = 1:2:numel(varargin)
    nm = varargin{k};
    if isstring(nm), nm = char(nm); end
    if k + 1 > numel(varargin)
        error('phase4_production:args', 'Name-value options need a value.');
    end
    vv = varargin{k + 1};
    switch lower(nm)
        case 'overwrite'
            overwrite = logical(vv);
        case 'legs'
            legs = asCell(vv, 'legs');
        case 'locs'
            locs = asCell(vv, 'locs');
        case 'types'
            types = asCell(vv, 'types');
        case 'stages'
            stages = asCell(vv, 'stages');
        case 'mvals'
            mVals = vv(:)';
            if ~isnumeric(mVals) || any(~isfinite(mVals)) || any(mVals < 0 | mVals > 1)
                error('phase4_production:badM', 'mVals must be finite values in [0,1].');
            end
        case 'skipvalidate'
            skipValidate = logical(vv);
        case 'analyticlegs'
            analyticLegs = asCell(vv, 'analyticLegs');
        otherwise
            error('phase4_production:args', 'Unknown option ''%s''.', nm);
    end
end
for k = 1:numel(types)
    if ~any(strcmp(types{k}, typesFull))
        error('phase4_production:badType', 'Unknown fault type ''%s''.', types{k});
    end
end
for k = 1:numel(locs)
    if ~any(strcmp(locs{k}, locsFull))
        error('phase4_production:badLoc', 'Unknown fault location ''%s''.', locs{k});
    end
end
for k = 1:numel(stages)
    if ~any(strcmp(stages{k}, stagesFull))
        error('phase4_production:badStage', 'Unknown stage ''%s''.', stages{k});
    end
end

root = ashuganj_root();
dirPath = fullfile(root, 'results', 'phase4_fault', tag);
if exist(dirPath, 'dir') == 7 && ~overwrite
    error('phase4_production:exists', ...
        'Tag directory %s exists; re-run with ''overwrite'', true.', dirPath);
end
if exist(dirPath, 'dir') ~= 7
    parentDir = fullfile(root, 'results', 'phase4_fault');
    if exist(parentDir, 'dir') ~= 7
        mkdir(fullfile(root, 'results'), 'phase4_fault');
    end
    mkdir(parentDir, tag);
end

logL = {};
logL{end+1} = sprintf('run_phase4_production %s started %s (local)', tag, datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
logL{end+1} = 'solver settings: ds=P XoR_P=15 k0g=1.5 kR=3.5 kX=2.75 kB=0.725 XdRole=sat gatLeg=H1 lambda_T=1.0 gatZ0sel=nominal ner=primary lineScale=1.0 ZfMode=bolted coupler=closed (base; OFAT legs vary one factor per legDesc)';
logL{end+1} = sprintf('scope legs: %s', strjoin(legs, ','));
logL{end+1} = sprintf('scope locs: %s  types: %s  stages: %s', strjoin(locs, ','), strjoin(types, ','), strjoin(stages, ','));
logL{end+1} = 'Ib DEFAULT: t_break=0.06 s chosen study reference time (not a measured breaker clearing time).';
logL{end+1} = 'F4 SUBSET GUARD: matrix rows use m=0.5 single section; full m-set block appended to currents table.';

% ---- partition into matrix segments ----
bbLegs = legs(ismember(legs, {'base', 'GAT-IN'}));
ofatLegs = legs(~ismember(legs, {'base', 'GAT-IN'}));
pkStages = stages(ismember(stages, {'Ikpp', 'ip'}));
segs = struct('name', {}, 'legs', {}, 'locs', {}, 'types', {}, 'stages', {});
if ~isempty(bbLegs) && ~isempty(locs) && ~isempty(types) && ~isempty(pkStages)
    segs(end+1) = struct('name', 'backbone', 'legs', {bbLegs}, 'locs', {locs}, 'types', {types}, 'stages', {pkStages});
end
ofatLocs = locs(ismember(locs, {'F3', 'F4', 'F5'}));
ofatTypes = types(ismember(types, {'LG', 'LLG'}));
if ~isempty(ofatLegs) && ~isempty(ofatLocs) && ~isempty(ofatTypes) && ~isempty(pkStages)
    segs(end+1) = struct('name', 'ofat', 'legs', {ofatLegs}, 'locs', {ofatLocs}, 'types', {ofatTypes}, 'stages', {pkStages});
end
anLocs = locs(ismember(locs, {'F3'}));
anTypes = types(ismember(types, {'LG', 'LLL'}));
anStages = stages(ismember(stages, {'Ib', 'Isteady'}));
if ~isempty(bbLegs) && ~isempty(anLocs) && ~isempty(anTypes) && ~isempty(anStages)
    segs(end+1) = struct('name', 'anchors', 'legs', {bbLegs}, 'locs', {anLocs}, 'types', {anTypes}, 'stages', {anStages});
end
doM = any(strcmp(locs, 'F4')) && any(strcmp(stages, 'Ikpp')) && ~isempty(bbLegs) && ~isempty(mVals);
if isempty(segs) && ~doM
    error('phase4_production:emptyScope', 'Scoped legs/locs/types/stages select no backbone, OFAT, anchor or F4 m-section rows.');
end

schemaHeaders = {'fault_type', 'location', 'm', 'caseID', 'grid_dataset', 'XoR_P', ...
    'zero_band', 'k0g', 'XdRole', 'NER_variant', 'GAT_variant', 'ZfMode', 'Zf_ohm', ...
    'coupler', 'stage', 'unit', 'base', 'Irms_kA', 'Iang_deg', 'Iseq0_kA', 'Iseq1_kA', ...
    'Iseq2_kA', 'r_kappa_ip', 't_break_s', 'footnote'};
kclHeaders = {'kcl_seq', 'kcl_ph', 'kcl_earth'};
canonTags = {'GEN', 'GSUT_LV', 'GSUT_HV', 'UAT', 'GAT_HV', 'GAT_LV', ...
    'LINE_total', 'LINE_B1', 'LINE_B2', 'GRID', 'NER_earth'};
ctHeaders = {'fault_type', 'location', 'caseID', 'through_path', 'stage', 'kind', ...
    'primary_kA', 'FL_anchor_kA', 'ratio_1600_1_A', 'ratio_800_1_A', 'ratio_400_1_A', 'footnote'};
bandHeaders = {'group', 'fault_type', 'min_Ik_kA', 'max_Ik_kA', 'min_leg', 'max_leg', ...
    'mid_Ik_kA', 'mid_leg', 'incomplete', 'note'};

% ---- run matrix segments into scratch tags, read back ----
segTabs = struct('name', {}, 'nSolves', {}, 'secs', {}, 'Tcur', {}, 'Tcon', {}, 'Tband', {}, 'Tct', {});
for s = 1:numel(segs)
    segTag = sprintf('%s_seg%d', tag, s);
    segDir = fullfile(root, 'results', 'phase4_fault', segTag);
    if exist(segDir, 'dir') == 7
        rmdir(segDir, 's');
    end
    nSol = numel(segs(s).legs) * numel(segs(s).locs) * numel(segs(s).types) * numel(segs(s).stages);
    t0s = tic;
    run_phase4_matrix(segs(s).legs, segs(s).locs, segs(s).types, segs(s).stages, segTag);
    sSecs = toc(t0s);
    Tc = readtable(fullfile(segDir, 'phase4_fault_currents.csv'));
    Tk = readtable(fullfile(segDir, 'phase4_contributions.csv'));
    Tb = readtable(fullfile(segDir, 'phase4_bands.csv'));
    Tg = readtable(fullfile(segDir, 'phase4_ct_data.csv'));
    if ~isequal(Tc.Properties.VariableNames, schemaHeaders)
        error('phase4_production:schema', 'Segment %s currents headers differ from schema.', segs(s).name);
    end
    if ~isequal(Tg.Properties.VariableNames, ctHeaders)
        error('phase4_production:schema', 'Segment %s ct headers differ from schema.', segs(s).name);
    end
    segTabs(end+1) = struct('name', segs(s).name, 'nSolves', nSol, 'secs', sSecs, ...
        'Tcur', Tc, 'Tcon', Tk, 'Tband', Tb, 'Tct', Tg);
    logL{end+1} = sprintf('segment %s (%s): legs=%d locs=%d types=%d stages=%d solves=%d secs=%.1f rows cur=%d con=%d band=%d ct=%d', ...
        segs(s).name, segTag, numel(segs(s).legs), numel(segs(s).locs), numel(segs(s).types), numel(segs(s).stages), ...
        nSol, sSecs, height(Tc), height(Tk), height(Tb), height(Tg));
    for q = 1:numel(segs(s).legs)
        logL{end+1} = sprintf('  leg completed: %s', segs(s).legs{q});
    end
    try
        segLog = fileread(fullfile(segDir, 'run_log.txt'));
        segLines = strsplit(segLog, '\n');
        for q = 1:numel(segLines)
            if ~isempty(strtrim(segLines{q}))
                logL{end+1} = sprintf('  [%s] %s', segTag, segLines{q});
            end
        end
    catch
        logL{end+1} = sprintf('  [%s] run_log unreadable', segTag);
    end
end

% ---- merge currents ----
Tcur = segTabs(1).Tcur;
for s = 2:numel(segTabs)
    Tcur = [Tcur; segTabs(s).Tcur]; %#ok<AGROW>
end

% ---- F4 m-section block (currents table only, base-opts solves) ----
mRows = cell(0, numel(schemaHeaders));
mCases = {};
if any(strcmp(bbLegs, 'base')), mCases{end+1} = 'LF360_GAT_OUT'; end
if any(strcmp(bbLegs, 'GAT-IN')), mCases{end+1} = 'LF360_GAT_IN'; end
mTypes = types(ismember(types, typesFull));
mStages = {};
if any(strcmp(stages, 'Ikpp')), mStages{end+1} = 'Ikpp'; end
if any(strcmp(stages, 'ip')), mStages{end+1} = 'ip'; end
if doM
    Ibase230 = 100 / (sqrt(3) * 230);
    for ci = 1:numel(mCases)
        for mi = 1:numel(mVals)
            mv = mVals(mi);
            opts = struct('m', mv, 'gatLeg', 'H1', 'coupler', 'closed', ...
                'kR', 3.5, 'kX', 2.75, 'kB', 0.725, 'k0g', 1.5, ...
                'ner', 'primary', 'XdRole', 'sat', 'lambda_T', 1.0, ...
                'lineScale', 1.0, 'gatZ0sel', 'nominal');
            opts.ovr = struct('Rloading_tolfrac', 0, 'ZN_UAT_scale', 1, ...
                'ZN_GATLV_scale', 1, 'ZN_GATHV_ohm', 0);
            for ti = 1:numel(mTypes)
                ftype = mTypes{ti};
                F = phase4_solve(mCases{ci}, 'P', 15, 'F4', ftype, 'Ikpp', 0, opts);
                Ifault = govCurrent(F, ftype);
                Irms = abs(Ifault) * Ibase230;
                Ang = angle(Ifault) * 180 / pi;
                s0 = abs(F.I0) * Ibase230; s1 = abs(F.I1) * Ibase230; s2 = abs(F.I2) * Ibase230;
                ipkA = F.ip * Ibase230;
                for qi = 1:numel(mStages)
                    st = mStages{qi};
                    fn = footnoteFor(st, ftype, F);
                    mRows(end+1, :) = {ftype, 'F4', mv, mCases{ci}, 'P', 15, ...
                        'MID', 1.5, 'sat', 'primary', 'H1', ...
                        'bolted', 0, 'closed', st, 'kA', ...
                        '100MVA', Irms, Ang, s0, s1, s2, ipkA, NaN, fn}; %#ok<AGROW>
                end
            end
        end
    end
    Tm = cell2table(mRows, 'VariableNames', schemaHeaders);
    Tcur = [Tcur; Tm];
    logL{end+1} = sprintf('F4 m-section: m=[%s] types=%s cases=%s stages=%s rows=%d (currents only; leg-split helper is matrix-internal)', ...
        num2str(mVals), strjoin(mTypes, ','), strjoin(mCases, ','), strjoin(mStages, ','), height(Tm));
end
magVals = [Tcur.Irms_kA, Tcur.Iseq0_kA, Tcur.Iseq1_kA, Tcur.Iseq2_kA, Tcur.r_kappa_ip];
if any(~isfinite(magVals(:)))
    error('phase4_production:badNumeric', 'Merged currents magnitude columns must be finite (t_break_s exempt).');
end
for k = 1:height(Tcur)
    if isempty(Tcur.fault_type{k}) || isempty(Tcur.location{k}) || isempty(Tcur.caseID{k}) ...
            || isempty(Tcur.stage{k}) || isempty(Tcur.footnote{k})
        error('phase4_production:schema', 'Every currents row must carry ALL schema columns (row %d incomplete).', k);
    end
end
assertNoForbidden(Tcur.Properties.VariableNames);

% ---- merge contributions (union of leg columns, canonical order, NaN fill) ----
legUnion = {};
for s = 1:numel(segTabs)
    vn = segTabs(s).Tcon.Properties.VariableNames;
    legCols = vn(~ismember(vn, [schemaHeaders, kclHeaders]));
    for q = 1:numel(legCols)
        if ~any(strcmp(legUnion, legCols{q}))
            legUnion{end+1} = legCols{q}; %#ok<AGROW>
        end
    end
end
legTags = {};
for q = 1:numel(canonTags)
    cn = ['leg_' canonTags{q} '_kA'];
    if any(strcmp(legUnion, cn))
        legTags{end+1} = cn; %#ok<AGROW>
    end
end
if numel(legTags) ~= numel(legUnion)
    error('phase4_production:legCol', 'Unknown leg column in segment contributions.');
end
conTarget = [schemaHeaders, legTags, kclHeaders];
Tcon = segTabs(1).Tcon;
Tcon = alignContrib(Tcon, conTarget);
for s = 2:numel(segTabs)
    Tcon = [Tcon; alignContrib(segTabs(s).Tcon, conTarget)]; %#ok<AGROW>
end
assertNoForbidden(Tcon.Properties.VariableNames);

% ---- merge bands (regroup by location + fault_type across segments) ----
bandRows = cell(0, numel(bandHeaders));
agg = struct('key', {}, 'loc', {}, 'type', {}, 'mn', {}, 'mnLeg', {}, 'mx', {}, 'mxLeg', {}, 'mid', {}, 'midLeg', {}, 'inc', {});
for s = 1:numel(segTabs)
    Tb = segTabs(s).Tband;
    for r = 1:height(Tb)
        g = char(Tb.group(r));
        [loc, ftype] = parseGroup(g);
        key = [loc '|' ftype];
        bi = find(strcmp({agg.key}, key), 1);
        mn = Tb.min_Ik_kA(r); mx = Tb.max_Ik_kA(r);
        mnLeg = char(Tb.min_leg(r)); mxLeg = char(Tb.max_leg(r));
        mid = Tb.mid_Ik_kA(r); midLeg = char(Tb.mid_leg(r));
        inc = Tb.incomplete(r);
        if isempty(bi)
            agg(end+1) = struct('key', key, 'loc', loc, 'type', ftype, 'mn', mn, ...
                'mnLeg', mnLeg, 'mx', mx, 'mxLeg', mxLeg, 'mid', mid, 'midLeg', midLeg, 'inc', inc); %#ok<AGROW>
        else
            if mn < agg(bi).mn, agg(bi).mn = mn; agg(bi).mnLeg = mnLeg; end
            if mx > agg(bi).mx, agg(bi).mx = mx; agg(bi).mxLeg = mxLeg; end
            if strcmp(agg(bi).midLeg, 'base') || ~(strcmp(midLeg, 'base') || strcmp(agg(bi).midLeg, 'base'))
            else
                agg(bi).mid = mid; agg(bi).midLeg = midLeg;
            end
            if inc == 0, agg(bi).inc = 0; end
        end
    end
end
for b = 1:numel(agg)
    bandRows(end+1, :) = {[agg(b).loc '_' agg(b).type '_' tag], agg(b).type, ...
        agg(b).mn, agg(b).mx, agg(b).mnLeg, agg(b).mxLeg, agg(b).mid, agg(b).midLeg, ...
        agg(b).inc, 'production band from OFAT leg spread across production segments (merged min/max; mid prefers base leg)'}; %#ok<AGROW>
end
Tband = cell2table(bandRows, 'VariableNames', bandHeaders);
assertNoForbidden(Tband.Properties.VariableNames);
logL{end+1} = sprintf('bands merged: %d groups across %d segments', numel(agg), numel(segTabs));

% ---- merge ct ----
Tct = segTabs(1).Tct;
for s = 2:numel(segTabs)
    Tct = [Tct; segTabs(s).Tct]; %#ok<AGROW>
end
assertNoForbidden(Tct.Properties.VariableNames);

% ---- analytic bounds from sensitivity entry points (no reimplemented formulas) ----
t0a = tic;
S = phase4_sensitivity('base_LF360_OUT_P15', analyticLegs);
aRows = cell(0, 7);
for i = 1:numel(S.runs)
    lid = S.runs(i).legID;
    method = S.runs(i).label;
    vv = S.runs(i).variedValues;
    note = analyticNote(lid);
    note = [note '; method ' method '; never a nodal run'];
    fns = fieldnames(vv);
    for q = 1:numel(fns)
        v = vv.(fns{q});
        if isnumeric(v) && isscalar(v) && ~isnan(abs(v))
            aRows(end+1, :) = {lid, method, fns{q}, real(v), imag(v), abs(v), note}; %#ok<AGROW>
        end
    end
end
aHeaders = {'bound_id', 'method', 'field', 'value_real', 'value_imag', 'value_abs', 'note'};
Tana = cell2table(aRows, 'VariableNames', aHeaders);
assertNoForbidden(Tana.Properties.VariableNames);
aSecs = toc(t0a);
logL{end+1} = sprintf('analytic bounds: legs=%s rows=%d secs=%.1f (phase4_sensitivity analytic locals)', ...
    strjoin(analyticLegs, ','), height(Tana), aSecs);

% ---- validation reference (live run unless skipped) ----
if skipValidate
    vPass = NaN; vTotal = NaN;
    vNote = 'validation skipped for bounded subset';
else
    t0v = tic;
    V = phase4_validate('production');
    vSecs = toc(t0v);
    vPass = sum([V.legs.pass]); vTotal = numel(V.legs);
    vNote = sprintf('live phase4_validate runID=production %d/%d legs pass in %.1f s', vPass, vTotal, vSecs);
end
logL{end+1} = ['validation: ' vNote];

% ---- writes (only after all checks pass) ----
writetable(Tcur, fullfile(dirPath, 'phase4_fault_currents.csv'));
writetable(Tcon, fullfile(dirPath, 'phase4_contributions.csv'));
writetable(Tband, fullfile(dirPath, 'phase4_bands.csv'));
writetable(Tct, fullfile(dirPath, 'phase4_ct_data.csv'));
writetable(Tana, fullfile(dirPath, 'analytic_bounds.csv'));

% ---- code hashes (Java MessageDigest helper, inside this file) ----
mlist = dir(fullfile(root, 'matlab', 'phase4', '*.m'));
mlist = mlist(~[mlist.isdir]);
[~, sord] = sort({mlist.name});
mlist = mlist(sord);
codeHashes = struct('file', {}, 'sha256', {});
for k = 1:numel(mlist)
    codeHashes(end+1) = struct('file', mlist(k).name, ...
        'sha256', sha256file(fullfile(root, 'matlab', 'phase4', mlist(k).name))); %#ok<AGROW>
end

% ---- manifest ----
segScope = struct('name', {}, 'legs', {}, 'locs', {}, 'types', {}, 'stages', {}, 'solves', {});
for s = 1:numel(segs)
    segScope(end+1) = struct('name', segs(s).name, 'legs', {segs(s).legs}, 'locs', {segs(s).locs}, ...
        'types', {segs(s).types}, 'stages', {segs(s).stages}, 'solves', segTabs(s).nSolves); %#ok<AGROW>
end
manifest = struct( ...
    'tag', tag, ...
    'timestamp_local', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), ...
    'baseDescriptor', struct('caseID', 'LF360_GAT_OUT', 'ds', 'P', 'XoR_P', 15, ...
        'k0g', 1.5, 'kR', 3.5, 'kX', 2.75, 'kB', 0.725, 'XdRole', 'sat', ...
        'gatLeg', 'H1', 'lambda_T', 1.0, 'gatZ0sel', 'nominal', 'ner', 'primary', ...
        'lineScale', 1.0, 'ZfMode', 'bolted', 'coupler', 'closed', ...
        'source', 'phase4_sensitivity H1-base descriptor (transcribed)'), ...
    'scope', struct('legs', {legs}, 'locs', {locs}, 'types', {types}, 'stages', {stages}, ...
        'segments', segScope, 'f4mValues', mVals, 'f4mCases', {mCases}, 'f4mTypes', {mTypes}, ...
        'analyticLegs', {analyticLegs}), ...
    'rowCounts', struct('phase4_fault_currents_csv', height(Tcur), ...
        'phase4_contributions_csv', height(Tcon), 'phase4_bands_csv', height(Tband), ...
        'phase4_ct_data_csv', height(Tct), 'analytic_bounds_csv', height(Tana)), ...
    'files', {{'phase4_fault_currents.csv', 'phase4_contributions.csv', ...
        'phase4_bands.csv', 'phase4_ct_data.csv', 'analytic_bounds.csv', ...
        'manifest.json', 'run_log.txt', 'sha256.txt'}}, ...
    'codeHashes', codeHashes, ...
    'tolerances', struct('T_RT', 1e-9, 'T_AN', 1e-6, 'T_KCL', 1e-6, 'T_DEAD', 1e-3, ...
        'T_CONT', 0.05, 'T_DET', 1e-12, 'T_STRUCT', 0.5, 'T_SYM', 1e-6, ...
        'T_PRE', 0.10, 'T_B66', 0.05, 'T_TAP', 1e-12, ...
        'settings', 'ds=P XoR_P=15 stage=Ikpp bolted Zf=0 (unless noted) sat primary closed', ...
        'source', 'phase4_validate.m adopted tolerances (transcribed)'), ...
    'validation', struct('runner', 'phase4_validate', 'reference', '27/27', ...
        'pass', vPass, 'total', vTotal, 'note', vNote), ...
    'notes', {{ ...
        'Analytic bounds (E1/E3/D4-joint/D2/D3/D5) recomputed from phase4_sensitivity analytic locals; labelled EXACT/APPROXIMATION, never nodal runs.', ...
        'Ib rows use t_break=0.06 s chosen study reference time (not a measured breaker clearing time); constant-E-prime reference approximation.', ...
        'F4 matrix rows use m=0.5 single section (matrix subset guard); full m-set block appended to currents table via base-opts phase4_solve rows.', ...
        'F4 m-section block is currents-table only: the per-leg split helper is matrix-internal and legs are never redefined.', ...
        'Per-leg IN-case OFAT (H/G legs under IN case) is not expressible via run_phase4_matrix (case fixed per leg); only the backbone and E5H3joint carry IN scope, and E5H3joint rows carry caseID LF360_GAT_IN.', ...
        'No relay/TMS/grading/duty/verdict content; no substation names; no compliance claims.' ...
    }});
fid = fopen(fullfile(dirPath, 'manifest.json'), 'w');
if fid < 0
    error('phase4_production:write', 'Cannot write manifest.json.');
end
fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
fclose(fid);

% ---- run log ----
secs = toc(t0run);
logL{end+1} = sprintf('totals: currents=%d contrib=%d bands=%d ct=%d analytic=%d (wall %.1f s)', ...
    height(Tcur), height(Tcon), height(Tband), height(Tct), height(Tana), secs);
logL{end+1} = 'sha256.txt written after this log; it covers the 4 CSVs + manifest + analytic bounds + this log.';
fid = fopen(fullfile(dirPath, 'run_log.txt'), 'w');
if fid < 0
    error('phase4_production:write', 'Cannot write run_log.txt.');
end
for k = 1:numel(logL)
    fprintf(fid, '%s\n', logL{k});
end
fclose(fid);

% ---- sha256 over outputs ----
hashFiles = {'phase4_fault_currents.csv', 'phase4_contributions.csv', ...
    'phase4_bands.csv', 'phase4_ct_data.csv', 'analytic_bounds.csv', ...
    'manifest.json', 'run_log.txt'};
fid = fopen(fullfile(dirPath, 'sha256.txt'), 'w');
if fid < 0
    error('phase4_production:write', 'Cannot write sha256.txt.');
end
for k = 1:numel(hashFiles)
    fprintf(fid, '%s  %s\n', sha256file(fullfile(dirPath, hashFiles{k})), hashFiles{k});
end
fclose(fid);

% ---- scratch cleanup (production archive stands alone) ----
for s = 1:numel(segs)
    segDir = fullfile(root, 'results', 'phase4_fault', sprintf('%s_seg%d', tag, s));
    if exist(segDir, 'dir') == 7
        rmdir(segDir, 's');
    end
end

fprintf('run_phase4_production %s: %d currents, %d contrib, %d bands, %d ct, %d analytic rows in %s (%.1f s)\n', ...
    tag, height(Tcur), height(Tcon), height(Tband), height(Tct), height(Tana), dirPath, secs);
R = struct('dir', dirPath, 'tag', tag, 'nCurr', height(Tcur), 'nCon', height(Tcon), ...
    'nBand', height(Tband), 'nCt', height(Tct), 'nAnalytic', height(Tana), ...
    'validatePass', vPass, 'validateTotal', vTotal, 'secs', secs);
end

% =====================================================================
function c = asCell(v, nm)
if isstring(v), v = cellstr(v); end
if ischar(v) && isrow(v), v = {v}; end
if ~iscell(v) || isempty(v)
    error('phase4_production:badInput', '%s must be a non-empty cell array of string scalars.', nm);
end
c = cell(1, numel(v));
for i = 1:numel(v)
    li = v{i};
    if isstring(li), li = char(li); end
    if ~(ischar(li) && isrow(li) && ~isempty(li))
        error('phase4_production:badInput', '%s entries must be non-empty string scalars.', nm);
    end
    c{i} = li;
end
end

function T = alignContrib(T, target)
vn = T.Properties.VariableNames;
for q = 1:numel(target)
    if ~any(strcmp(vn, target{q}))
        T.(target{q}) = NaN(height(T), 1);
    end
end
T = T(:, target);
end

function [loc, ftype] = parseGroup(g)
tok = regexp(g, '^(F[1-5])_(LLL|LG|LL|LLG)_', 'tokens', 'once');
if isempty(tok)
    error('phase4_production:bandGroup', 'Cannot parse band group ''%s''.', g);
end
loc = tok{1}; ftype = tok{2};
end

function Ifault = govCurrent(F, type)
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

function fn = footnoteFor(stage, type, F)
ZfMode = 'bolted';
if strcmp(stage, 'ip')
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

function assertNoForbidden(headers)
pats = {'pickup', 'tms', 'grading', 'differential', 'duty', 'verdict', 'rating'};
for i = 1:numel(headers)
    h = lower(char(headers{i}));
    for j = 1:numel(pats)
        if ~isempty(strfind(h, pats{j}))
            error('phase4_production:forbiddenCol', 'Forbidden column pattern detected in headers.');
        end
    end
end
end

function n = analyticNote(lid)
switch lid
    case 'E1'
        n = 'R_loading +-5% band to 3ZN band, F1 LG exact re-evaluation';
    case 'E3'
        n = 'NGT bound resistive-assumed, F1 LG exact re-evaluation';
    case 'D4'
        n = 'X0 x0.9/x1.1 bounded tolerance + X0 error check, F1 LG exact re-evaluation';
    case {'D4E', 'D4+E', 'D4+E-JOINT'}
        n = 'combined D4+E evaluator at F1 LG, exact re-evaluation';
    case 'D2'
        n = 'Xqpp substitution input-spread bound, generator-dominated inheritance';
    case 'D3'
        n = 'X2 +-10% + error-check input-spread bound, generator-dominated inheritance';
    case 'D5'
        n = 'saliency error bound into Ib';
    otherwise
        n = 'analytic local from phase4_sensitivity';
end
end

function hex = sha256file(path)
%SHA256FILE  SHA-256 hex digest via Java MessageDigest (no toolbox).
md = java.security.MessageDigest.getInstance('SHA-256');
jpath = java.io.File(path).toPath();
md.update(java.nio.file.Files.readAllBytes(jpath));
dig = md.digest();
bi = java.math.BigInteger(1, dig);
hex = char(bi.toString(16));
hex = [repmat('0', 1, 64 - numel(hex)) hex];
end
