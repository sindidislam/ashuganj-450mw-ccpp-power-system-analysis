function R = run_phase5_production(tag, varargin)
%RUN_PHASE5_PRODUCTION  End-to-end Phase-5 production driver (Task 17/T20).
%   R = RUN_PHASE5_PRODUCTION(tag) builds every Phase-5 protection output
%   from the frozen Phase-4 production archive (read-only) and writes
%   results/phase5_protection/ via PHASE5_WRITER:
%     9 CSVs (device_registry, relay_settings, fault_inputs,
%     relay_currents, coordination_matrix, coordination_margins,
%     breaker_duty, sensitivity, validation) + manifest.json + run_log.txt
%     + sha256.txt, plus TCC plots via PHASE5_TCC into plots/.
%
%   R = RUN_PHASE5_PRODUCTION(tag, 'overwrite', true) re-runs into the
%   existing results/phase5_protection directory. Without the flag, an
%   existing directory errors error('phase5_production:exists').
%   Default tag 'production' (manifest tag only; the output directory is
%   fixed results/phase5_protection).
%
%   Binding carry-forwards (locked, read ALL consumers first):
%   (a) Relay settings/pickups use the T6 PRODUCTION path: GIS-Q0-51 =
%       1.2 x FL_anchor read live from phase4_ct_data.csv FL_anchor_kA
%       (LINE_Q9 path; ~1043.95 A), never the 2400 A rated-proxy fallback
%       that phase5_coord/phase5_tcc use internally when the registry
%       carries NaN pickup. Production pickups are stamped into a devices
%       copy (registry never edited) so phase5_coord grades production
%       settings (T6-registry source). TCC footers keep their disclosed
%       fallback; production CSVs carry production values.
%   (b) Iseq0_kA is joined live from phase4_fault_currents.csv
%       (backbone-first dedup identical to phase5_import) into the import
%       table before phase5_coord, and into relay-currents/earth rows, so
%       LLG earth uses real I0; the I0-NOT-DETERMINABLE path only fires
%       where production truly lacks I0.
%   (c) r_kappa_ip (borrowed-shape peak, informational only) is joined the
%       same way and passes through phase5_duty into I_peak_kA; missing ->
%       NaN + MISSING-peak note, never invented.
%   (d) Task-15 full close: phase5_writer errors on any empty
%       provenance/scope (phase5_writer:provenance).
%   (e) TCC plots regenerate via phase5_tcc into
%       results/phase5_protection/plots/ as part of this run
%       (deterministic overwrite within the new dir only).
%   (f) manifest.json carries tag, timestamp, the INPUT production
%       manifest SHA-256 (production manifest.json hashed read-only plus
%       the production sha256.txt lines transcribed), code SHA-256 of
%       every matlab/phase5/*.m, row counts, and the live phase5_validate
%       reference. sha256.txt covers the 9 CSVs + manifest + run_log +
%       validation CSV (11 lines). run_log.txt carries settings + row
%       counts + validation/test counts. Existing modules are consumed
%       with their exact call signatures and never modified.
%
%   Validation/tests: live phase5_validate() supplies the validation CSV
%   and manifest reference; run_phase5_tests() runs after the tables and
%   TCC plots but BEFORE phase5_writer, so NP/NF land in run_log.txt
%   before sha256.txt is hashed (never appended after hashing). Counts
%   are recorded honestly, never gated-to-pass here (the T19 gate judges).
%   All errors are 'phase5'-prefixed.
t0run = tic;
if nargin < 1 || isempty(tag)
    tag = 'production';
end
if isstring(tag) && isscalar(tag), tag = char(tag); end
if ~(ischar(tag) && isrow(tag) && ~isempty(tag))
    error('phase5_production:badTag', 'tag must be a non-empty char rowvec (manifest tag).');
end
overwrite = false;
for k = 1:2:numel(varargin)
    nm = varargin{k};
    if isstring(nm), nm = char(nm); end
    if k + 1 > numel(varargin)
        error('phase5_production:args', 'Name-value options need a value.');
    end
    vv = varargin{k + 1};
    switch lower(nm)
        case 'overwrite'
            overwrite = logical(vv);
        otherwise
            error('phase5_production:args', 'Unknown option ''%s''.', nm);
    end
end
root = ashuganj_root();
outDir = fullfile(root, 'results', 'phase5_protection');
if exist(outDir, 'dir') == 7 && ~overwrite
    error('phase5_production:exists', ...
        'Output directory %s exists; re-run with ''overwrite'', true.', outDir);
end
% ---- (f) INPUT production manifest SHA, read-only ----
prodMan = fullfile(root, 'results', 'phase4_fault', 'production', 'manifest.json');
prodSha = fullfile(root, 'results', 'phase4_fault', 'production', 'sha256.txt');
if exist(prodMan, 'file') ~= 2
    error('phase5_production:input', 'production manifest missing (read-only input): %s', prodMan);
end
if exist(prodSha, 'file') ~= 2
    error('phase5_production:input', 'production sha256.txt missing (read-only input): %s', prodSha);
end
inputManifestSha = sha256file(prodMan);
inputShaLines = strsplit(strtrim(fileread(prodSha)), '\n');
inputShaLines = inputShaLines(:)';
% ---- Registry + backbone import (40 rows, 2x5x4 Ikpp) ----
Rreg = phase5_registry();
Ti = phase5_import(root);
if height(Ti) ~= 40
    error('phase5_production:matrix', 'phase5_import backbone row count %d ~= 40.', height(Ti));
end
% ---- (b)+(c) Iseq0_kA + r_kappa_ip joins from production currents ----
TiJ = join_production_peaks(root, Ti);
% ---- (a) FL anchors live from production ct_data (frozen flows) ----
anchors = read_anchors(root);
% Imin anchors, coord-consistent (totals-based; branch legs affect times only).
[IminPhase, IminEarth] = pickup_anchors(TiJ);
% ---- (a) T6 PRODUCTION pickups, stamped into a devices copy ----
[devicesProd, setRows, settingsLines] = production_settings(Rreg, anchors, IminPhase, IminEarth);
% ---- Tables 1-3: registry / settings / fault_inputs ----
Tregistry = registry_table(Rreg);
TfaultInputs = table(Ti.fault_location, Ti.fault_type, Ti.caseID, Ti.m, ...
    Ti.stage, Ti.I_primary_kA, Ti.I_primary_A, Ti.provenance, ...
    repmat({'PRIMARY'}, height(Ti), 1), ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', 'm', ...
    'stage', 'I_primary_kA', 'I_primary_A', 'provenance', 'scope'});
% ---- Coordination on production settings + joined Iseq0 ----
[Mtrx, Mrg] = phase5_coord(devicesProd, TiJ);
Mtrx.provenance = repmat({['DERIVED:phase5_coord-branch-through-current-' ...
    'margin-CTI-0.3s-study-threshold-SOURCE-BACKED-Phase-4-import']}, height(Mtrx), 1);
Mtrx.scope = repmat({'PRIMARY'}, height(Mtrx), 1);
Mrg.provenance = repmat({['DERIVED:phase5_coord-margin-dt-t_up-minus-t_down-' ...
    'SOURCE-BACKED-Phase-4-import']}, height(Mrg), 1);
Mrg.scope = repmat({'PRIMARY'}, height(Mrg), 1);
% ---- Relay currents traced from the graded matrix sides ----
TrelayCurrents = relay_currents_table(Mtrx, TiJ);
% ---- Breaker duty on breaker-path through-currents + peak passthrough ----
Dduty = phase5_duty(TiJ, []);
Dprov = repmat({'SOURCE-BACKED:Phase-4-production-import-through-current-branch'}, height(Dduty), 1);
isNote = strcmp(tocell(Dduty.verdict), 'NOTE');
Dprov(isNote) = {'ESTIMATED:50.00-kA-station-reference-informational-only-never-duty-basis'};
Dduty.provenance = Dprov;
Dduty.scope = repmat({'PRIMARY'}, height(Dduty), 1);
% ---- Fenced sensitivity (production-stamped devices; GEN outputs identical) ----
Tsens = phase5_sensitivity(TiJ, devicesProd);
% ---- Live validation -> validation CSV + manifest reference ----
V = phase5_validate();
vPass = sum([V.legs.pass]); vTotal = numel(V.legs);
vIds = strjoin({V.legs.id}, ',');
vNote = sprintf('live phase5_validate %d/%d legs pass (%s)', vPass, vTotal, vIds);
Tvalid = table({V.legs.id}', double([V.legs.pass]'), [V.legs.residual]', ...
    {V.legs.note}', ...
    repmat({'DERIVED:phase5_validate-live-run-R0-V1-V15'}, vTotal, 1), ...
    repmat({'PRIMARY'}, vTotal, 1), ...
    'VariableNames', {'leg', 'pass', 'residual', 'note', 'provenance', 'scope'});
% ---- (e) TCC plots regenerate into the new plots dir ----
plotDir = fullfile(outDir, 'plots');
Stcc = phase5_tcc(plotDir, root);
settingsLines{end + 1} = sprintf('TCC plots regenerated via phase5_tcc: %s, %s', ... %#ok<AGROW>
    Stcc.gen_png, Stcc.grid_png);
% ---- Tests run BEFORE the writer so counts land in run_log pre-hash ----
[NP, NF] = run_phase5_tests();
% ---- Writer (d: provenance full close enforced inside) ----
tables = struct('registry', Tregistry, 'settings', setRows, ...
    'faultInputs', TfaultInputs, 'relayCurrents', TrelayCurrents, ...
    'coordMatrix', Mtrx, 'coordMargins', Mrg, 'duty', Dduty, ...
    'sensitivity', Tsens, 'validation', Tvalid);
meta = struct('tag', tag, 'inputManifestSha', inputManifestSha, ...
    'inputShaLines', {inputShaLines}, ...
    'validation', struct('pass', vPass, 'total', vTotal, 'note', vNote), ...
    'testCounts', struct('NP', NP, 'NF', NF), ...
    'settingsLines', {settingsLines}, ...
    'extraNotes', {{'TCC plots (tcc_gen.png, tcc_grid.png) in plots/ are study-curve figures, not hashed in sha256.txt.'}});
W = phase5_writer(outDir, tables, meta);
secs = toc(t0run);
fprintf(['run_phase5_production %s: registry=%d settings=%d inputs=%d currents=%d ' ...
    'matrix=%d margins=%d duty=%d sens=%d valid=%d/%d tests NP=%d NF=%d in %s (%.1f s)\n'], ...
    tag, height(Tregistry), height(setRows), height(TfaultInputs), ...
    height(TrelayCurrents), height(Mtrx), height(Mrg), height(Dduty), ...
    height(Tsens), vPass, vTotal, NP, NF, outDir, secs);
R = struct('dir', outDir, 'tag', tag, 'rowCounts', W.rowCounts, ...
    'validatePass', vPass, 'validateTotal', vTotal, 'NP', NP, 'NF', NF, ...
    'genPng', Stcc.gen_png, 'gridPng', Stcc.grid_png, 'secs', secs);
end

function TiJ = join_production_peaks(root, Ti)
%JOIN_PRODUCTION_PEAKS  (b)+(c): Iseq0_kA + r_kappa_ip from currents CSV.
%   Backbone-first dedup identical to phase5_import (filter stage Ikpp +
%   m 0.5, first-per-(caseID,location,fault_type) in file order), then an
%   inner join on those keys. Every import row must hit, else
%   phase5_production:join (never silently NaN-filled).
Fp = fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_fault_currents.csv');
C = readtable(Fp);
for k = 1:numel({'fault_type', 'location', 'm', 'caseID', 'stage', 'Iseq0_kA', 'r_kappa_ip'})
    need = {'fault_type', 'location', 'm', 'caseID', 'stage', 'Iseq0_kA', 'r_kappa_ip'};
    if ~any(strcmp(C.Properties.VariableNames, need{k}))
        error('phase5_production:schema', 'production currents CSV missing column %s.', need{k});
    end
end
Cb = C(strcmp(C.stage, 'Ikpp') & C.m == 0.5, :);
keys = strcat(Cb.caseID, '|', Cb.location, '|', Cb.fault_type);
[~, ia] = unique(keys, 'stable');
Cb = Cb(ia, :);
n = height(Ti);
Iseq0 = NaN(n, 1); rkp = NaN(n, 1);
tloc = tocell(Ti.fault_location); ttyp = tocell(Ti.fault_type); tcs = tocell(Ti.caseID);
bloc = tocell(Cb.location); btyp = tocell(Cb.fault_type); bcs = tocell(Cb.caseID);
for i = 1:n
    hit = find(strcmp(bcs, tcs{i}) & strcmp(bloc, tloc{i}) & strcmp(btyp, ttyp{i}), 1, 'first');
    if isempty(hit)
        error('phase5_production:join', ...
            'production currents join missed %s %s %s (backbone keys diverged).', ...
            tcs{i}, tloc{i}, ttyp{i});
    end
    Iseq0(i) = Cb.Iseq0_kA(hit);
    rkp(i) = Cb.r_kappa_ip(hit);
end
if any(~isfinite(Iseq0)) || any(~isfinite(rkp))
    error('phase5_production:join', 'joined Iseq0_kA/r_kappa_ip must be finite on all 40 backbone rows.');
end
TiJ = Ti;
TiJ.Iseq0_kA = Iseq0;
TiJ.r_kappa_ip = rkp;
end

function anchors = read_anchors(root)
%READ_ANCHORS  Frozen-flow FL_anchor_kA per through_path, live from ct_data.
G = readtable(fullfile(root, 'results', 'phase4_fault', 'production', 'phase4_ct_data.csv'));
if ~all(ismember({'through_path', 'FL_anchor_kA'}, G.Properties.VariableNames))
    error('phase5_production:schema', 'production ct_data CSV missing through_path/FL_anchor_kA.');
end
paths = {'GEN_Q', 'GSUT_HV', 'GRID_Q', 'LINE_Q9'};
anchors = struct();
tp = tocell(G.through_path);
for k = 1:numel(paths)
    u = unique(G.FL_anchor_kA(strcmp(tp, paths{k})));
    u = u(isfinite(u));
    if numel(u) ~= 1
        error('phase5_production:anchor', ...
            'through_path %s must carry exactly one FL_anchor_kA (got %d).', paths{k}, numel(u));
    end
    anchors.(paths{k}) = u;
end
end

function [IminPhase, IminEarth] = pickup_anchors(TiJ)
%PICKUP_ANCHORS  Must-detect anchors for the T6 production pickup calls.
%   IminPhase: coord-consistent min over phase-fault totals (LLL/LL/LLG,
%   never LG earth). IminEarth: LG-only min over LG totals. The LG-only
%   restriction is the phase5_pickup contract ('EF uses F1 LG 7.27 A') and
%   matches validate V2/V9 legs plus the T6 methodology (GEN-51N 5 A
%   must-detect F1 LG with margin ~1.45). The LLG-inclusive 3I0 min that
%   phase5_coord uses INTERNALLY (LLG 3I0 ~3.63 A < 5 A pickup) stays
%   where it belongs: honest below-pickup NO-TRIP rows in the
%   coordination matrix, never in the settings must-detect anchor.
typs = tocell(TiJ.fault_type);
ph = strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG');
IfA = double(TiJ.I_primary_A(:));
if any(ph)
    IminPhase = min(IfA(ph));
else
    IminPhase = min(IfA);
end
lg = strcmp(typs, 'LG');
if any(lg)
    IminEarth = min(IfA(lg));
else
    IminEarth = 7.27200442799167;
end
end

function [devicesProd, setRows, settingsLines] = production_settings(Rreg, anchors, IminPhase, IminEarth)
%PRODUCTION_SETTINGS  (a): T6 PRODUCTION pickups stamped on a devices copy.
devs = Rreg.devices;
ids = {devs.device_id};
d51 = devs(strcmp(ids, 'GEN-51'));
d51N = devs(strcmp(ids, 'GEN-51N'));
dHV = devs(strcmp(ids, 'GSUT-HV-51'));
dQ0 = devs(strcmp(ids, 'GIS-Q0-51'));
% GEN-51: 1.25 x rated (12019 A -> 15023.75 A), no-trip-on-load vs rated.
P51 = phase5_pickup(d51, double(Rreg.gen.Irated_A), IminPhase);
if abs(P51.setting - 15023.75) > 1e-9
    error('phase5_production:pickup', 'GEN-51 production pickup %.4f A ~= 15023.75 A.', P51.setting);
end
% GEN-51N: 5 A SENSITIVE study setting, must-detect F1 LG.
PN = phase5_pickup(d51N, 0, IminEarth);
if abs(PN.setting - 5) > 1e-12
    error('phase5_production:pickup', 'GEN-51N production pickup %.6f A ~= 5 A.', PN.setting);
end
% GSUT-HV-51: generic 1.2 x max(rated, frozen-flow anchor).
hvAnchor = anchors.GSUT_HV * 1000;
PHV = phase5_pickup(dHV, hvAnchor, IminPhase);
% GIS-Q0-51 PRODUCTION PATH: 1.2 x LINE_Q9 FL_anchor (never rated-proxy).
q0Anchor = anchors.LINE_Q9 * 1000;
PQ0 = phase5_pickup(dQ0, q0Anchor, IminPhase);
if abs(PQ0.setting / q0Anchor - 1.2) > 1e-12
    error('phase5_production:pickup', 'GIS-Q0-51 production pickup must be 1.2x FL_anchor.');
end
if abs(PQ0.setting - 1.2 * 869.956651959241) > 1e-6
    error('phase5_production:pickup', ...
        'GIS-Q0-51 production pickup %.4f A drifts from 1.2x frozen LINE_Q9 anchor 1043.95 A.', PQ0.setting);
end
% Stamp into a copy (registry struct itself never edited).
devicesProd = devs;
devicesProd(strcmp(ids, 'GEN-51')).pickup_A = P51.setting;
devicesProd(strcmp(ids, 'GEN-51N')).pickup_A = PN.setting;
devicesProd(strcmp(ids, 'GSUT-HV-51')).pickup_A = PHV.setting;
devicesProd(strcmp(ids, 'GIS-Q0-51')).pickup_A = PQ0.setting;
% Applied TMS/curve mirror the coord study defaults (registry NaN/empty).
setRows = settings_table(devs, P51, PN, PHV, PQ0);
settingsLines = {
    sprintf('GEN-51 phase pickup %.2f A-primary (1.25x rated 12019 A; %s)', P51.setting, P51.basis)
    sprintf('GEN-51N earth pickup %.2f A-primary (SENSITIVE; %s)', PN.setting, PN.basis)
    sprintf('GSUT-HV-51 phase pickup %.2f A-primary (1.2x max(rated 1150 A, GSUT_HV anchor %.4f A); %s)', PHV.setting, hvAnchor, PHV.source)
    sprintf('GIS-Q0-51 phase pickup %.4f A-primary (PRODUCTION 1.2x LINE_Q9 FL_anchor %.6f A from phase4_ct_data.csv; never 2400 A rated-proxy)', PQ0.setting, q0Anchor)
    sprintf('FL anchors (phase4_ct_data.csv FL_anchor_kA, frozen flows): GEN_Q %.4f, GSUT_HV %.5f, GRID_Q %.5f, LINE_Q9 %.6f kA', anchors.GEN_Q, anchors.GSUT_HV, anchors.GRID_Q, anchors.LINE_Q9)
    sprintf('Imin anchors: phase %.2f A (LLL/LL/LLG totals min); earth %.5f A (LG totals min per T6 EF contract; LLG 3I0 below-pickup outcomes live honestly in the matrix)', IminPhase, IminEarth)
    'TMS study defaults (ENGINEERING_ASSUMPTION, registry NaN): GEN 0.1 / GSUT 0.2 / GIS 0.3; curve SI (STUDY constants, never manufacturer)'
    'CTI 0.3 s (ENGINEERING_ASSUMPTION study threshold); primary CT 15000/1 SOURCE-BACKED, 16000/1 LEGACY fenced sensitivity only'
    'Breaker duty: Q0 (52-1) only; Q1/Q2/Q9 disconnectors never duty; peak r_kappa_ip borrowed-shape informational only, never duty input'
    'CSV dialect: RFC-4180 comma-separated; text fields with commas are double-quoted (notably the GSUT-HV-51 basis cell). MATLAB readers must use readtable(fp,''Delimiter'','','') because the auto-delimiter sniffer misparses quoted-comma rows.'
    };
end

function setRows = settings_table(devs, P51, PN, PHV, PQ0)
%SETTINGS_TABLE  7-row relay_settings CSV (4 production + 3 MISSING).
ctOf = @(id) devs(strcmp({devs.device_id}, id)).ct_ratio;
[t51, c51] = tc_default(devs(strcmp({devs.device_id}, 'GEN-51')), 'GEN-51', 0.1);
[tN, cN] = tc_default(devs(strcmp({devs.device_id}, 'GEN-51N')), 'GEN-51N', 0.1);
[tHV, cHV] = tc_default(devs(strcmp({devs.device_id}, 'GSUT-HV-51')), 'GSUT-HV-51', 0.2);
[tQ0, cQ0] = tc_default(devs(strcmp({devs.device_id}, 'GIS-Q0-51')), 'GIS-Q0-51', 0.3);
dids = {'GEN-51'; 'GEN-51N'; 'GSUT-HV-51'; 'GIS-Q0-51'; ...
    'GIS-Q0-50'; 'LINE-21-note'; 'REMOTE-GRID-boundary'};
sets = [P51.setting; PN.setting; PHV.setting; PQ0.setting; NaN; NaN; NaN];
units = {'A-primary'; 'A-primary'; 'A-primary'; 'A-primary'; ''; ''; ''};
basis = {P51.basis; PN.basis; PHV.basis; PQ0.basis; ...
    'NOT DETERMINABLE FROM AVAILABLE DATA:GIS-Q0-50-high-set-DISABLED-unless-justified'; ...
    'NOT DETERMINABLE FROM AVAILABLE DATA:distance-settings-no-source'; ...
    'NOT DETERMINABLE FROM AVAILABLE DATA:remote-grid-monitoring-only-no-device'};
src = {P51.source; PN.source; PHV.source; PQ0.source; ...
    'MISSING:no-high-set-source'; 'MISSING:no-distance-source'; 'MISSING:no-device'};
val = {[P51.validation ';tms-study-default-0.1;curve-SI-STUDY']; ...
    [PN.validation ';tms-study-default-0.1;curve-SI-STUDY']; ...
    [PHV.validation ';tms-study-default-0.2;curve-SI-STUDY']; ...
    [PQ0.validation ';tms-study-default-0.3;curve-SI-STUDY']; ...
    'DISABLED-unless-justified;no high-set invented'; ...
    'NOTE-only;no settings invented'; ...
    'MONITORING-only;no settings invented'};
cts = [ctOf('GEN-51'); ctOf('GEN-51N'); ctOf('GSUT-HV-51'); ctOf('GIS-Q0-51'); ...
    ctOf('GIS-Q0-50'); NaN; NaN];
tms = [t51; tN; tHV; tQ0; NaN; NaN; NaN];
cvs = {c51; cN; cHV; cQ0; ''; ''; ''};
prov = {['SOURCE-BACKED:protection-report-CT-15000/1-B22;' P51.source]; ...
    ['SOURCE-BACKED:protection-report-CT-15000/1-B22-EF;' PN.source]; ...
    ['ENGINEERING_ASSUMPTION:GSUT-HV-CT-2000/1-ratio-assumed;' PHV.source]; ...
    ['ENGINEERING_ASSUMPTION:GIS-CT-2000/1-ratio-assumed;' PQ0.source]; ...
    'MISSING:GIS-Q0-50-high-set-no-source'; ...
    'MISSING:distance-settings-not-determinable-from-available-data'; ...
    'MISSING:remote-grid-no-device-monitoring-only'};
scope = {P51.assumption_class; PN.assumption_class; PHV.assumption_class; ...
    PQ0.assumption_class; 'PRIMARY'; 'PRIMARY'; 'PRIMARY'};
setRows = table(dids, sets, units, basis, src, val, cts, tms, cvs, prov, scope, ...
    'VariableNames', {'device_id', 'setting_A_primary', 'unit', 'basis', ...
    'source', 'validation', 'ct_ratio', 'tms', 'curve', 'provenance', 'scope'});
end

function [tms, cv] = tc_default(d, id, defTms)
%TC_DEFAULT  Applied TMS/curve identical to the coord study defaults.
tm = double(d.tms);
if isscalar(tm) && isfinite(tm) && tm > 0
    tms = tm;
else
    tms = defTms;
end
c = d.curve;
if isstring(c) && isscalar(c), c = char(c); end
if ischar(c) && ~isempty(strtrim(c))
    cv = upper(strtrim(c));
else
    cv = 'SI';
end
end

function Tregistry = registry_table(Rreg)
%REGISTRY_TABLE  21 locked registry fields + scope into a CSV-ready table.
d = Rreg.devices;
n = numel(d);
ch = @(f) tocell({d.(f)});
Tregistry = table(ch('device_id'), ch('device_type'), ch('equipment'), ...
    ch('ansi'), ch('zone'), [d.ct_ratio]', ch('ct_source'), [d.rated_A]', ...
    [d.vnom_kV]', ch('fault_source'), [d.pickup_A]', [d.tms]', ch('curve'), ...
    [d.ef_pickup_A]', [d.ef_tms]', ch('breaker_ref'), ch('upstream'), ...
    ch('downstream'), ch('provenance'), ch('status'), ch('assumption_class'), ...
    repmat({'PRIMARY'}, n, 1), ...
    'VariableNames', {'device_id', 'device_type', 'equipment', 'ansi', ...
    'zone', 'ct_ratio', 'ct_source', 'rated_A', 'vnom_kV', 'fault_source', ...
    'pickup_A', 'tms', 'curve', 'ef_pickup_A', 'ef_tms', 'breaker_ref', ...
    'upstream', 'downstream', 'provenance', 'status', 'assumption_class', 'scope'});
end

function Trc = relay_currents_table(Mtrx, TiJ)
%RELAY_CURRENTS_TABLE  One row per finite matrix side + I0 context.
%   I_primary = I_secondary x CT (matrix sides are secondary amperes).
%   I0_A joins real production Iseq0 (b); LG-exact If/3 only when the join
%   truly lacks I0; LLG-without-Iseq0 -> NaN, never invented.
ml = tocell(Mtrx.fault_location); mt = tocell(Mtrx.fault_type); mc = tocell(Mtrx.caseID);
jl = tocell(TiJ.fault_location); jt = tocell(TiJ.fault_type); jc = tocell(TiJ.caseID);
Jseq = double(TiJ.Iseq0_kA(:)); Jtot = double(TiJ.I_primary_A(:));
oLoc = {}; oTyp = {}; oCase = {}; oDev = {}; oSide = {};
oIp = []; oIk = []; oCt = []; oIs = []; oI0 = []; oSrc = {};
oProv = {}; oScope = {};
PROV = 'SOURCE-BACKED:Phase-4-production-import-branch-through-current-via-phase5_coord';
for i = 1:height(Mtrx)
    j = find(strcmp(jc, mc{i}) & strcmp(jl, ml{i}) & strcmp(jt, mt{i}), 1, 'first');
    if isempty(j)
        error('phase5_production:join', ...
            'relay-currents join missed %s %s %s.', mc{i}, ml{i}, mt{i});
    end
    if isfinite(Jseq(j))
        i0 = Jseq(j) * 1000;
        src = 'Iseq0-SOURCE-BACKED-Phase-4-production';
    elseif strcmp(mt{i}, 'LG')
        i0 = Jtot(j) / 3;
        src = 'LG-exact-If/3-DERIVED';
    else
        i0 = NaN;
        src = 'MISSING-no-Iseq0-LLG-neutral-counted-once-N/A';
    end
    if isfinite(Mtrx.I_down_A(i)) && isfinite(Mtrx.ct_down(i))
        oLoc{end + 1} = ml{i}; oTyp{end + 1} = mt{i}; oCase{end + 1} = mc{i}; %#ok<AGROW>
        oDev{end + 1} = Mtrx.downstream{i}; oSide{end + 1} = 'downstream'; %#ok<AGROW>
        oIp(end + 1) = Mtrx.I_down_A(i) * Mtrx.ct_down(i); %#ok<AGROW>
        oIk(end + 1) = oIp(end) / 1000; %#ok<AGROW>
        oCt(end + 1) = Mtrx.ct_down(i); %#ok<AGROW>
        oIs(end + 1) = Mtrx.I_down_A(i); %#ok<AGROW>
        oI0(end + 1) = i0; %#ok<AGROW>
        oSrc{end + 1} = src; %#ok<AGROW>
        oProv{end + 1} = PROV; oScope{end + 1} = 'PRIMARY'; %#ok<AGROW>
    end
    if isfinite(Mtrx.I_up_A(i)) && isfinite(Mtrx.ct_up(i))
        oLoc{end + 1} = ml{i}; oTyp{end + 1} = mt{i}; oCase{end + 1} = mc{i}; %#ok<AGROW>
        oDev{end + 1} = Mtrx.upstream{i}; oSide{end + 1} = 'upstream'; %#ok<AGROW>
        oIp(end + 1) = Mtrx.I_up_A(i) * Mtrx.ct_up(i); %#ok<AGROW>
        oIk(end + 1) = oIp(end) / 1000; %#ok<AGROW>
        oCt(end + 1) = Mtrx.ct_up(i); %#ok<AGROW>
        oIs(end + 1) = Mtrx.I_up_A(i); %#ok<AGROW>
        oI0(end + 1) = i0; %#ok<AGROW>
        oSrc{end + 1} = src; %#ok<AGROW>
        oProv{end + 1} = PROV; oScope{end + 1} = 'PRIMARY'; %#ok<AGROW>
    end
end
Trc = table(oLoc', oTyp', oCase', oDev', oSide', oIp', oIk', oCt', ...
    oIs', oI0', oSrc', oProv', oScope', ...
    'VariableNames', {'fault_location', 'fault_type', 'caseID', ...
    'device_id', 'side', 'I_primary_A', 'I_primary_kA', 'CT_ratio', ...
    'I_secondary_A', 'I0_A', 'I0_source', 'provenance', 'scope'});
if height(Trc) < 1
    error('phase5_production:rows', 'relay-currents table empty (matrix sides all missing).');
end
end

function c = tocell(v)
%TOCELL  Normalize table/struct text to cellstr.
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
    error('phase5_production:schema', 'text column must be cell/string/char.');
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
