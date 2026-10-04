function hFig = plot_generator_capability(S, curve, savePath)
%PLOT_GENERATOR_CAPABILITY Visualizes generator capability curve and operating points.
%   hFig = PLOT_GENERATOR_CAPABILITY(S, curve, savePath)
%   Plots:
%   1. Authoritative 6-point Qmax and Qmin capability envelope
%   2. Permissible primary operating envelope (P <= 360 MW)
%   3. Apparent power limit Snom = 458 MVA
%   4. Primary 360 MW solved operating points
%   5. Qualified 342.01 MW scenario points
%   6. Historical 389.30 MW reference points (explicitly marked as historical)

if nargin < 2 || isempty(curve)
    G = ashuganj_generators();
    curve = G.capabilityCurve;
end

if nargin < 3 || isempty(savePath)
    root = ashuganj_root();
    savePath = fullfile(root, 'docs', 'validation', 'rev31_phase2', 'generator_capability_curve.png');
end

% Dense interpolation for smooth plotting
P_dense = linspace(0, 458, 500);
[Qmin_dense, Qmax_dense] = generatorCapability(P_dense, curve);

% Snom = 458 MVA circle
Q_snom = sqrt(max(0, 458^2 - P_dense.^2));

hFig = figure('Name', 'Generator P-Q Capability Curve', 'Color', 'w', ...
    'Position', [100, 100, 950, 750], 'Visible', 'off');
ax = axes('Parent', hFig);
hold(ax, 'on');
grid(ax, 'on');
set(ax, 'GridLineStyle', ':', 'GridAlpha', 0.4);

% Shaded permissible primary operating region (P <= 360 MW)
idx360 = P_dense <= 360;
fill([P_dense(idx360), fliplr(P_dense(idx360))], ...
     [Qmax_dense(idx360), fliplr(Qmin_dense(idx360))], ...
     [0.85 0.95 0.85], 'EdgeColor', 'none', 'DisplayName', 'Permissible Primary Zone (P \leq 360 MW)', 'Parent', ax);

% Shaded extended OEM capability envelope (360 MW < P <= 458 MW)
fill([P_dense(~idx360), fliplr(P_dense(~idx360))], ...
     [Qmax_dense(~idx360), fliplr(Qmin_dense(~idx360))], ...
     [0.95 0.90 0.85], 'EdgeColor', 'none', 'DisplayName', 'Extended Reference Envelope (P > 360 MW)', 'Parent', ax);

% Capability curve boundaries
plot(ax, P_dense, Qmax_dense, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Q_{max} Capability Boundary');
plot(ax, P_dense, Qmin_dense, 'b--', 'LineWidth', 2.0, 'DisplayName', 'Q_{min} Capability Boundary');

% 6 Authoritative Source Points
plot(ax, curve.P_MW, curve.Qmax_MVAr, 'bs', 'MarkerSize', 7, 'MarkerFaceColor', 'b', ...
    'DisplayName', 'Source Curve Data Points (Protection Report)');
plot(ax, curve.P_MW, curve.Qmin_MVAr, 'bs', 'MarkerSize', 7, 'MarkerFaceColor', 'b', 'HandleVisibility', 'off');

% Snom circle
plot(ax, P_dense, Q_snom, 'k:', 'LineWidth', 1.2, 'DisplayName', 'S_{nom} = 458 MVA Rating Circle');
plot(ax, P_dense, -Q_snom, 'k:', 'LineWidth', 1.2, 'HandleVisibility', 'off');

% 360 MW Primary Capacity Guard line
xline(ax, 360, 'r-', 'LineWidth', 1.8, 'DisplayName', 'Primary Capacity Limit (360 MW)');

% Overlay Operating Points if provided
if nargin >= 1 && ~isempty(S)
    for i = 1:numel(S)
        s = S(i);
        if contains(s.ID, 'LF360')
            plot(ax, s.Gen_P_MW, s.Gen_Q_MVAr, 'go', 'MarkerSize', 9, 'MarkerFaceColor', [0 0.7 0], ...
                'DisplayName', sprintf('Primary 360 MW: %s (%.1f MW, %+.1f MVAr)', s.ID, s.Gen_P_MW, s.Gen_Q_MVAr));
        elseif contains(s.ID, 'LF342') || strcmp(s.ID, 'LF3') || strcmp(s.ID, 'LF4')
            plot(ax, s.Gen_P_MW, s.Gen_Q_MVAr, 'd', 'MarkerSize', 8, 'MarkerFaceColor', [1 0.5 0], ...
                'DisplayName', sprintf('Qualified 342 MW: %s (%.1f MW, %+.1f MVAr)', s.ID, s.Gen_P_MW, s.Gen_Q_MVAr));
        elseif contains(s.ID, 'LF389') || strcmp(s.ID, 'LF1') || strcmp(s.ID, 'LF2')
            plot(ax, s.Gen_P_MW, s.Gen_Q_MVAr, 'rx', 'MarkerSize', 10, 'LineWidth', 2.0, ...
                'DisplayName', sprintf('Historical OEM Ref: %s (%.1f MW, %+.1f MVAr)', s.ID, s.Gen_P_MW, s.Gen_Q_MVAr));
        end
    end
end

xlabel(ax, 'Generator Active Power P [MW]', 'FontSize', 11, 'FontWeight', 'bold');
ylabel(ax, 'Generator Reactive Power Q [MVAr]', 'FontSize', 11, 'FontWeight', 'bold');
title(ax, {'Ashuganj South 450 MW CCPP — Generator P-Q Capability Curve', ...
    'Primary 360 MW Capacity vs Operating Cases (Prompt §37)'}, 'FontSize', 12, 'FontWeight', 'bold');

xlim(ax, [0, 480]);
ylim(ax, [-260, 360]);
legend(ax, 'Location', 'northeastoutside', 'FontSize', 9);

% Save to file
outFolder = fileparts(savePath);
if ~exist(outFolder, 'dir')
    mkdir(outFolder);
end
try
    saveas(hFig, savePath);
    fprintf('  Capability plot saved to: %s\n', savePath);
catch ME
    warning('plot_generator_capability:saveFailed', 'Could not save plot: %s', ME.message);
end
end
