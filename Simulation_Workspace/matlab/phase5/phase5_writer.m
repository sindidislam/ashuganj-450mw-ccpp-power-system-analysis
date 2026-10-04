function W = phase5_writer(outDir, tables, meta)
%PHASE5_WRITER  CSV/manifest/sha256/run_log writer (Phase-5 Task 17).
%   W = PHASE5_WRITER(outDir, tables, meta) writes the nine locked
%   Phase-5 production tables plus manifest.json, run_log.txt and
%   sha256.txt into outDir (created when missing; files overwritten
%   deterministically). The caller (run_phase5_production) owns the
%   results/phase5_protection exists-guard; this function never deletes
%   anything outside outDir and never touches Phase-4 inputs.
%
%   tables struct fields (all MATLAB tables, height >= 1):
%     .registry      device_registry (21 locked registry fields + scope)
%     .settings      relay_settings (device_id, setting_A_primary, unit,
%                    basis, source, validation, ct_ratio, tms, curve,
%                    provenance, scope)
%     .faultInputs   fault_inputs (fault_location, fault_type, caseID, m,
%                    stage, I_primary_kA, I_primary_A, provenance, scope)
%     .relayCurrents relay_currents (fault_location, fault_type, caseID,
%                    device_id, side, I_primary_A, I_primary_kA, CT_ratio,
%                    I_secondary_A, I0_A, I0_source, provenance, scope)
%     .coordMatrix   coordination_matrix (15 locked T8 cols + provenance
%                    + scope)
%     .coordMargins  coordination_margins (pair, fault_location,
%                    fault_type, caseID, margin_s, verdict, reason,
%                    provenance, scope)
%     .duty          breaker_duty (10 locked T10 cols + provenance + scope)
%     .sensitivity   sensitivity (28 locked T14 cols incl. scope/provenance)
%     .validation    validation (leg, pass, residual, note, provenance,
%                    scope; pass written 1/0)
%
%   meta struct fields:
%     .tag               manifest tag (required non-empty char)
%     .inputManifestSha  SHA-256 of results/phase4_fault/production/
%                        manifest.json, read-only (required non-empty char)
%     .inputShaLines     cellstr copy of production sha256.txt lines
%                        (optional, default {})
%     .validation        struct pass/total/note, live phase5_validate
%                        reference (required)
%     .testCounts        struct NP/NF from run_phase5_tests (required)
%     .settingsLines     cellstr T6 production settings summary for the
%                        run log (required)
%     .extraNotes        cellstr manifest notes appendix (optional)
%
%   Provenance enforcement (Task 15 full close): every one of the nine
%   tables must carry non-empty 'provenance' and 'scope' columns; any
%   missing column errors error('phase5_writer:schema'), any empty
%   (all-blank/whitespace) cell errors error('phase5_writer:provenance').
%   Numeric NaN elsewhere is honest MISSING and is allowed.
%
%   sha256.txt covers the 9 CSVs + manifest.json + run_log.txt (11 lines),
%   hex digests via the Java MessageDigest helper (Phase-4 pattern, no
%   toolbox). Code hashes cover every matlab/phase5/*.m sorted by name.
%   All errors are 'phase5'-prefixed.
if nargin ~= 3
    error('phase5_writer:args', 'usage: W = phase5_writer(outDir, tables, meta).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if ~ischar(outDir) || isempty(strtrim(outDir))
    error('phase5_writer:args', 'outDir must be a non-empty path (char).');
end
names = {'registry', 'settings', 'faultInputs', 'relayCurrents', ...
    'coordMatrix', 'coordMargins', 'duty', 'sensitivity', 'validation'};
files = {'phase5_device_registry.csv', 'phase5_relay_settings.csv', ...
    'phase5_fault_inputs.csv', 'phase5_relay_currents.csv', ...
    'phase5_coordination_matrix.csv', 'phase5_coordination_margins.csv', ...
    'phase5_breaker_duty.csv', 'phase5_sensitivity.csv', ...
    'phase5_validation.csv'};
if ~isstruct(tables) || ~isscalar(tables)
    error('phase5_writer:args', 'tables must be a scalar struct with the 9 locked table fields.');
end
for k = 1:numel(names)
    if ~isfield(tables, names{k}) || ~istable(tables.(names{k}))
        error('phase5_writer:schema', 'tables.%s missing or not a table.', names{k});
    end
    if height(tables.(names{k})) < 1
        error('phase5_writer:rows', 'tables.%s must carry >= 1 row.', names{k});
    end
end
reqCols.registry = {'device_id', 'device_type', 'equipment', 'ansi', 'zone', ...
    'ct_ratio', 'ct_source', 'rated_A', 'vnom_kV', 'fault_source', ...
    'pickup_A', 'tms', 'curve', 'ef_pickup_A', 'ef_tms', 'breaker_ref', ...
    'upstream', 'downstream', 'provenance', 'status', 'assumption_class', 'scope'};
reqCols.settings = {'device_id', 'setting_A_primary', 'unit', 'basis', ...
    'source', 'validation', 'ct_ratio', 'tms', 'curve', 'provenance', 'scope'};
reqCols.faultInputs = {'fault_location', 'fault_type', 'caseID', 'm', ...
    'stage', 'I_primary_kA', 'I_primary_A', 'provenance', 'scope'};
reqCols.relayCurrents = {'fault_location', 'fault_type', 'caseID', ...
    'device_id', 'side', 'I_primary_A', 'I_primary_kA', 'CT_ratio', ...
    'I_secondary_A', 'I0_A', 'I0_source', 'provenance', 'scope'};
reqCols.coordMatrix = {'downstream', 'upstream', 'fault_location', ...
    'fault_type', 'caseID', 'I_fault_kA', 'I_down_A', 'I_up_A', ...
    't_down_s', 't_up_s', 'ct_down', 'ct_up', 'margin_s', 'verdict', ...
    'reason', 'provenance', 'scope'};
reqCols.coordMargins = {'pair', 'fault_location', 'fault_type', 'caseID', ...
    'margin_s', 'verdict', 'reason', 'provenance', 'scope'};
reqCols.duty = {'location', 'breaker_ref', 'fault_type', 'caseID', ...
    'I_sym_kA', 'I_peak_kA', 'rating_kA', 'basis', 'verdict', 'note', ...
    'provenance', 'scope'};
reqCols.sensitivity = {'fault_location', 'fault_type', 'caseID', ...
    'device_id', 'I_primary_A', 'I_primary_kA', 'relay_path', ...
    'I_sec_primary_A', 'I_sec_sens_A', 'ct_primary', 'ct_legacy', ...
    'ct_tag', 'pickup_primary_A', 'tms', 'curve', 't_primary_s', ...
    't_sens_s', 'dt_s', 'direction', 'margin_primary_s', 'margin_sens_s', ...
    'dmargin_s', 'margin_direction', 'verdict_primary', 'verdict_sens', ...
    'scope', 'provenance', 'reason'};
reqCols.validation = {'leg', 'pass', 'residual', 'note', 'provenance', 'scope'};
for k = 1:numel(names)
    vn = tables.(names{k}).Properties.VariableNames;
    for q = 1:numel(reqCols.(names{k}))
        if ~any(strcmp(vn, reqCols.(names{k}){q}))
            error('phase5_writer:schema', 'tables.%s missing required column %s.', ...
                names{k}, reqCols.(names{k}){q});
        end
    end
    % Task-15 full close: provenance + scope non-empty on every row.
    assert_ledger(tables.(names{k}), names{k}, 'provenance');
    assert_ledger(tables.(names{k}), names{k}, 'scope');
end
meta = check_meta(meta);
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk
        error('phase5_writer:mkdir', 'cannot create outDir %s (%s).', outDir, msgMk);
    end
end
% Validation pass column to 1/0 numeric for CSV cleanliness.
Tval = tables.validation;
if islogical(Tval.pass)
    Tval.pass = double(Tval.pass);
end
tout.registry = tables.registry;
tout.settings = tables.settings;
tout.faultInputs = tables.faultInputs;
tout.relayCurrents = tables.relayCurrents;
tout.coordMatrix = tables.coordMatrix;
tout.coordMargins = tables.coordMargins;
tout.duty = tables.duty;
tout.sensitivity = tables.sensitivity;
tout.validation = Tval;
for k = 1:numel(names)
    writetable(tout.(names{k}), fullfile(outDir, files{k}));
end
% Code hashes: every matlab/phase5/*.m sorted by name (Java helper).
root = ashuganj_root();
mlist = dir(fullfile(root, 'matlab', 'phase5', '*.m'));
mlist = mlist(~[mlist.isdir]);
[~, sord] = sort({mlist.name});
mlist = mlist(sord);
codeHashes = struct('file', {}, 'sha256', {});
for k = 1:numel(mlist)
    codeHashes(end + 1) = struct('file', mlist(k).name, ... %#ok<AGROW>
        'sha256', sha256file(fullfile(root, 'matlab', 'phase5', mlist(k).name)));
end
rowCounts = struct('phase5_device_registry_csv', height(tout.registry), ...
    'phase5_relay_settings_csv', height(tout.settings), ...
    'phase5_fault_inputs_csv', height(tout.faultInputs), ...
    'phase5_relay_currents_csv', height(tout.relayCurrents), ...
    'phase5_coordination_matrix_csv', height(tout.coordMatrix), ...
    'phase5_coordination_margins_csv', height(tout.coordMargins), ...
    'phase5_breaker_duty_csv', height(tout.duty), ...
    'phase5_sensitivity_csv', height(tout.sensitivity), ...
    'phase5_validation_csv', height(tout.validation));
vref = sprintf('%d/%d', meta.validation.pass, meta.validation.total);
manifest = struct( ...
    'tag', meta.tag, ...
    'timestamp_local', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), ...
    'input', struct('productionManifestSha256', meta.inputManifestSha, ...
        'productionSha256Txt', {meta.inputShaLines}, ...
        'source', 'results/phase4_fault/production (read-only; never modified)'), ...
    'rowCounts', rowCounts, ...
    'files', {{files{1}, files{2}, files{3}, files{4}, files{5}, files{6}, ...
        files{7}, files{8}, files{9}, 'manifest.json', 'run_log.txt'}}, ...
    'codeHashes', codeHashes, ...
    'validation', struct('runner', 'phase5_validate', 'reference', vref, ...
        'pass', meta.validation.pass, 'total', meta.validation.total, ...
        'note', meta.validation.note), ...
    'testCounts', struct('runner', 'run_phase5_tests', ...
        'NP', meta.testCounts.NP, 'NF', meta.testCounts.NF), ...
    'settings', {meta.settingsLines}, ...
    'notes', {{['Phase-5 protection study outputs on frozen Phase-4 production data; ' ...
        'study settings / engineering assumptions / source-backed only; ' ...
        'never manufacturer settings; ip peak is borrowed-shape design-defined, ' ...
        'never a breaker-duty input.'], meta.extraNotes{:}}});
fid = fopen(fullfile(outDir, 'manifest.json'), 'w');
if fid < 0
    error('phase5_writer:write', 'Cannot write manifest.json.');
end
fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
fclose(fid);
% Run log: settings + row counts + validation/test references.
logL = {};
logL{end + 1} = sprintf('run_phase5_production %s written %s (local)', ... %#ok<AGROW>
    meta.tag, datestr(now, 'yyyy-mm-ddTHH:MM:SS'));
logL{end + 1} = sprintf('input production manifest SHA-256: %s', meta.inputManifestSha); %#ok<AGROW>
logL{end + 1} = 'settings (T6 production path; study settings, never tuned-to-pass):'; %#ok<AGROW>
for k = 1:numel(meta.settingsLines)
    logL{end + 1} = sprintf('  %s', meta.settingsLines{k}); %#ok<AGROW>
end
rc = fieldnames(rowCounts);
for k = 1:numel(rc)
    logL{end + 1} = sprintf('rows %s = %d', rc{k}, rowCounts.(rc{k})); %#ok<AGROW>
end
logL{end + 1} = sprintf('validation live phase5_validate: %s (%s)', vref, meta.validation.note); %#ok<AGROW>
logL{end + 1} = sprintf('tests run_phase5_tests: NP=%d NF=%d', ... %#ok<AGROW>
    meta.testCounts.NP, meta.testCounts.NF);
logL{end + 1} = 'sha256.txt written after this log; it covers the 9 CSVs + manifest.json + this log.'; %#ok<AGROW>
fid = fopen(fullfile(outDir, 'run_log.txt'), 'w');
if fid < 0
    error('phase5_writer:write', 'Cannot write run_log.txt.');
end
for k = 1:numel(logL)
    fprintf(fid, '%s\n', logL{k});
end
fclose(fid);
% sha256 over the 9 CSVs + manifest + run log.
hashFiles = [files, {'manifest.json', 'run_log.txt'}];
fid = fopen(fullfile(outDir, 'sha256.txt'), 'w');
if fid < 0
    error('phase5_writer:write', 'Cannot write sha256.txt.');
end
for k = 1:numel(hashFiles)
    fprintf(fid, '%s  %s\n', sha256file(fullfile(outDir, hashFiles{k})), hashFiles{k});
end
fclose(fid);
W = struct('outDir', outDir, 'tag', meta.tag, 'files', {hashFiles}, ...
    'rowCounts', rowCounts, 'validation', meta.validation, ...
    'testCounts', meta.testCounts);
end

function meta = check_meta(meta)
%CHECK_META  Required meta fields with loud phase5-prefixed errors.
if ~isstruct(meta) || ~isscalar(meta)
    error('phase5_writer:args', 'meta must be a scalar struct (tag/validation/testCounts/settingsLines/...).');
end
if ~isfield(meta, 'tag')
    error('phase5_writer:args', 'meta.tag required (manifest tag).');
end
tag = meta.tag;
if isstring(tag) && isscalar(tag), tag = char(tag); meta.tag = tag; end
if ~ischar(tag) || isempty(strtrim(tag))
    error('phase5_writer:args', 'meta.tag must be non-empty char.');
end
if ~isfield(meta, 'inputManifestSha')
    error('phase5_writer:args', 'meta.inputManifestSha required (production manifest SHA, read-only).');
end
sh = meta.inputManifestSha;
if isstring(sh) && isscalar(sh), sh = char(sh); meta.inputManifestSha = sh; end
if ~ischar(sh) || isempty(strtrim(sh))
    error('phase5_writer:args', 'meta.inputManifestSha must be non-empty char.');
end
if ~isfield(meta, 'inputShaLines') || isempty(meta.inputShaLines)
    meta.inputShaLines = {};
end
meta.inputShaLines = as_lines(meta.inputShaLines, 'meta.inputShaLines');
if ~isfield(meta, 'validation') || ~isstruct(meta.validation) ...
        || ~all(isfield(meta.validation, {'pass', 'total', 'note'}))
    error('phase5_writer:args', 'meta.validation struct with pass/total/note required (live phase5_validate).');
end
if ~isfield(meta, 'testCounts') || ~isstruct(meta.testCounts) ...
        || ~all(isfield(meta.testCounts, {'NP', 'NF'}))
    error('phase5_writer:args', 'meta.testCounts struct with NP/NF required (run_phase5_tests).');
end
if ~isfield(meta, 'settingsLines')
    error('phase5_writer:args', 'meta.settingsLines cellstr required (T6 production settings summary).');
end
meta.settingsLines = as_lines(meta.settingsLines, 'meta.settingsLines');
if ~isfield(meta, 'extraNotes') || isempty(meta.extraNotes)
    meta.extraNotes = {};
end
meta.extraNotes = as_lines(meta.extraNotes, 'meta.extraNotes');
end

function c = as_lines(v, nm)
%AS_LINES  Normalize a cellstr/string/char setting block to cellstr.
if isstring(v), v = cellstr(v(:)); end
if ischar(v), v = cellstr(v); end
if ~iscell(v) || isempty(v)
    error('phase5_writer:args', '%s must be a non-empty cellstr.', nm);
end
c = v(:)';
for k = 1:numel(c)
    if isstring(c{k}) && isscalar(c{k}), c{k} = char(c{k}); end
    if ~ischar(c{k})
        error('phase5_writer:args', '%s entries must be char/string.', nm);
    end
end
end

function assert_ledger(T, tname, col)
%ASSERT_LEDGER  Task-15 full close: column present + every row non-empty.
if ~any(strcmp(T.Properties.VariableNames, col))
    error('phase5_writer:schema', 'tables.%s missing required column %s.', tname, col);
end
v = T.(col);
ok = true;
if iscell(v)
    for i = 1:numel(v)
        vv = v{i};
        if isstring(vv) && isscalar(vv), vv = char(vv); end
        if ~ischar(vv) || isempty(strtrim(vv)), ok = false; break; end
    end
elseif isstring(v)
    for i = 1:numel(v)
        if strlength(strtrim(v(i))) == 0, ok = false; break; end
    end
elseif ischar(v)
    if isempty(strtrim(v)), ok = false; end
else
    ok = false;
end
if ~ok
    error('phase5_writer:provenance', ...
        'tables.%s has an empty %s cell (every row needs provenance + scope).', tname, col);
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
