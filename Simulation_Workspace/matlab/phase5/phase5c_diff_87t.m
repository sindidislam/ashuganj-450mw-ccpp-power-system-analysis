function S = phase5c_diff_87t(varargin)
%PHASE5C_DIFF_87T  GSUT differential 87T (7UT6331), dual-slope + harmonics.
% Frozen primary: 515 MVA, 22/230 kV, YNd1, uk 16% (GSUT datasheet p.1-2).
% Hypothetical plot basis: 450 MVA, 22/400 kV (not the South transformer).
% CT: LV 15000/1, HV 1600/1 (study; 1500/1 protection core as sensitivity).
% Static scalar examples; no measured vector compensation/zero-sequence filter.
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection_v2', 'plots');
elseif nargin == 1
    outDir = varargin{1}; root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1}; root = varargin{2};
else
    error('phase5c_diff_87t:args', 'usage: S = phase5c_diff_87t() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir)), error('phase5c_diff_87t:args', 'outDir must be non-empty.'); end
if ~ischar(root) || isempty(strtrim(root)), error('phase5c_diff_87t:args', 'root must be non-empty.'); end
if exist(root, 'dir') ~= 7, error('phase5c_diff_87t:root', 'root not found: %s', root); end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk, error('phase5c_diff_87t:mkdir', 'cannot create %s (%s).', outDir, msgMk); end
end

% --- ratings ---
In_LV_450 = 450e6 / (sqrt(3) * 22000);     % 11809.437 A (hypothetical basis)
In_HV_400 = 450e6 / (sqrt(3) * 400000);    % 649.5 A (spec basis)
In_LV_515 = 515e6 / (sqrt(3) * 22000);     % 13515.2 A (datasheet IN)
In_HV_230 = 515e6 / (sqrt(3) * 230000);    % 1292.8 A (datasheet IN)
CT_LV = 15000; CT_HV = 1600;
Isec_LV_450 = In_LV_450 / CT_LV;           % 0.7873 A
Isec_HV_400 = In_HV_400 / CT_HV;           % 0.4060 A
Isec_LV_515 = In_LV_515 / CT_LV;           % 0.9010 A
Isec_HV_230 = In_HV_230 / CT_HV;           % 0.8080 A
M_LV_450 = 1 / Isec_LV_450;                % Hypothetical 450 MVA / 22 kV.
M_HV_400 = 1 / Isec_HV_400;                % Hypothetical 450 MVA / 400 kV.
M_LV_515 = 1 / Isec_LV_515;                % Actual 515 MVA / 22 kV: 1.109858.
M_HV_230 = 1 / Isec_HV_230;                % Actual 515 MVA / 230 kV: 1.237660.
M_LV = M_LV_450; M_HV = M_HV_400;          % Legacy aliases retain hypothetical basis.

% --- characteristic (LV 450MVA pu basis) ---
pickup_pu = 0.30;
pickup_A_LV450 = pickup_pu * In_LV_450;    % 3542.7 A
pickup_A_LV515 = pickup_pu * In_LV_515;    % 4054.6 A
k1 = 0.25; Irest1_pu = 1.50; k2 = 0.50; hs_pu = 8.0;
h2_block = 0.15; h5_block = 0.30;

Ir = linspace(0, 12, 600);
Itrip = zeros(size(Ir));
for i = 1:numel(Ir)
    if Ir(i) <= Irest1_pu
        Itrip(i) = max(pickup_pu, k1 * Ir(i));
    else
        Itrip(i) = max(pickup_pu, k1 * Irest1_pu + k2 * (Ir(i) - Irest1_pu));
    end
end

% --- validation points (450MVA pu) ---
A = struct('Idiff_pu', 0.02, 'Irest_pu', 2.0);            % normal mismatch
A.trip = trip87t(A.Idiff_pu, A.Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, 0.05, 0.05, h2_block, h5_block);
B = struct('Idiff_pu', 0.35, 'Irest_pu', 10.6);           % assumed scalar through-current example
B.trip = trip87t(B.Idiff_pu, B.Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, 0.05, 0.05, h2_block, h5_block);
C = struct('Idiff_pu', 0.60, 'Irest_pu', 0.60);           % internal LV fault
C.trip = trip87t(C.Idiff_pu, C.Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, 0.05, 0.05, h2_block, h5_block);
D = struct('Idiff_pu', 0.60, 'Irest_pu', 0.60);           % same + inrush 25% 2nd harmonic
D.trip = trip87t(D.Idiff_pu, D.Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, 0.25, 0.05, h2_block, h5_block);
E = struct('Idiff_pu', 0.60, 'Irest_pu', 0.60);           % same + overexcitation 35% 5th
E.trip = trip87t(E.Idiff_pu, E.Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, 0.05, 0.35, h2_block, h5_block);

fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1200 750]);
hold on;
plot(Ir, Itrip, 'k-', 'LineWidth', 1.8);
plot([0 12], [hs_pu hs_pu], 'r--', 'LineWidth', 1.2);
plot(A.Irest_pu, A.Idiff_pu, 'go', 'MarkerSize', 9, 'LineWidth', 1.6);
plot(B.Irest_pu, B.Idiff_pu, 'bs', 'MarkerSize', 9, 'LineWidth', 1.6);
plot(C.Irest_pu, C.Idiff_pu, 'r^', 'MarkerSize', 9, 'LineWidth', 1.6);
xlim([0 12]); ylim([0 9]);
xlabel('Restraint current Irest (pu, LV 450MVA basis 11809 A)');
ylabel('Differential current Idiff (pu)');
title('87T dual-slope: pickup 0.30pu, k1 25% to 1.5pu, k2 50%, HS 8pu', 'Interpreter', 'none');
legend({'Trip boundary', 'High-set 8pu', 'A normal (NO TRIP)', 'B assumed through-current (STABLE)', 'C internal (TRIP, D/E blocked by harmonics)'}, 'Location', 'northwest', 'FontSize', 8, 'Interpreter', 'none');
grid on;
pngPath = fullfile(outDir, 'diff_87t_characteristic.png');
print(fig, pngPath, '-dpng'); close(fig);
if exist(pngPath, 'file') ~= 2, error('phase5c_diff_87t:write', 'PNG not written: %s', pngPath); end

S = struct('In_LV_450_A', In_LV_450, 'In_HV_400_A', In_HV_400, ...
    'In_LV_515_A', In_LV_515, 'In_HV_230_A', In_HV_230, ...
    'CT_LV', CT_LV, 'CT_HV', CT_HV, ...
    'Isec_LV_450_A', Isec_LV_450, 'Isec_HV_400_A', Isec_HV_400, ...
    'Isec_LV_515_A', Isec_LV_515, 'Isec_HV_230_A', Isec_HV_230, ...
    'M_LV', M_LV, 'M_HV', M_HV, ...
    'M_LV_450', M_LV_450, 'M_HV_400', M_HV_400, ...
    'M_LV_515', M_LV_515, 'M_HV_230', M_HV_230, ...
    'characteristic_basis', 'hypothetical 450 MVA / 22/400 kV', ...
    'pickup_pu', pickup_pu, 'pickup_A_LV450', pickup_A_LV450, 'pickup_A_LV515', pickup_A_LV515, ...
    'k1', k1, 'Irest1_pu', Irest1_pu, 'k2', k2, 'highset_pu', hs_pu, ...
    'h2_block', h2_block, 'h5_block', h5_block, ...
    'A', A, 'B', B, 'C', C, 'D', D, 'E', E, 'png', pngPath);
end

function t = trip87t(Idiff_pu, Irest_pu, pickup_pu, k1, k2, Irest1_pu, hs_pu, h2, h5, h2b, h5b)
if h2 >= h2b || h5 >= h5b, t = false; return; end   % harmonic block
if Idiff_pu >= hs_pu, t = true; return; end
if Irest_pu <= Irest1_pu
    thr = max(pickup_pu, k1 * Irest_pu);
else
    thr = max(pickup_pu, k1 * Irest1_pu + k2 * (Irest_pu - Irest1_pu));
end
t = Idiff_pu > thr;
end
