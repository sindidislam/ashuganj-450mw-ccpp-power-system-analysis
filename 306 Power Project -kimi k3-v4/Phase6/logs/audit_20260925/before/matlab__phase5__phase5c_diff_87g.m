function S = phase5c_diff_87g(varargin)
%PHASE5C_DIFF_87G  Generator differential 87G (7UM62), dual-slope.
% Frozen base: 458 MVA, 22 kV, In = 12019.2 A, CT 15000/1 both sides.
% Uses Siemens convention: Idiff = |It-In|, Irest = |It|+|In| (scalar sum).
% S = phase5c_diff_87g() or (outDir) or (outDir, root).
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection_v2', 'plots');
elseif nargin == 1
    outDir = varargin{1}; root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1}; root = varargin{2};
else
    error('phase5c_diff_87g:args', 'usage: S = phase5c_diff_87g() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir)), error('phase5c_diff_87g:args', 'outDir must be non-empty.'); end
if ~ischar(root) || isempty(strtrim(root)), error('phase5c_diff_87g:args', 'root must be non-empty.'); end
if exist(root, 'dir') ~= 7, error('phase5c_diff_87g:root', 'root not found: %s', root); end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk, error('phase5c_diff_87g:mkdir', 'cannot create %s (%s).', outDir, msgMk); end
end

% --- base values (source: Generator Data_South.pdf p.6) ---
Sn = 458e6; Vn = 22000;
In = Sn / (sqrt(3) * Vn);            % 12019.2 A
CT = 15000;
Isec_n = In / CT;                    % 0.80128 A
pickup_pu = 0.20;
Idiff_pickup_A = pickup_pu * In;     % 2403.84 A
Idiff_pickup_sec = Idiff_pickup_A / CT;
k1 = 0.20; Irest1_pu = 1.00;
k2 = 0.50;
Idiff_hs_pu = 5.0; Idiff_hs_A = Idiff_hs_pu * In;  % 60096 A, <=20 ms

% --- characteristic curve (pu of In) ---
Ir = linspace(0, 12, 600);
Itrip = zeros(size(Ir));
for i = 1:numel(Ir)
    if Ir(i) <= Irest1_pu
        Itrip(i) = max(pickup_pu, k1 * Ir(i));
    else
        Itrip(i) = max(pickup_pu, k1 * Irest1_pu + k2 * (Ir(i) - Irest1_pu));
    end
end

% --- validation points ---
% A: normal load 12019 A through (It=In, In_neut=In, opposite refs -> Idiff~0, Irest=2pu)
A = struct('It', In, 'Ine', In, 'Idiff_pu', 0, 'Irest_pu', 2.0);
A.trip = trip87g(A.Idiff_pu, A.Irest_pu, pickup_pu, k1, k2, Irest1_pu, Idiff_hs_pu);
% B: external F1 3PH 126.21 kA through (symmetric, 5% CT mismatch worst case)
Ithru = 126214.14;
B = struct('It', Ithru, 'Ine', Ithru * 0.95, 'Idiff_pu', (Ithru*0.05)/In, 'Irest_pu', (Ithru*1.95)/In);
B.trip = trip87g(B.Idiff_pu, B.Irest_pu, pickup_pu, k1, k2, Irest1_pu, Idiff_hs_pu);
% C: internal stator 5000 A vs 0
C = struct('It', 5000, 'Ine', 0, 'Idiff_pu', 5000/In, 'Irest_pu', 5000/In);
C.trip = trip87g(C.Idiff_pu, C.Irest_pu, pickup_pu, k1, k2, Irest1_pu, Idiff_hs_pu);

% --- plot ---
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1200 750]);
hold on;
plot(Ir, Itrip, 'k-', 'LineWidth', 1.8);
plot([0 12], [Idiff_hs_pu Idiff_hs_pu], 'r--', 'LineWidth', 1.2);
plot(A.Irest_pu, A.Idiff_pu, 'go', 'MarkerSize', 9, 'LineWidth', 1.6);
plot(B.Irest_pu, B.Idiff_pu, 'bs', 'MarkerSize', 9, 'LineWidth', 1.6);
plot(C.Irest_pu, C.Idiff_pu, 'r^', 'MarkerSize', 9, 'LineWidth', 1.6);
xlim([0 12]); ylim([0 6]);
xlabel('Restraint current Irest (pu of In, 12019 A)');
ylabel('Differential current Idiff (pu of In)');
title('87G dual-slope: pickup 0.20pu, k1 20% to 1.0pu, k2 50%, HS 5.0pu', 'Interpreter', 'none');
legend({'Trip boundary', 'High-set 5.0pu (60.1 kA, \leq20 ms)', 'A normal (NO TRIP)', 'B F1 ext 126kA (STABLE)', 'C internal 5kA (TRIP)'}, 'Location', 'northwest', 'FontSize', 8, 'Interpreter', 'none');
grid on;
pngPath = fullfile(outDir, 'diff_87g_characteristic.png');
print(fig, pngPath, '-dpng'); close(fig);
if exist(pngPath, 'file') ~= 2, error('phase5c_diff_87g:write', 'PNG not written: %s', pngPath); end

S = struct('In_A', In, 'CT', CT, 'Isec_n_A', Isec_n, ...
    'pickup_pu', pickup_pu, 'pickup_A', Idiff_pickup_A, 'pickup_sec_A', Idiff_pickup_sec, ...
    'k1', k1, 'Irest1_pu', Irest1_pu, 'k2', k2, 'highset_pu', Idiff_hs_pu, 'highset_A', Idiff_hs_A, ...
    'A', A, 'B', B, 'C', C, 'png', pngPath);
end

function t = trip87g(Idiff_pu, Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu)
if Idiff_pu >= hs_pu, t = true; return; end
if Irest_pu <= Irest1_pu
    thr = max(pickup_pu, k1 * Irest_pu);
else
    thr = max(pickup_pu, k1 * Irest1_pu + k2 * (Irest_pu - Irest1_pu));
end
t = Idiff_pu > thr;
end
