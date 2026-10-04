function S = phase5b_tcc(varargin)
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection_v2', 'plots');
elseif nargin == 1
    outDir = varargin{1};
    root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1};
    root = varargin{2};
else
    error('phase5b_tcc:args', 'usage: S = phase5b_tcc() or phase5b_tcc(outDir) or phase5b_tcc(outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir))
    error('phase5b_tcc:args', 'outDir must be a non-empty path (char).');
end
if ~ischar(root) || isempty(strtrim(root))
    error('phase5b_tcc:args', 'root must be a non-empty project-root path (char).');
end
if exist(root, 'dir') ~= 7
    error('phase5b_tcc:root', 'project root not found: %s', root);
end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk
        error('phase5b_tcc:mkdir', 'cannot create outDir %s (%s).', outDir, msgMk);
    end
end
R = phase5b_registry();
bl = find_by_ansi_layer(R.devices, '50/51-DT', 'PHYSICAL');
d87 = find_by_ansi_layer(R.devices, '87G', 'PHYSICAL');
FL_GENQ_A = 9.47574312698307 * 1000;
IMIN_PHASE_A = 43758.8597559;
Pb = phase5b_pickup(bl, FL_GENQ_A, IMIN_PHASE_A);
dt_Is_prim = Pb.setting;
dt_Is_sec = Pb.setting_sec_A;
tdef_s = Pb.tdef;
pickup_87G_A = double(d87.pickup_A);
pickup_87G_pu = 0.20;
ILOAD_GSUT_A = 870.772573866956;
ILOAD_Q0_A = 869.956651959241;
dGen = find_by_id(R.devices, 'GEN-51');
dHv = find_by_id(R.devices, 'GSUT-HV-51');
dQ0 = find_by_id(R.devices, 'GIS-Q0-51');
Pg = phase5b_pickup(dGen, FL_GENQ_A, IMIN_PHASE_A);
Ph = phase5b_pickup(dHv, ILOAD_GSUT_A, IMIN_PHASE_A);
Pq = phase5b_pickup(dQ0, ILOAD_Q0_A, IMIN_PHASE_A);
sGen = mk_study_setting('GEN-51', dGen, Pg);
sHv = mk_study_setting('GSUT-HV-51', dHv, Ph);
sQ0 = mk_study_setting('GIS-Q0-51', dQ0, Pq);
study_settings = [sGen, sHv, sQ0];
study_times = zeros(1, 3);
for k = 1:3
    s = study_settings(k);
    study_times(k) = phase5_time(2*s.pickup_sec, s.pickup_sec, s.TMS, s.curve);
end
dt_label = sprintf('GEN DT comparator | CT 15000/1 | Is %.4g A (%.4g A secondary)', dt_Is_prim, dt_Is_sec);
tdef_label = sprintf('DT comparator %.2f s - study assumption', tdef_s);
band_label = sprintf('GEN 87G pickup band 0.20pu approx %.1f A-prim (no curve invented)', pickup_87G_A);
physical_labels = {dt_label, tdef_label, band_label};
physical_title = 'Phase-5 physical-device study: GEN DT comparator and 87G threshold';
physical_foot = {'Study proxies; installed settings unverified', '87G threshold only; 45 ms detection proxy; high-set OFF'};
physPng = fullfile(outDir, 'tcc_physical.png');
draw_physical(dt_Is_prim, tdef_s, pickup_87G_A, dt_label, tdef_label, band_label, physical_title, physical_foot, physPng);
study_labels = cell(1, 3);
for k = 1:3
    s = study_settings(k);
    study_labels{k} = sprintf('%s | ANSI 51 OC | CT %.0f/1 | Is %.4g A-prim (%.4g A-sec) | TMS %.4g | %s', ...
        s.device_id, s.ct, s.pickup_prim, s.pickup_sec, s.TMS, s.curve);
end
study_title = sprintf('Phase-5 study TCC | TMS: GEN-51 %.2f | GSUT-51 %.2f | Q0-51 %.2f', Pg.tms, Ph.tms, Pq.tms);
study_foot = {'All currents referred to 230 kV; Q0 conditional transformer-bay mapping', 'IEC Standard Inverse study settings; CTI = 0.30 s criterion'};
studyPng = fullfile(outDir, 'tcc_study.png');
draw_study(study_settings, study_labels, study_title, study_foot, studyPng);
S = struct('physical_png', physPng, 'study_png', studyPng, ...
    'physical_title', physical_title, 'study_title', study_title, ...
    'physical_labels', {physical_labels}, 'study_labels', {study_labels}, ...
    'physical_foot', {physical_foot}, 'study_foot', {study_foot}, ...
    'dt_Is_prim', dt_Is_prim, 'dt_Is_sec', dt_Is_sec, 'tdef_s', tdef_s, ...
    'dt_label', dt_label, 'tdef_label', tdef_label, ...
    'dt_vline_style', '-', 'dt_hline_style', '--', ...
    'pickup_87G_A', pickup_87G_A, 'pickup_87G_pu', pickup_87G_pu, ...
    'study_settings', study_settings, 'study_times', study_times, 'reference_voltage_kV', 230);
fid=fopen(fullfile(outDir,'tcc_metadata.json'),'w'); fprintf(fid,'%s',jsonencode(S,'PrettyPrint',true)); fclose(fid);
end

function d = find_by_id(devices, id)
d = [];
for k = 1:numel(devices)
    did = devices(k).device_id;
    if isstring(did) && isscalar(did), did = char(did); end
    if ischar(did) && strcmp(strtrim(did), id), d = devices(k); return; end
end
if isempty(d)
    error('phase5b_tcc:devices', 'device %s not found in phase5b_registry.', id);
end
end

function d = find_by_ansi_layer(devices, ansiWant, layerWant)
d = [];
for k = 1:numel(devices)
    a = devices(k).ansi;
    if isstring(a) && isscalar(a), a = char(a); end
    L = devices(k).layer;
    if isstring(L) && isscalar(L), L = char(L); end
    if ischar(a) && ischar(L) && strcmp(strtrim(a), ansiWant) && strcmp(strtrim(L), layerWant)
        d = devices(k); return;
    end
end
if isempty(d)
    error('phase5b_tcc:devices', 'ansi %s layer %s not found in phase5b_registry.', ansiWant, layerWant);
end
end

function s = mk_study_setting(id, devRow, P)
ct = double(devRow.ct_ratio);
if ~(isscalar(ct) && isfinite(ct) && ct > 0)
    error('phase5b_tcc:ct', 'device %s needs finite ct_ratio > 0 (protection CT).', id);
end
s = struct('device_id', id, 'pickup_prim', double(P.setting), ...
    'pickup_sec', double(P.setting_sec_A), 'TMS', double(P.tms), ...
    'curve', char(P.curve), 'ct', ct, 'voltage_kV', devRow.vnom_kV, 'plot_pickup_A', double(P.setting)*devRow.vnom_kV/230);
end

function draw_physical(IsPrim, tdef, bandA, dtLabel, tdefLabel, bandLabel, titleStr, footStr, pngPath)
xmin = 500;
xmax = 2e6;
yl = [0.1, 30];
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1400 850]);
hold on;
loglog([IsPrim, IsPrim], yl, '-', 'Color', [0 0.4470 0.7410], 'LineWidth', 1.6);
text(IsPrim, yl(2), ['  ' dtLabel], 'Color', [0 0.4470 0.7410], 'FontSize', 7, 'VerticalAlignment', 'top', 'Interpreter', 'none');
loglog([xmin, xmax], [tdef, tdef], '--', 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.6);
text(xmax*0.5, tdef*1.15, ['  ' tdefLabel], 'Color', [0.8500 0.3250 0.0980], 'FontSize', 7, 'Interpreter', 'none');
loglog([bandA, bandA], yl, ':', 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.4);
text(bandA, yl(2)*0.35, ['  ' bandLabel], 'Color', [0.4660 0.6740 0.1880], 'FontSize', 7, 'Interpreter', 'none');
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('Current, A primary (log scale)');
ylabel('Time, s (log scale)');
title(titleStr, 'Interpreter', 'none');
legend({dtLabel, tdefLabel, bandLabel}, 'Location', 'southoutside', 'Interpreter', 'none', 'FontSize', 7);
grid on;
xlim([xmin, xmax]);
ylim(yl);
text(xmax*0.98, yl(2)*0.7, footStr, 'FontSize', 7, ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
    'Interpreter', 'none');
print(fig, pngPath, '-dpng');
close(fig);
if exist(pngPath, 'file') ~= 2
    error('phase5b_tcc:write', 'TCC PNG not written: %s', pngPath);
end
end

function draw_study(settings, labels, titleStr, footStr, pngPath)
n = numel(settings);
IsAll = zeros(1, n);
for k = 1:n
    IsAll(k) = settings(k).plot_pickup_A;
end
xmin = min(IsAll) * 0.5;
xmax = max(IsAll) * 100;
if ~(isfinite(xmin) && isfinite(xmax) && xmin > 0 && xmax > xmin)
    error('phase5b_tcc:limits', 'non-finite TCC current axis limits.');
end
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1400 850]);
hold on;
cols = lines(n);
for k = 1:n
    s = settings(k);
    Is = s.plot_pickup_A;
    lo = Is * 1.005;
    hi = Is * 100;
    I = logspace(log10(lo), log10(hi), 240);
    M = I / Is;
    t = phase5_curve(M, s.curve, s.TMS);
    loglog(I, t, 'Color', cols(k, :), 'LineWidth', 1.6);
end
yl = [0.01, 100];
for k = 1:n
    loglog([IsAll(k), IsAll(k)], yl, '--', 'Color', cols(k, :), 'LineWidth', 1.0);
    py = yl(2)*10^(-0.45*(k-1));
    text(IsAll(k), py, sprintf('  Is %s', settings(k).device_id), ...
        'Color', cols(k, :), 'FontSize', 8, 'VerticalAlignment', 'top');
end
set(gca, 'XScale', 'log', 'YScale', 'log');
xlabel('Current referred to 230 kV, A (log scale)');
ylabel('Time, s (log scale)');
title(titleStr, 'Interpreter', 'none');
legend(labels, 'Location', 'southoutside', 'Interpreter', 'none', 'FontSize', 7);
grid on;
xlim([xmin, xmax]);
ylim(yl);
text(xmax*0.98, yl(2)*0.7, footStr, 'FontSize', 7, ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'right', ...
    'Interpreter', 'none');
print(fig, pngPath, '-dpng');
close(fig);
if exist(pngPath, 'file') ~= 2
    error('phase5b_tcc:write', 'TCC PNG not written: %s', pngPath);
end
end
