function S = phase5_tcc(varargin)
%PHASE5_TCC  TCC plot generator (Phase-5 Task 9).
%   S = PHASE5_TCC() writes the two locked TCC figures headlessly:
%     results/phase5_protection/plots/tcc_gen.png   generator zone
%       (GEN-51 + GEN-51N + GSUT-HV-51, F1 LLL/LG branch-current markers:
%       GEN_Q 55.05 kA LLL / 8.41 kA LG phase, 7.27 A earth)
%     results/phase5_protection/plots/tcc_grid.png  grid zone
%       (GIS-Q0-51 + GSUT-HV-51, F3 markers: total 50.53 kA LLL with
%       branch annotation)
%   S = PHASE5_TCC(outDir) writes into outDir; S = PHASE5_TCC(outDir, root)
%   reads Phase-4 production via root (default ashuganj_root()).
%
%   Curves come from the locked library only: settings via PHASE5_REGISTRY
%   + PHASE5_PICKUP (T6 fallbacks identical to phase5_coord: GEN-51
%   15023.75 A / GEN-51N 5 A / GSUT-HV-51 1380 A / GIS-Q0-51 2400 A
%   primary; TMS study defaults GEN 0.1 / GSUT 0.2 / GIS 0.3; SI), times
%   via PHASE5_CURVE / PHASE5_CURVE_DT (never hardcoded). Fault markers
%   are SOURCE-BACKED branch through-currents from PHASE5_IMPORT
%   (leg_GEN_kA / leg_GSUT_HV_kA / leg_GRID_kA / leg_LINE_total_kA proxy),
%   never net totals; earth marker is the 7.27 A total (3I0 single count).
%   Log-log current (A secondary) vs time (s); each curve labelled
%   device/function/CT/pickup/TMS/curve; pickup points + fault markers
%   plotted. No relay-manufacturer strings anywhere (study settings only).
%   Figures are headless-safe (Visible off). All errors 'phase5'-prefixed.
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection', 'plots');
elseif nargin == 1
    outDir = varargin{1};
    root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1};
    root = varargin{2};
else
    error('phase5_tcc:args', 'usage: S = phase5_tcc() or phase5_tcc(outDir) or phase5_tcc(outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir))
    error('phase5_tcc:args', 'outDir must be a non-empty path (char).');
end
if ~ischar(root) || isempty(strtrim(root))
    error('phase5_tcc:args', 'root must be a non-empty project-root path (char).');
end
if exist(root, 'dir') ~= 7
    error('phase5_tcc:root', 'project root not found: %s', root);
end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk
        error('phase5_tcc:mkdir', 'cannot create outDir %s (%s).', outDir, msgMk);
    end
end

R = phase5_registry();
Ti = phase5_import(root);
IminPhase = import_min_phase(Ti);
IminEarth = import_min_earth(Ti);

sGEN = resolve_setting(R.devices, 'GEN-51', IminPhase, IminEarth);
sEF = resolve_setting(R.devices, 'GEN-51N', IminPhase, IminEarth);
sHV = resolve_setting(R.devices, 'GSUT-HV-51', IminPhase, IminEarth);
sQ0 = resolve_setting(R.devices, 'GIS-Q0-51', IminPhase, IminEarth);

% ---- SOURCE-BACKED branch markers, case LF360_GAT_OUT ----
mLLL = get_markers(Ti, 'F1', 'LLL');
mLG = get_markers(Ti, 'F1', 'LG');
mF3 = get_markers(Ti, 'F3', 'LLL');

% ---- Generator-zone figure ----
genDevs = {sGEN, sEF, sHV};
genTitle = 'Phase-5 generator-zone TCC (study settings, SI study curves)';
genMarks = {
    struct('dev', 'GEN-51', 'prim_A', mLLL.GEN_A, ...
        'tag', sprintf('F1 LLL GEN_Q %.2f kA-prim', mLLL.GEN_A / 1000)), ...
    struct('dev', 'GEN-51', 'prim_A', mLG.GEN_A, ...
        'tag', sprintf('F1 LG GEN_Q %.2f kA-prim (phase branch)', mLG.GEN_A / 1000)), ...
    struct('dev', 'GEN-51N', 'prim_A', mLG.earth_A, ...
        'tag', sprintf('F1 LG earth %.2f A-prim (3I0 single count)', mLG.earth_A)), ...
    struct('dev', 'GSUT-HV-51', 'prim_A', mLLL.HV_A, ...
        'tag', sprintf('F1 LLL GSUT_HV %.2f kA-prim', mLLL.HV_A / 1000)), ...
    struct('dev', 'GSUT-HV-51', 'prim_A', mLG.HV_A, ...
        'tag', sprintf('F1 LG GSUT_HV %.2f kA-prim', mLG.HV_A / 1000)), ...
    };
genFoot = {'SOURCE-BACKED: LF360_GAT_OUT (F1 LLL tot 126.21 kA; F1 LG tot 7.27 A)', ...
    'F1 LG GEN_Q 8.41 kA-prim phase branch below GEN-51 Is: honest NO-TRIP', ...
    'STUDY pickups/TMS/SI; CTI 0.3 s not shown'};
genPng = fullfile(outDir, 'tcc_gen.png');
genLabels = draw_tcc(genDevs, genMarks, genTitle, genFoot, genPng);

% ---- Grid-zone figure ----
gridDevs = {sQ0, sHV};
gridMarks = {
    struct('dev', 'GIS-Q0-51', 'prim_A', mF3.LINE_A, ...
        'tag', sprintf('F3 LLL LINE_Q9 %.2f kA-prim (branch of %.2f kA total)', ...
        mF3.LINE_A / 1000, mF3.total_kA)), ...
    struct('dev', 'GSUT-HV-51', 'prim_A', mF3.HV_A, ...
        'tag', sprintf('F3 LLL GSUT_HV %.2f kA-prim (branch of %.2f kA total)', ...
        mF3.HV_A / 1000, mF3.total_kA)), ...
    };
gridTitle = 'Phase-5 grid-zone TCC (study settings, SI study curves)';
gridFoot = {'SOURCE-BACKED: LF360_GAT_OUT F3 LLL tot 50.53 kA', ...
    'LINE_Q9 proxy leg_LINE_total_kA; STUDY pickups/TMS/SI'};
gridPng = fullfile(outDir, 'tcc_grid.png');
gridLabels = draw_tcc(gridDevs, gridMarks, gridTitle, gridFoot, gridPng);

markers = struct( ...
    'F1_LLL_total_kA', mLLL.total_kA, ...
    'F1_LLL_GENkA', mLLL.GEN_A / 1000, ...
    'F1_LLL_HVkA', mLLL.HV_A / 1000, ...
    'F1_LLL_GRIDkA', mLLL.GRID_A / 1000, ...
    'F1_LG_total_A', mLG.earth_A, ...
    'F1_LG_GENkA', mLG.GEN_A / 1000, ...
    'F1_LG_HVkA', mLG.HV_A / 1000, ...
    'F1_LG_earth_A', mLG.earth_A, ...
    'F1_LLL_GEN51_t', optime(sGEN, mLLL.GEN_A), ...
    'F1_LG_GEN51N_t', optime(sEF, mLG.earth_A), ...
    'F3_LLL_total_kA', mF3.total_kA, ...
    'F3_LLL_LINEkA', mF3.LINE_A / 1000, ...
    'F3_LLL_HVkA', mF3.HV_A / 1000, ...
    'F3_LLL_GENkA', mF3.GEN_A / 1000);
settings = [sGEN, sEF, sHV, sQ0];
S = struct('gen_png', genPng, 'grid_png', gridPng, ...
    'gen_title', genTitle, 'grid_title', gridTitle, ...
    'gen_labels', {genLabels}, 'grid_labels', {gridLabels}, ...
    'gen_devices', {{'GEN-51', 'GEN-51N', 'GSUT-HV-51'}}, ...
    'grid_devices', {{'GIS-Q0-51', 'GSUT-HV-51'}}, ...
    'settings', settings, 'markers', markers);
end

function s = resolve_setting(devices, id, IminPhase, IminEarth)
%RESOLVE_SETTING  Pickup/TMS/curve/CT per device (T6 + study defaults, coord-consistent).
d = [];
for k = 1:numel(devices)
    did = devices(k).device_id;
    if isstring(did) && isscalar(did), did = char(did); end
    if ischar(did) && strcmp(strtrim(did), id), d = devices(k); break; end
end
if isempty(d)
    error('phase5_tcc:devices', 'device %s not found in phase5_registry.', id);
end
ct = double(d.ct_ratio);
if ~(isscalar(ct) && isfinite(ct) && ct > 0)
    error('phase5_tcc:ct', 'device %s needs finite ct_ratio > 0 (protection CT).', id);
end
pk = double(d.pickup_A);
if isscalar(pk) && isfinite(pk) && pk > 0
    pickupPrim = pk;
else
    if strcmp(id, 'GEN-51N')
        P = phase5_pickup(d, 0, IminEarth);
    else
        rA = double(d.rated_A);
        if ~(isscalar(rA) && isfinite(rA) && rA > 0)
            error('phase5_tcc:load', ['phase5_tcc: %s needs finite rated_A as Iload proxy ', ...
                'for T6 fallback (NOT DETERMINABLE otherwise).'], id);
        end
        P = phase5_pickup(d, rA, IminPhase);
    end
    pickupPrim = P.setting;
end
tm = double(d.tms);
if isscalar(tm) && isfinite(tm) && tm > 0
    TMS = tm;
else
    if strncmp(id, 'GEN', 3)
        TMS = 0.1;
    elseif strncmp(id, 'GSUT', 4)
        TMS = 0.2;
    elseif strncmp(id, 'GIS', 3)
        TMS = 0.3;
    else
        error('phase5_tcc:tms', 'no TMS study default for device %s (registry tms NaN).', id);
    end
end
cv = d.curve;
if isstring(cv) && isscalar(cv), cv = char(cv); end
if ischar(cv) && ~isempty(strtrim(cv))
    cv = upper(strtrim(cv));
    if ~any(strcmp(cv, {'SI', 'VI', 'EI', 'DT'}))
        error('phase5_tcc:curve', 'device %s curve %s unsupported (need SI/VI/EI/DT).', id, cv);
    end
else
    cv = 'SI';
end
a = d.ansi;
if isstring(a) && isscalar(a), a = char(a); end
if ~ischar(a), a = ''; end
a = strtrim(a);
dt2 = d.device_type;
if isstring(dt2) && isscalar(dt2), dt2 = char(dt2); end
if ~ischar(dt2), dt2 = ''; end
dt2 = strtrim(dt2);
if strcmp(dt2, 'ef') || strcmp(a, '51N')
    fn = sprintf('ANSI %s EF', a);
else
    fn = sprintf('ANSI %s OC', a);
end
s = struct('device_id', id, 'func', strtrim(fn), 'ct', ct, ...
    'pickup_prim', pickupPrim, 'pickup_sec', pickupPrim / ct, ...
    'TMS', TMS, 'curve', cv);
end

function v = import_min_phase(Ti)
%IMPORT_MIN_PHASE  Minimum phase-fault total (LLL/LL/LLG, never LG earth).
typs = tocell(Ti.fault_type);
ph = strcmp(typs, 'LLL') | strcmp(typs, 'LL') | strcmp(typs, 'LLG');
if any(ph)
    v = min(double(Ti.I_primary_A(ph)));
else
    v = min(double(Ti.I_primary_A));
end
end

function v = import_min_earth(Ti)
%IMPORT_MIN_EARTH  Minimum 3I0 earth total (LG-exact If; LLG unknown -> skip).
typs = tocell(Ti.fault_type);
em = strcmp(typs, 'LG');
if any(em)
    v = min(double(Ti.I_primary_A(em)));
else
    v = 7.27200442799167;  % F1-LG-OUT T1 identity fallback (SOURCE-BACKED constant)
end
end

function m = get_markers(Ti, loc, typ)
%GET_MARKERS  SOURCE-BACKED branch markers for one (LF360_GAT_OUT, loc, typ) combo.
cs = 'LF360_GAT_OUT';
locs = tocell(Ti.fault_location);
typs = tocell(Ti.fault_type);
cases = tocell(Ti.caseID);
hit = strcmp(locs, loc) & strcmp(typs, typ) & strcmp(cases, cs);
if sum(hit) ~= 1
    error('phase5_tcc:markers', 'need exactly one %s %s %s row (got %d).', cs, loc, typ, sum(hit));
end
r = Ti(hit, :);
req = {'I_primary_kA', 'I_primary_A', 'leg_GEN_kA', 'leg_GSUT_HV_kA', ...
    'leg_GRID_kA', 'leg_LINE_total_kA'};
for k = 1:numel(req)
    if ~any(strcmp(Ti.Properties.VariableNames, req{k}))
        error('phase5_tcc:markers', 'phase5_import table missing column %s.', req{k});
    end
end
GEN_A = double(r.leg_GEN_kA) * 1000;
HV_A = double(r.leg_GSUT_HV_kA) * 1000;
GRID_A = double(r.leg_GRID_kA) * 1000;
LINE_A = double(r.leg_LINE_total_kA) * 1000;
if ~all(isfinite([GEN_A, HV_A, GRID_A, LINE_A]))
    error('phase5_tcc:markers', ['phase5_tcc: branch legs missing for %s %s %s ', ...
        '(MISSING-leg, never fabricated).'], cs, loc, typ);
end
m = struct('total_kA', double(r.I_primary_kA), ...
    'total_A', double(r.I_primary_A), ...
    'earth_A', double(r.I_primary_A), ...
    'GEN_A', GEN_A, 'HV_A', HV_A, 'GRID_A', GRID_A, 'LINE_A', LINE_A);
end

function t = optime(s, Iprim_A)
%OPTIME  Operating time via the locked library (secondary vs secondary pickup).
t = phase5_time(Iprim_A / s.ct, s.pickup_prim / s.ct, s.TMS, s.curve);
end

function labels = draw_tcc(devs, marks, titleStr, footStr, pngPath)
%DRAW_TCC  Headless log-log TCC figure: library curves + pickup + fault markers.
n = numel(devs);
IsAll = zeros(1, n);
secMarks = [];
for k = 1:n
    IsAll(k) = devs{k}.pickup_sec;
end
for k = 1:numel(marks)
    s = setting_of(devs, marks{k}.dev);
    secMarks(end + 1) = marks{k}.prim_A / s.ct; %#ok<AGROW>
end
xmin = min([IsAll * 0.5, secMarks * 0.5]);
xmax = max([IsAll * 100, secMarks * 6]);
if ~(isfinite(xmin) && isfinite(xmax) && xmin > 0 && xmax > xmin)
    error('phase5_tcc:limits', 'non-finite TCC current axis limits.');
end
fig = figure('Visible', 'off', 'Color', 'white');
hold on;
labels = cell(1, n);
cols = lines(n);
for k = 1:n
    s = devs{k};
    Is = s.pickup_sec;
    lo = Is * 1.005;
    hi = max(Is * 100, max(secMarks(secMarks > Is)) * 3);
    if ~isfinite(hi) || hi <= lo, hi = Is * 100; end
    I = logspace(log10(lo), log10(hi), 240);
    M = I / Is;
    if strcmp(s.curve, 'DT')
        t = phase5_curve_dt(I, Is, s.TMS);
    else
        t = phase5_curve(M, s.curve, s.TMS);
    end
    loglog(I, t, 'Color', cols(k, :), 'LineWidth', 1.6);
    labels{k} = sprintf('%s | %s | CT %.0f/1 | Is %.4g A-sec (%.2f A-prim) | TMS %.4g | %s', ...
        s.device_id, s.func, s.ct, Is, s.pickup_prim, s.TMS, s.curve);
end
% Pickup points: dashed verticals at each Is (labels staggered: first on top).
yl = [0.01, 100];
for k = 1:n
    loglog([IsAll(k), IsAll(k)], yl, '--', 'Color', cols(k, :), 'LineWidth', 1.0);
    if k == 1
        py = yl(2);
    else
        py = yl(2) * 0.35;
    end
    text(IsAll(k), py, sprintf('  Is %s', devs{k}.device_id), ...
        'Color', cols(k, :), 'FontSize', 8, 'VerticalAlignment', 'top');
end
% Fault markers: operating points with primary/secondary/time tags
% (staggered, edge-aware: right-half markers right-align so text is not clipped).
syms = {'o', 's', 'd', '^', 'v', 'p'};
dy = [2.0, 0.5];
for k = 1:numel(marks)
    s = setting_of(devs, marks{k}.dev);
    Isec = marks{k}.prim_A / s.ct;
    tOp = optime(s, marks{k}.prim_A);
    if ~isfinite(tOp), continue; end
    idx = dev_index(devs, marks{k}.dev);
    loglog(Isec, tOp, syms{mod(k - 1, numel(syms)) + 1}, ...
        'Color', cols(idx, :), 'MarkerFaceColor', cols(idx, :), ...
        'MarkerSize', 7, 'LineWidth', 1.2);
    ty = tOp * dy(mod(k - 1, 2) + 1);
    if Isec > xmax / 8
        text(Isec * 0.97, ty, sprintf('%s (%.4g A-sec, %.4g s)', marks{k}.tag, Isec, tOp), ...
            'Color', cols(idx, :), 'FontSize', 7, ...
            'HorizontalAlignment', 'right');
    else
        text(Isec, ty, sprintf('  %s (%.4g A-sec, %.4g s)', marks{k}.tag, Isec, tOp), ...
            'Color', cols(idx, :), 'FontSize', 7);
    end
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('Current, A secondary (log scale)');
ylabel('Time, s (log scale)');
title(titleStr, 'Interpreter', 'none');
legend(labels, 'Location', 'best', 'Interpreter', 'none', 'FontSize', 7);
grid on;
xlim([xmin, xmax]);
ylim(yl);
text(xmax * 0.98, yl(2) * 0.7, footStr, 'FontSize', 7, ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
    'Interpreter', 'none');
print(fig, pngPath, '-dpng');
close(fig);
if exist(pngPath, 'file') ~= 2
    error('phase5_tcc:write', 'TCC PNG not written: %s', pngPath);
end
end

function s = setting_of(devs, id)
%SETTING_OF  Find device setting struct by id.
for k = 1:numel(devs)
    if strcmp(devs{k}.device_id, id), s = devs{k}; return; end
end
error('phase5_tcc:devices', 'marker device %s not in this TCC figure.', id);
end

function k = dev_index(devs, id)
%DEV_INDEX  1-based index of device id in figure device list.
for k = 1:numel(devs)
    if strcmp(devs{k}.device_id, id), return; end
end
error('phase5_tcc:devices', 'marker device %s not in this TCC figure.', id);
end

function c = tocell(v)
%TOCELL  Normalize table text column to cellstr.
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
    error('phase5_tcc:schema', 'text column must be cell/string/char.');
end
end
