function [np, nf] = test_phase5_tcc()
%TEST_PHASE5_TCC  Phase-5 Task 9 TCC plot generator tests (TDD).
%   Locks: phase5_tcc() writes results/phase5_protection/plots/tcc_gen.png
%   (GEN-51 + GEN-51N + GSUT-HV-51 curves, F1 LLL/LG branch-current markers:
%   GEN_Q 55.05 kA LLL / 8.41 kA LG phase, 7.27 A earth) and tcc_grid.png
%   (GIS-Q0-51 + GSUT-HV-51, F3 total 50.53 kA LLL with branch annotation).
%   PNGs exist + non-zero bytes; each curve label carries device/function/
%   CT/pickup/TMS/curve; titles/labels scanned for fabricated manufacturer
%   strings; markers source-backed (branch, never net total); marker times
%   reproduce phase5_time (curves from the phase5_curve library). Headless-
%   safe figure code. All errors phase5-prefixed.
T = t_case('test_phase5_tcc');
root = ashuganj_root();
S = phase5_tcc();
T = T.chk(isstruct(S) && isfield(S, 'gen_png') && isfield(S, 'grid_png'), ...
    'phase5_tcc returns struct with gen_png/grid_png');
expGen = fullfile(root, 'results', 'phase5_protection', 'plots', 'tcc_gen.png');
expGrid = fullfile(root, 'results', 'phase5_protection', 'plots', 'tcc_grid.png');
T = T.chk(strcmp(S.gen_png, expGen), 'gen PNG path results/phase5_protection/plots/tcc_gen.png');
T = T.chk(strcmp(S.grid_png, expGrid), 'grid PNG path results/phase5_protection/plots/tcc_grid.png');
T = T.chk(exist(expGen, 'file') == 2, 'tcc_gen.png exists');
T = T.chk(exist(expGrid, 'file') == 2, 'tcc_grid.png exists');
d1 = dir(expGen); d2 = dir(expGrid);
T = T.chk(d1.bytes > 0, 'tcc_gen.png non-zero bytes');
T = T.chk(d2.bytes > 0, 'tcc_grid.png non-zero bytes');
% Curves contain expected device labels (delimiter-pinned: GEN-51 vs GEN-51N).
T = T.chk(hasTok(S.gen_labels, 'GEN-51'), 'gen curves contain GEN-51 label');
T = T.chk(hasTok(S.gen_labels, 'GEN-51N'), 'gen curves contain GEN-51N label');
T = T.chk(hasTok(S.gen_labels, 'GSUT-HV-51'), 'gen curves contain GSUT-HV-51 label');
T = T.chk(hasTok(S.grid_labels, 'GIS-Q0-51'), 'grid curves contain GIS-Q0-51 label');
T = T.chk(hasTok(S.grid_labels, 'GSUT-HV-51'), 'grid curves contain GSUT-HV-51 label');
% Each curve labelled device/function/CT/pickup/TMS/curve.
T = T.chk(allTok(S.gen_labels, 'CT'), 'gen labels carry CT token');
T = T.chk(allTok(S.gen_labels, 'TMS'), 'gen labels carry TMS token');
T = T.chk(allTok(S.gen_labels, 'SI'), 'gen labels carry curve family token');
T = T.chk(allTok(S.grid_labels, 'CT'), 'grid labels carry CT token');
T = T.chk(allTok(S.grid_labels, 'TMS'), 'grid labels carry TMS token');
T = T.chk(allTok(S.grid_labels, 'SI'), 'grid labels carry curve family token');
% No fabricated manufacturer strings anywhere in titles/labels.
allTxt = [S.gen_title ' ' S.grid_title ' ' ...
    strjoin(cellstr(S.gen_labels), ' ') ' ' strjoin(cellstr(S.grid_labels), ' ')];
T = T.chk(~hasMaker(allTxt), 'no manufacturer strings in titles/labels');
% Fault markers source-backed: branch currents, never net totals.
T = T.chk(abs(S.markers.F1_LLL_GENkA - 55.0487096805) < 1e-6, ...
    'F1 LLL GEN_Q marker 55.05 kA branch (not 126.21 kA total)');
T = T.chk(abs(S.markers.F1_LLL_GENkA - 126.21414119005) > 10, ...
    'F1 LLL marker is branch, honestly understates net total');
T = T.chk(abs(S.markers.F1_LG_GENkA - 8.4141166954) < 1e-6, ...
    'F1 LG GEN_Q marker 8.41 kA phase branch (not 7.27 A total)');
T = T.chk(abs(S.markers.F1_LG_earth_A - 7.27200442799167) < 1e-6, ...
    'F1 LG earth marker 7.27 A (3I0 single-count total)');
T = T.chk(abs(S.markers.F3_LLL_total_kA - 50.5308851865359) < 1e-6, ...
    'F3 LLL total marker 50.53 kA with branch annotation');
% Marker time reproduces the curve library (phase5_curve via phase5_time).
tExp = phase5_time(55.0487096805 * 1000 / 15000, 15023.75 / 15000, 0.1, 'SI');
T = T.chk(abs(S.markers.F1_LLL_GEN51_t - tExp) < 1e-9, ...
    'gen marker time matches phase5_time recomputation (library curves)');
% Errors phase5-prefixed.
try
    phase5_tcc(42);
    T = T.chk(false, 'bad outDir errors');
catch ME
    T = T.chk(strncmp(ME.identifier, 'phase5', 6), 'bad outDir errors phase5-prefixed');
end
[np, nf] = T.done();
end

function ok = hasTok(labels, tok)
%HASTOK  Label set contains the device token followed by the label delimiter.
ok = false;
key = [tok ' |'];
for k = 1:numel(labels)
    lab = labels{k};
    if isstring(lab) && isscalar(lab), lab = char(lab); end
    if ischar(lab) && ~isempty(strfind(lab, key)), ok = true; return; end
end
end

function ok = allTok(labels, tok)
%ALLTOK  Every label carries the required token (CT/TMS/curve family).
ok = true;
for k = 1:numel(labels)
    lab = labels{k};
    if isstring(lab) && isscalar(lab), lab = char(lab); end
    if ~ischar(lab) || isempty(strfind(lab, tok)), ok = false; return; end
end
end

function bad = hasMaker(txt)
%HASMAKER  True if fabricated relay-manufacturer strings appear (titles/labels).
low = lower(txt);
subs = {'siemens', 'schneider', 'alstom', 'micom', 'areva', 'hitachi', ...
    'toshiba', 'siprotec', 'reyrolle', 'general electric'};
bad = false;
for k = 1:numel(subs)
    if ~isempty(strfind(low, subs{k})), bad = true; return; end
end
words = regexp(low, '[a-z0-9]+', 'match');
if any(strcmp(words, 'abb')) || any(strcmp(words, 'sel')), bad = true; end
end
