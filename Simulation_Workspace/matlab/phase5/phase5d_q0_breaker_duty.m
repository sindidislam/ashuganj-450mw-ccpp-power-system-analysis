function R = phase5d_q0_breaker_duty(varargin)
%PHASE5D_Q0_BREAKER_DUTY  Q0 duty + PGCB envelope (63 kA) + 230 kV actual.
% South GIS is 230 kV (SLD); 400 kV is the regional envelope level.
% R = phase5d_q0_breaker_duty() or (outDir) or (outDir, root).
if nargin == 0
    root = ashuganj_root();
    outDir = fullfile(root, 'results', 'phase5_protection_v2');
elseif nargin == 1
    outDir = varargin{1}; root = ashuganj_root();
elseif nargin == 2
    outDir = varargin{1}; root = varargin{2};
else
    error('phase5d_q0:args', 'usage: R = phase5d_q0_breaker_duty() or (outDir) or (outDir, root).');
end
if isstring(outDir) && isscalar(outDir), outDir = char(outDir); end
if isstring(root) && isscalar(root), root = char(root); end
if ~ischar(outDir) || isempty(strtrim(outDir)), error('phase5d_q0:args', 'outDir must be non-empty.'); end
if ~ischar(root) || isempty(strtrim(root)), error('phase5d_q0:args', 'root must be non-empty.'); end
if exist(root, 'dir') ~= 7, error('phase5d_q0:root', 'root not found: %s', root); end
if exist(outDir, 'dir') ~= 7
    [okMk, msgMk] = mkdir(outDir);
    if ~okMk, error('phase5d_q0:mkdir', 'cannot create %s (%s).', outDir, msgMk); end
end
plotDir = fullfile(outDir, 'plots');
if exist(plotDir, 'dir') ~= 7, mkdir(plotDir); end

rated = 63.0; ip_rated = 2.55 * rated;      % 160.65 kA peak
plant = 3.03;                                % kA through GSU
% 5 grid scenarios (Ssc -> Igrid at 400 kV)
Ssc = [10000; 20000; 30000; 34641; 41548];
Igrid = [10000/(sqrt(3)*400); 20000/(sqrt(3)*400); 30000/(sqrt(3)*400); 50.00; 59.97];
Itotal = plant + Igrid;
duty = Itotal / rated * 100;
margin = rated - Itotal;
verdict = repmat("PASS", 5, 1);
verdict(duty > 100) = "FAIL";
scenario = ["Weak 10 GVA"; "Moderate 20 GVA"; "Strong 30 GVA"; "PGCB max 50 kA"; "Rating boundary 59.97 kA"];
D = table(scenario, Ssc, Igrid, repmat(plant,5,1), Itotal, duty, margin, verdict, ...
    'VariableNames', {'scenario','Ssc_MVA','Igrid_kA','Iplant_kA','Itotal_kA','duty_pct','margin_kA','verdict'});

% 230 kV actual-duty note (frozen branch max Q0 6.897 kA vs conditional 50 kA)
actual_branch = 6.89701475447833; actual_duty_50 = actual_branch / 50 * 100;

writetable(D, fullfile(outDir, 'q0_breaker_duty_matrix.csv'));

fig = figure('Visible', 'off', 'Color', 'white', 'Position', [50 50 1200 750]);
hold on;
plot(Igrid, duty, 'b-o', 'LineWidth', 1.8, 'MarkerSize', 8);
plot([0 65], [100 100], 'r--', 'LineWidth', 1.4);
plot([0 65], [84.2 84.2], 'g:', 'LineWidth', 1.2);
xlim([10 62]); ylim([20 105]);
xlabel('Grid infeed Igrid (kA @400 kV)');
ylabel('Duty = (Igrid+3.03)/63 (%)');
title('Q0 duty vs grid level: PGCB 50 kA -> 84.2% (15.8% margin)', 'Interpreter', 'none');
legend({'Duty %', 'Rating 100%', 'PGCB design 84.2%'}, 'Location', 'northwest', 'FontSize', 9, 'Interpreter', 'none');
grid on;
pngPath = fullfile(plotDir, 'q0_duty_sensitivity_curve.png');
print(fig, pngPath, '-dpng'); close(fig);
if exist(pngPath, 'file') ~= 2, error('phase5d_q0:write', 'PNG not written: %s', pngPath); end

R = struct('rated_kA', rated, 'ip_kA', ip_rated, 'plant_kA', plant, ...
    'grid_max_allow_kA', rated - plant, 'grid_max_allow_MVA', (rated-plant)*sqrt(3)*400, ...
    'pgcb_total_kA', 53.03, 'pgcb_duty_pct', 53.03/63*100, 'pgcb_margin_pct', (63-53.03)/63*100, ...
    'actual_230_branch_kA', actual_branch, 'actual_230_duty50_pct', actual_duty_50, ...
    'csv', fullfile(outDir, 'q0_breaker_duty_matrix.csv'), 'png', pngPath);
end
