function G = phase5_gate(ov)
%PHASE5_GATE  Phase-5 quality-gate predicate runner (Phase-5 Task 19).
%   G = PHASE5_GATE() is a read-only consumer of results/phase5_protection/
%   + PHASE5_FINAL_REPORT.md + results/phase4_fault/production/ (it modifies
%   nothing): it evaluates 17 predicates, prints a checklist, and errors
%   error('phase5_gate:fail') when any predicate fails.
%
%   G = PHASE5_GATE(ov) accepts an optional struct overriding shipped inputs
%   in-memory only (negative-path injection for tests); recognised fields:
%   faultInputs, relayCurrents, coordMatrix, coordMargins, duty,
%   sensitivity, settings, registry, validation (MATLAB tables), reportText
%   (char), noThrow (logical: return G without erroring).
%
%   G fields: .n (17), .ids (17 cellstr slugs), .pass (17 logical),
%   .note (17 cellstr), .npass (scalar count).
%
%   The 17 predicates (master §25):
%     P01 regression        R0 identities: F3 LLL OUT 50.5308851865359 kA
%                           (1e-6), F1 LG OUT 0.00727200442799167 kA (1e-9).
%     P02 cases             exactly {LF360_GAT_OUT, LF360_GAT_IN}.
%     P03 locs              exactly {F1..F5}.
%     P04 types             exactly {LLL,LG,LL,LLG}.
%     P05 ct-conversions    per-row Isec == Iprim./CT_ratio (tol 1e-9 abs).
%     P06 relay-calcs       settings anchors (GEN-51 15023.75, GEN-51N 5,
%                           GSUT-HV-51 1380, GIS-Q0-51 1043.94798235109) +
%                           GEN-51N F1 LG operating-time recomputation via
%                           phase5_time matches matrix t_down (tol 1e-9).
%     P07 matrix-complete   coordination matrix + margins 96 rows each.
%     P08 margins-numeric   finite rows margin == t_up-t_down (1e-9);
%                           non-finite rows margin NaN; margins file matches
%                           matrix margins multiset + verdict distribution.
%     P09 duty-separated    no t_up/t_down/margin columns in duty CSV.
%     P10 rating-provenance non-NOTE duty rows NOT DETERMINABLE + MISSING
%                           basis + NaN rating, never PASS/FAIL; exactly one
%                           50-kA NOTE row (+1.06%, ESTIMATED, never verdict).
%     P11 assumption-tags   every one of the 9 CSVs carries non-empty
%                           provenance + scope on every row.
%     P12 legacy-fenced     '16000' appears only in sensitivity CSV raw text.
%     P13 no-scratch        zero case-insensitive 'scratch' hits in 9 CSVs.
%     P14 manifest-hashes   recompute sha256 of the 11 sha256.txt lines.
%     P15 report-match      CSV-derived spots found in report: GIS-Q0-51
%                           pickup string, 'FAIL = <n>', 'PASS = <n>'
%                           (report-vs-CSV ONLY, never vs test literals).
%     P16 no-IEC-claim      zero 'IEC' in duty table; zero affirmative
%                           compliance-claim patterns in report.
%     P17 no-Phase3/4-change PHASE3_FINAL_REPORT.md 45504 bytes + production
%                           sha256.txt 7/7 recompute-verify.
%
%   CSV readers use readtable(fp,'Delimiter',',') (RFC-4180 quoted-comma
%   dialect). All errors are 'phase5'-prefixed.
if nargin < 1 || isempty(ov)
    ov = struct();
end
if ~isstruct(ov) || ~isscalar(ov)
    error('phase5_gate:args', 'ov must be a scalar struct (or omitted).');
end
noThrow = isfield(ov, 'noThrow') && isequal(ov.noThrow, true);
root = ashuganj_root();
outDir = fullfile(root, 'results', 'phase5_protection');
prodDir = fullfile(root, 'results', 'phase4_fault', 'production');

files9 = {'phase5_device_registry.csv', 'phase5_relay_settings.csv', ...
    'phase5_fault_inputs.csv', 'phase5_relay_currents.csv', ...
    'phase5_coordination_matrix.csv', 'phase5_coordination_margins.csv', ...
    'phase5_breaker_duty.csv', 'phase5_sensitivity.csv', ...
    'phase5_validation.csv'};
FI = getTab(ov, 'faultInputs', outDir, files9{3});
RC = getTab(ov, 'relayCurrents', outDir, files9{4});
MX = getTab(ov, 'coordMatrix', outDir, files9{5});
MG = getTab(ov, 'coordMargins', outDir, files9{6});
DU = getTab(ov, 'duty', outDir, files9{7});
SN = getTab(ov, 'sensitivity', outDir, files9{8});
ST = getTab(ov, 'settings', outDir, files9{2});
RG = getTab(ov, 'registry', outDir, files9{1});
VL = getTab(ov, 'validation', outDir, files9{9});
tabs9 = {RG, ST, FI, RC, MX, MG, DU, SN, VL};
if isfield(ov, 'reportText')
    rep = ov.reportText;
    if isstring(rep) && isscalar(rep), rep = char(rep); end
    if ~ischar(rep)
        error('phase5_gate:args', 'ov.reportText must be char.');
    end
else
    rp = fullfile(root, 'PHASE5_FINAL_REPORT.md');
    if exist(rp, 'file') ~= 2
        error('phase5_gate:missing', 'report missing: %s', rp);
    end
    rep = fileread(rp);
end
raws = cell(1, 9);
for k = 1:9
    p = fullfile(outDir, files9{k});
    if exist(p, 'file') ~= 2
        error('phase5_gate:missing', 'output CSV missing: %s', p);
    end
    raws{k} = fileread(p);
end

ids = {'regression', 'cases', 'locs', 'types', 'ct-conversions', ...
    'relay-calcs', 'matrix-complete', 'margins-numeric', 'duty-separated', ...
    'rating-provenance', 'assumption-tags', 'legacy-fenced', 'no-scratch', ...
    'manifest-hashes', 'report-match', 'no-IEC-claim', 'no-Phase3/4-change'};
pass = false(1, 17);
note = repmat({''}, 1, 17);

[pass(1), note{1}] = pRegression(FI);
[pass(2), note{2}] = pCases(FI);
[pass(3), note{3}] = pLocs(FI);
[pass(4), note{4}] = pTypes(FI);
[pass(5), note{5}] = pCT(RC);
[pass(6), note{6}] = pRelay(ST, RC, MX);
[pass(7), note{7}] = pMatrix(MX, MG);
[pass(8), note{8}] = pMargins(MX, MG);
[pass(9), note{9}] = pDutySep(DU);
[pass(10), note{10}] = pRating(DU, FI);
[pass(11), note{11}] = pTags(tabs9, files9);
[pass(12), note{12}] = pLegacy(raws, files9);
[pass(13), note{13}] = pScratch(raws);
[pass(14), note{14}] = pHashes(outDir);
[pass(15), note{15}] = pReport(ST, MX, rep);
[pass(16), note{16}] = pIEC(DU, rep);
[pass(17), note{17}] = pFreeze(root, prodDir);

G = struct();
G.n = 17;
G.ids = ids;
G.pass = pass;
G.note = note;
G.npass = sum(pass);
fprintf('phase5_gate checklist (read-only; modifies nothing):\n');
for k = 1:17
    if pass(k)
        st = 'PASS';
    else
        st = 'FAIL';
    end
    fprintf('  [%s] P%02d %-18s %s\n', st, k, ids{k}, note{k});
end
fprintf('phase5_gate: %d/17 predicates pass\n', G.npass);
if G.npass < 17 && ~noThrow
    bad = strjoin(ids(~pass), ', ');
    error('phase5_gate:fail', '%d/17 predicates pass; failures: %s.', G.npass, bad);
end
end

% =====================================================================
function T = getTab(ov, field, outDir, file)
if isfield(ov, field)
    T = ov.(field);
    if ~istable(T)
        error('phase5_gate:args', 'ov.%s must be a table.', field);
    end
    return;
end
p = fullfile(outDir, file);
if exist(p, 'file') ~= 2
    error('phase5_gate:missing', 'output CSV missing: %s', p);
end
T = readtable(p, 'Delimiter', ',');
end

function c = tcell(v)
if iscell(v)
    c = v(:);
elseif isstring(v)
    c = cellstr(v(:));
elseif ischar(v)
    c = cellstr(v);
else
    error('phase5_gate:schema', 'text column must be cell/string/char.');
end
end

function [p, n] = pRegression(FI)
locs = tcell(FI.fault_location); typs = tcell(FI.fault_type); cs = tcell(FI.caseID);
a = FI(strcmp(locs, 'F3') & strcmp(typs, 'LLL') & strcmp(cs, 'LF360_GAT_OUT'), :);
g = FI(strcmp(locs, 'F1') & strcmp(typs, 'LG') & strcmp(cs, 'LF360_GAT_OUT'), :);
if height(a) ~= 1 || height(g) ~= 1
    p = false; n = 'F3-LLL-OUT / F1-LG-OUT rows not unique-present'; return;
end
d1 = abs(a.I_primary_kA - 50.5308851865359);
d2 = abs(g.I_primary_kA - 0.00727200442799167);
p = (d1 < 1e-6) && (d2 < 1e-9);
n = sprintf('F3-LLL-OUT %.10f kA (d %.2g, tol 1e-6); F1-LG-OUT %.14f kA (d %.2g, tol 1e-9)', ...
    a.I_primary_kA, d1, g.I_primary_kA, d2);
end

function [p, n] = pCases(FI)
u = sort(tcell(unique(tcell(FI.caseID))));
p = isequal(u, {'LF360_GAT_IN'; 'LF360_GAT_OUT'});
n = sprintf('cases {%s}', strjoin(u', ', '));
end

function [p, n] = pLocs(FI)
u = sort(tcell(unique(tcell(FI.fault_location))));
p = isequal(u, {'F1'; 'F2'; 'F3'; 'F4'; 'F5'});
n = sprintf('locs {%s}', strjoin(u', ', '));
end

function [p, n] = pTypes(FI)
u = sort(tcell(unique(tcell(FI.fault_type))));
p = isequal(u, {'LG'; 'LL'; 'LLG'; 'LLL'});
n = sprintf('types {%s}', strjoin(u', ', '));
end

function [p, n] = pCT(RC)
if ~all(isfinite(double(RC.CT_ratio)) & double(RC.CT_ratio) > 0)
    p = false; n = 'non-finite/non-positive CT_ratio present'; return;
end
dev = max(abs(double(RC.I_secondary_A) - double(RC.I_primary_A) ./ double(RC.CT_ratio)));
p = dev <= 1e-9;
n = sprintf('%d rows Isec==Iprim/CT max-dev %.3g (tol 1e-9)', height(RC), dev);
end

function [p, n] = pRelay(ST, RC, MX)
ids = tcell(ST.device_id);
r51 = ST(strcmp(ids, 'GEN-51'), :);
r51N = ST(strcmp(ids, 'GEN-51N'), :);
rGS = ST(strcmp(ids, 'GSUT-HV-51'), :);
rQ0 = ST(strcmp(ids, 'GIS-Q0-51'), :);
if height(r51) ~= 1 || height(r51N) ~= 1 || height(rGS) ~= 1 || height(rQ0) ~= 1
    p = false; n = 'settings device rows not unique-present'; return;
end
c1 = abs(r51.setting_A_primary - 15023.75);
c2 = abs(r51N.setting_A_primary - 5);
c3 = abs(rGS.setting_A_primary - 1380);
c4 = abs(rQ0.setting_A_primary - 1043.94798235109);
locs = tcell(RC.fault_location); typs = tcell(RC.fault_type);
cs = tcell(RC.caseID); dv = tcell(RC.device_id);
rr = RC(strcmp(locs, 'F1') & strcmp(typs, 'LG') & strcmp(cs, 'LF360_GAT_OUT') ...
    & strcmp(dv, 'GEN-51N'), :);
if height(rr) ~= 1
    p = false; n = 'GEN-51N F1-LG-OUT relay-current row not unique'; return;
end
cv = tcell(r51N.curve); tms = double(r51N.tms);
t = phase5_time(double(rr.I_secondary_A), double(r51N.setting_A_primary) ...
    / double(r51N.ct_ratio), tms, char(cv{1}));
ml = tcell(MX.fault_location); mt = tcell(MX.fault_type);
mc = tcell(MX.caseID); md = tcell(MX.downstream);
mr = MX(strcmp(ml, 'F1') & strcmp(mt, 'LG') & strcmp(mc, 'LF360_GAT_OUT') ...
    & strcmp(md, 'GEN-51N'), :);
if height(mr) ~= 1
    p = false; n = 'GEN-51N F1-LG-OUT matrix row not unique'; return;
end
c5 = abs(t - double(mr.t_down_s));
p = (c1 < 1e-9) && (c2 < 1e-12) && (c3 < 1e-9) && (c4 < 1e-6) && (c5 < 1e-9);
n = sprintf(['GEN-51 %.2f (d %.2g); GEN-51N %.4f; GSUT %.2f; GIS-Q0 %.8f; ' ...
    'EF t recompute %.8f s vs matrix %.8f s (d %.2g)'], ...
    r51.setting_A_primary, c1, r51N.setting_A_primary, ...
    rGS.setting_A_primary, rQ0.setting_A_primary, t, double(mr.t_down_s), c5);
end

function [p, n] = pMatrix(MX, MG)
p = (height(MX) == 96) && (height(MG) == 96);
n = sprintf('coordination_matrix %d rows; coordination_margins %d rows (expect 96/96)', ...
    height(MX), height(MG));
end

function [p, n] = pMargins(MX, MG)
fin = isfinite(double(MX.t_down_s)) & isfinite(double(MX.t_up_s));
d = abs(double(MX.margin_s(fin)) - (double(MX.t_up_s(fin)) - double(MX.t_down_s(fin))));
okFin = all(d < 1e-9);
okNaN = all(isnan(double(MX.margin_s(~fin))));
a = sort(double(MX.margin_s)); b = sort(double(MG.margin_s));
okSet = isequal(isnan(a), isnan(b)) ...
    && all(abs(a(~isnan(a)) - b(~isnan(b))) < 1e-12);
[ua, ~, ia] = unique(tcell(MX.verdict)); ca = accumarray(ia, 1);
[ub, ~, ib] = unique(tcell(MG.verdict)); cb = accumarray(ib, 1);
okV = isequal(sortrows([ua num2cell(ca)]), sortrows([ub num2cell(cb)]));
p = okFin && okNaN && okSet && okV;
n = sprintf(['finite %d max-dev %.3g; non-finite %d all-NaN %d; ' ...
    'margins-file multiset %d; verdict-dist %d'], ...
    sum(fin), max([d; 0]), sum(~fin), okNaN, okSet, okV);
end

function [p, n] = pDutySep(DU)
vn = DU.Properties.VariableNames;
bad = {};
for k = 1:numel(vn)
    v = vn{k};
    if ~isempty(strfind(v, 'margin')) || ~isempty(strfind(v, 't_up')) ...
            || ~isempty(strfind(v, 't_down'))
        bad{end + 1} = v; %#ok<AGROW>
    end
end
p = isempty(bad);
if p
    n = sprintf('duty %d cols; no time/margin columns', numel(vn));
else
    n = sprintf('forbidden duty columns: %s', strjoin(bad, ', '));
end
end

function [p, n] = pRating(DU, FI)
isNote = strcmp(tcell(DU.verdict), 'NOTE');
Dd = DU(~isNote, :);
Dn = DU(isNote, :);
honest = all(strcmp(tcell(Dd.verdict), 'NOT DETERMINABLE FROM AVAILABLE DATA')) ...
    && ~any(strcmp(tcell(Dd.verdict), 'PASS')) ...
    && ~any(strcmp(tcell(Dd.verdict), 'FAIL')) ...
    && all(isnan(double(Dd.rating_kA)));
miss = true;
bs = tcell(Dd.basis);
for k = 1:numel(bs)
    if isempty(strfind(bs{k}, 'MISSING')), miss = false; break; end
end
locs = tcell(FI.fault_location); typs = tcell(FI.fault_type); cs = tcell(FI.caseID);
f3 = FI(strcmp(locs, 'F3') & strcmp(typs, 'LLL') & strcmp(cs, 'LF360_GAT_OUT'), :);
oneNote = (sum(isNote) == 1) && (height(f3) == 1) ...
    && (abs(double(Dn.I_sym_kA) - double(f3.I_primary_kA)) < 1e-6) ...
    && (abs(double(Dn.rating_kA) - 50.0) < 1e-12) ...
    && ~isempty(strfind(Dn.note{1}, '+1.06%')) ...
    && ~isempty(strfind(lower(Dn.basis{1}), 'estimat')) ...
    && strcmp(Dn.verdict{1}, 'NOTE');
q0only = all(strcmp(tcell(DU.breaker_ref), 'Q0'));
p = honest && miss && oneNote && q0only;
n = sprintf(['%d duty rows NOT DETERMINABLE/MISSING/NaN-rating %d; ' ...
    'one NOTE %.4f kA +1.06%% ESTIMATED (never PASS/FAIL) %d; Q0-only %d'], ...
    height(Dd), honest && miss, double(Dn.I_sym_kA), oneNote, q0only);
end

function [p, n] = pTags(tabs9, files9)
bad = 0;
for k = 1:9
    T = tabs9{k};
    vn = T.Properties.VariableNames;
    if ~any(strcmp(vn, 'provenance')) || ~any(strcmp(vn, 'scope'))
        bad = bad + 1; continue;
    end
    if ~colFull(T.provenance) || ~colFull(T.scope)
        bad = bad + 1;
    end
end
p = (bad == 0);
n = sprintf('provenance+scope non-empty on all 9 CSVs (tables failing: %d)', bad);
end

function ok = colFull(v)
ok = true;
if iscell(v)
    for i = 1:numel(v)
        vv = v{i};
        if isstring(vv) && isscalar(vv), vv = char(vv); end
        if ~ischar(vv) || isempty(strtrim(vv)), ok = false; return; end
    end
elseif isstring(v)
    for i = 1:numel(v)
        if strlength(strtrim(v(i))) == 0, ok = false; return; end
    end
elseif ischar(v)
    if isempty(strtrim(v)), ok = false; end
else
    ok = false;
end
end

function [p, n] = pLegacy(raws, files9)
hit = false(1, 9);
for k = 1:9
    hit(k) = ~isempty(strfind(raws{k}, '16000'));
end
idx = find(hit, 1);
p = (sum(hit) == 1) && ~isempty(idx) && ~isempty(strfind(files9{idx}, 'sensitivity'));
n = sprintf('''16000'' in %d/9 CSVs (%s)', sum(hit), strjoin(files9(hit), ', '));
if isempty(strjoin(files9(hit), ', '))
    n = '''16000'' in 0/9 CSVs (expect sensitivity only)';
end
end

function [p, n] = pScratch(raws)
h = 0;
for k = 1:9
    h = h + numel(strfind(lower(raws{k}), 'scratch'));
end
p = (h == 0);
n = sprintf('case-insensitive ''scratch'' hits in 9 CSVs: %d', h);
end

function [p, n] = pHashes(outDir)
sp = fullfile(outDir, 'sha256.txt');
if exist(sp, 'file') ~= 2
    error('phase5_gate:missing', 'sha256.txt missing: %s', sp);
end
lines = strsplit(strtrim(fileread(sp)), char(10));
lines = lines(~cellfun(@isempty, strtrim(lines)));
if numel(lines) ~= 11
    p = false; n = sprintf('sha256.txt has %d lines (expect 11)', numel(lines)); return;
end
bad = 0;
for k = 1:numel(lines)
    ln = strtrim(lines{k});
    sp1 = strfind(ln, ' ');
    if isempty(sp1)
        bad = bad + 1; continue;
    end
    expH = ln(1:sp1(1) - 1);
    fname = strtrim(ln(sp1(end) + 1:end));
    fp = fullfile(outDir, fname);
    if exist(fp, 'file') ~= 2
        bad = bad + 1; continue;
    end
    if ~strcmp(sha256file(fp), lower(expH))
        bad = bad + 1;
    end
end
p = (bad == 0);
n = sprintf('sha256 recompute-verify 11/11 lines (mismatches: %d)', bad);
end

function [p, n] = pReport(ST, MX, rep)
ids = tcell(ST.device_id);
rQ0 = ST(strcmp(ids, 'GIS-Q0-51'), :);
if height(rQ0) ~= 1
    p = false; n = 'GIS-Q0-51 settings row not unique'; return;
end
sPick = sprintf('%.6f', double(rQ0.setting_A_primary));
c1 = ~isempty(strfind(rep, sPick));
nFail = sum(strcmp(tcell(MX.verdict), 'FAIL'));
sF = sprintf('FAIL = %d', nFail);
c2 = ~isempty(strfind(rep, sF));
nPass = sum(strcmp(tcell(MX.verdict), 'PASS'));
sP = sprintf('PASS = %d', nPass);
c3 = ~isempty(strfind(rep, sP));
p = c1 && c2 && c3;
n = sprintf('CSV-derived spots in report: GIS-Q0-51 ''%s'' %d; ''%s'' %d; ''%s'' %d (report-vs-CSV only)', ...
    sPick, c1, sF, c2, sP, c3);
end

function [p, n] = pIEC(DU, rep)
pats = {'IEC compliant', 'IEC-compliant', 'IEC 60909', 'fully realistic', ...
    'exact plant settings', 'actual relay settings'};
repL = lower(rep);
hitR = {};
for k = 1:numel(pats)
    if ~isempty(strfind(repL, lower(pats{k})))
        hitR{end + 1} = pats{k}; %#ok<AGROW>
    end
end
hitD = table_has(DU, 'IEC');
p = isempty(hitR) && ~hitD;
if p
    n = 'zero IEC in duty table; zero affirmative compliance-claim patterns in report';
else
    n = sprintf('report hits {%s}; duty IEC %d', strjoin(hitR, '; '), hitD);
end
end

function tf = table_has(D, pat)
tf = ~isempty(strfind(strjoin(D.Properties.VariableNames, '|'), pat));
if tf, return; end
for k = 1:numel(D.Properties.VariableNames)
    col = D.(D.Properties.VariableNames{k});
    if iscell(col)
        for i = 1:numel(col)
            vv = col{i};
            if (ischar(vv) || isstring(vv)) && ~isempty(strfind(char(vv), pat))
                tf = true; return;
            end
        end
    elseif ischar(col) || isstring(col)
        if ~isempty(strfind(char(col), pat)), tf = true; return; end
    end
end
end

function [p, n] = pFreeze(root, prodDir)
fp = fullfile(root, 'PHASE3_FINAL_REPORT.md');
d = dir(fp);
if numel(d) ~= 1 || d.isdir
    error('phase5_gate:missing', 'PHASE3_FINAL_REPORT.md missing.');
end
okSize = (d.bytes == 45504);
sp = fullfile(prodDir, 'sha256.txt');
if exist(sp, 'file') ~= 2
    error('phase5_gate:missing', 'production sha256.txt missing: %s', sp);
end
lines = strsplit(strtrim(fileread(sp)), char(10));
lines = lines(~cellfun(@isempty, strtrim(lines)));
okN = (numel(lines) == 7);
bad = 0;
for k = 1:numel(lines)
    ln = strtrim(lines{k});
    sp1 = strfind(ln, ' ');
    if isempty(sp1)
        bad = bad + 1; continue;
    end
    expH = ln(1:sp1(1) - 1);
    fname = strtrim(ln(sp1(end) + 1:end));
    fpp = fullfile(prodDir, fname);
    if exist(fpp, 'file') ~= 2
        bad = bad + 1; continue;
    end
    if ~strcmp(sha256file(fpp), lower(expH))
        bad = bad + 1;
    end
end
p = okSize && okN && (bad == 0);
n = sprintf('PHASE3_FINAL_REPORT.md %d bytes (expect 45504) %d; production sha256 %d/7 verify (mismatches %d)', ...
    d.bytes, okSize, numel(lines) - bad, bad);
end

function hex = sha256file(path)
md = java.security.MessageDigest.getInstance('SHA-256');
jpath = java.io.File(path).toPath();
md.update(java.nio.file.Files.readAllBytes(jpath));
dig = md.digest();
bi = java.math.BigInteger(1, dig);
hex = char(bi.toString(16));
hex = [repmat('0', 1, 64 - numel(hex)) hex];
end
