function make_load_flow_plots(varargin)
%MAKE_LOAD_FLOW_PLOTS  Phase 14: the four deliverable figures, from the CSVs.
%
%   MAKE_LOAD_FLOW_PLOTS               read results/load_flow/*.csv, write PNGs
%   MAKE_LOAD_FLOW_PLOTS('Show', true) leave the figures open on screen
%
%   WHY THIS READS THE CSVs AND DOES NOT RE-SOLVE
%   --------------------------------------------
%   The figures must show the SAME numbers as the tables. If this function solved
%   the network again it could disagree with results/load_flow/*.csv - through a
%   dataset edit, a different case list, or the solve-writes-back-into-blocks
%   behaviour measured in solver_behaviour.md B3 - and a plot that silently
%   disagrees with its own table is worse than no plot. So the tables are the
%   single source and the plots are a rendering of them. Re-run
%   run_load_flow_study first if the tables are stale.
%
%   EVERY FIGURE HAS TO SHOW WHAT ITS CAPTION CLAIMS
%   -----------------------------------------------
%   The first version of this file produced four PNGs that were all technically
%   correct and two of which were useless, because a 375 MVA GSUT bar on a linear
%   axis compresses a 109.5 % UAT overload into an invisible sliver while the
%   title announces that overload. Scale choices below are therefore not
%   cosmetic:
%     * transformer loading is drawn TWICE - absolute MVA on a log axis so all
%       three machines are legible at once, and per-cent of the lowest documented
%       cooling stage on a linear axis, which is where the overload is visible.
%     * the bus profile plots only the four true busbars, in ELECTRICAL PATH
%       order. The GAT HV terminal is split into its own panel: with bay 10BAY20
%       open it sits at 0.9579 pu, which is the transformer turns ratio and not a
%       system voltage, and drawing it in-line made an open breaker look like a
%       4 % voltage gradient - the largest feature on the whole figure.
%     * the branch figure plots CURRENT against the documented 3150 A
%       bus-coupler/busbar module rating (bays are 2000 A modules; conductor
%       ampacity MISSING), because that is the one 230 kV continuous-current
%       limit the source set states at GIS level. An MVA bar chart of this
%       network shows one visible bar and nothing else.
%
%   No plot invents a limit line that no document states. The GSUT/UAT/GAT rating
%   stages and the 3150 A bus-coupler/busbar module rating ARE documented and are
%   drawn; bay currents (≈870 A) are stated against the 2000 A bay-module class
%   in the report tables, never against 3150 A; there
%   is no 230 kV voltage-tolerance band, because approved answer Q8a reports the
%   solved voltage without a pass/fail limit and no tolerance was found.

p = inputParser;
p.addParameter('Show', false, @islogical);
p.parse(varargin{:});
opt = p.Results;

root = ashuganj_root();
lfd  = fullfile(root, 'results', 'load_flow');
outd = fullfile(root, 'results', 'plots');
if ~isfolder(outd), mkdir(outd); end

req = {'bus_results', 'transformer_results', 'line_results', 'system_summary'};
for i = 1:numel(req)
    f = fullfile(lfd, [req{i} '.csv']);
    if ~isfile(f)
        error('make_load_flow_plots:missingTable', ...
            ['%s is missing. The plots render the tables and never re-solve, ' ...
             'so run run_load_flow_study first.'], f);
    end
end
B  = readtable(fullfile(lfd, 'bus_results.csv'),         'TextType', 'string');
Tx = readtable(fullfile(lfd, 'transformer_results.csv'), 'TextType', 'string');
Ln = readtable(fullfile(lfd, 'line_results.csv'),        'TextType', 'string');
Sy = readtable(fullfile(lfd, 'system_summary.csv'),      'TextType', 'string');

cases = unique(Sy.Case, 'stable');
nc    = numel(cases);
% Tick labels are rendered with the TeX interpreter, so that the log-scale panels
% show 10^3 rather than the literal characters 10^{3}. TeX also turns an
% underscore into a subscript, and these names come from a CSV: "GAT_HV" rendered
% as GAT_H with a stranded V in an earlier version of this figure. So names are
% escaped once, here, rather than switching the interpreter off wholesale and
% breaking the exponents.
casesD = texsafe(cases);
% One colour per case, and the SAME colour in every figure, so a reader can
% follow one case across all four plots without a per-figure legend lookup.
col   = lines(nc);
vis   = 'off';  if opt.Show, vis = 'on'; end
fprintf('Phase 14 plots from %s\n', lfd);

% =====================================================================
% 1. BUS VOLTAGE PROFILE
% =====================================================================
% Plotted in ELECTRICAL PATH order - grid, 230 kV busbar, 22 kV generator bus,
% 6.6 kV auxiliary bus. The register order would zigzag 230 -> 22 -> 6.6 -> 230
% and draw a profile along a path that does not exist. Merged members carry NaN
% injection and a Merged_into tag; they are the same node as their
% representative and are dropped rather than drawn three times.
pathOrder = ["BGRID230", "B230_1", "B22", "B6_6"];
present   = B.Case == cases(1) & (ismissing(B.Merged_into) | B.Merged_into == "");
bn = strings(0); lbl = strings(0);
for k = 1:numel(pathOrder)
    m = present & B.Bus == pathOrder(k);
    if any(m)
        bn(end+1)  = pathOrder(k);            %#ok<AGROW>
        lbl(end+1) = B.Label(find(m, 1));     %#ok<AGROW>
    else
        warning('make_load_flow_plots:busAbsent', ...
            '%s is not an unmerged bus in the results - omitted from the profile.', ...
            pathOrder(k));
    end
end
nb = numel(bn);

f1 = figure('Visible', vis, 'Position', [60 60 1180 780]);
tl = tiledlayout(f1, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile(tl, [2 1]); hold(ax, 'on'); grid(ax, 'on');
for c = 1:nc
    v = nan(nb, 1);
    for j = 1:nb
        m = B.Case == cases(c) & B.Bus == bn(j);
        if any(m), v(j) = B.V_pu(find(m, 1)); end
    end
    plot(ax, 1:nb, v, '-o', 'LineWidth', 1.6, 'MarkerSize', 8, ...
        'Color', col(c,:), 'MarkerFaceColor', col(c,:), 'DisplayName', char(casesD(c)));
end
yline(ax, 1.0, 'k:', 'LineWidth', 1.0, 'HandleVisibility', 'off');
text(ax, 0.58, 1.0, ' 1.00 pu', 'VerticalAlignment', 'bottom', 'FontSize', 8, ...
    'Color', [0.35 0.35 0.35]);
set(ax, 'XTick', 1:nb, 'XTickLabel', texsafe(lbl), 'XLim', [0.5 nb+0.5], 'FontSize', 10, ...
    'TickLabelInterpreter', 'tex');
ylabel(ax, '|V|  (pu on each bus''s own nominal)');
title(ax, {'Bus voltage profile - Ashuganj South, balanced load flow, 50 Hz', ...
    ['Electrical path order. Merged nodes omitted: the three 6.6 kV register ' ...
     'buses are ONE solved node (feeder impedances MISSING), as are the two ' ...
     '230 kV busbars (coupler closed)']}, 'FontSize', 10);
legend(ax, 'Location', 'southwest', 'FontSize', 9, 'Interpreter', 'none');
% The 22 kV bus reads exactly 1.0 because it was SET there. Saying so on the
% figure stops it being read as a solved result - it is assumption A5.
kv22 = find(bn == "B22", 1);
if ~isempty(kv22)
    text(ax, kv22, 1.0, {'', 'set, not solved', '(assumption A5)'}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
        'FontSize', 8, 'Color', [0.55 0 0], 'FontWeight', 'bold');
end
% The 6.6 kV bus is the one bus with two defensible bases. Both are in the CSV;
% the second is put on the figure so the reader is not left with one of them.
kv66 = find(bn == "B6_6", 1);
if ~isempty(kv66)
    m1 = B.Case == cases(1) & B.Bus == "B6_6";
    text(ax, kv66, B.V_pu(find(m1,1)), ...
        {sprintf('conflict C13: %.5f pu on 6600 V', B.V_pu(find(m1,1))), ...
         sprintf('%.5f pu on the 6900 V winding', B.V_pu_alt_base(find(m1,1))), ''}, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 8, 'Color', [0 0 0.6]);
end

% --- The GAT HV terminal, deliberately in its own panel ---------------
axG = nexttile(tl); hold(axG, 'on'); grid(axG, 'on');
vg = nan(nc, 1); st = strings(nc, 1);
for c = 1:nc
    m = B.Case == cases(c) & B.Bus == "GAT_HV";
    if any(m), vg(c) = B.V_pu(find(m, 1)); end
    st(c) = Sy.GAT(Sy.Case == cases(c));
end
hbg = bar(axG, vg, 0.55, 'FaceColor', 'flat');
hbg.CData = col;
for c = 1:nc
    text(axG, c, vg(c), sprintf('  %.6f pu\n  bay 10BAY20 %s', vg(c), st(c)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8);
end
ylim(axG, [0.94 max(vg)*1.008]);
set(axG, 'XTick', 1:nc, 'XTickLabel', casesD, 'FontSize', 9, ...
    'TickLabelInterpreter', 'tex');
ylabel(axG, '|V| (pu)');
title(axG, ['GAT HV terminal - NOT a busbar, and NOT on the profile above: with ' ...
    'bay 10BAY20 open it floats at the 230/6.9 kV turns ratio (0.9579 pu), not at a ' ...
    'system voltage'], 'FontSize', 9.5);
save_png(f1, fullfile(outd, 'bus_voltage_profile.png'), opt.Show);

% =====================================================================
% 2. TRANSFORMER LOADING
% =====================================================================
% Against the documented cooling stages. run_load_flow_study computes the CSV
% percentage as 100*max(S_from, S_to)/stage - the MORE HEAVILY LOADED TERMINAL,
% which is the right definition and is not always the HV one: for the UAT the HV
% side carries the LV load plus the copper loss, for the GSUT the LV side is the
% larger. So the absolute panel plots max(S_LV, S_HV) too. Plotting S_HV against
% a percentage derived from the max would put two different quantities in two
% panels of one figure - checked against the source, not assumed: an earlier
% version of this file did exactly that and disagreed with itself by 0.65 MVA on
% the GSUT.
txn = unique(Tx.Transformer, 'stable');
nt  = numel(txn);
S   = nan(nt, nc);   % MVA at the more heavily loaded terminal
L   = nan(nt, nc);   % per cent of lowest documented stage, same terminal
for c = 1:nc
    for j = 1:nt
        m = find(Tx.Case == cases(c) & Tx.Transformer == txn(j), 1);
        if ~isempty(m)
            S(j,c) = max(Tx.S_LV_MVA(m), Tx.S_HV_MVA(m));
            L(j,c) = Tx.Loading_pct_lowest_stage(m);
        end
    end
end

f2 = figure('Visible', vis, 'Position', [60 60 1180 800]);
tl = tiledlayout(f2, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- absolute MVA, LOG axis so 0.003, 7.7 and 375 MVA are all legible --
ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
hb = bar(ax, S, 'grouped');
for c = 1:nc, hb(c).FaceColor = col(c,:); hb(c).DisplayName = char(casesD(c)); end
% Documented rating stages, drawn per transformer as short horizontal marks.
% The CSV writes them as a MATLAB vector literal, "[355 460 515]" - whitespace
% separated inside brackets. Parsed by measurement of the actual file, not by
% guessing a delimiter: an earlier version split on '/' and silently found none.
lgOnce = true;
for j = 1:nt
    m  = find(Tx.Transformer == txn(j), 1);
    sg = sscanf(regexprep(char(Tx.Rating_stages_MVA(m)), '[\[\]]', ''), '%g');
    sg = sort(sg(~isnan(sg)));
    if isempty(sg)
        warning('make_load_flow_plots:noStages', ...
            'No rating stages parsed for %s - the ratings line is not drawn.', txn(j));
    end
    for s = 1:numel(sg)
        sty = '--'; lw = 1.0;
        if s == 1, sty = '-'; lw = 2.0; end   % lowest (ONAN) stage - the one crossed
        h = plot(ax, [j-0.44 j+0.44], [sg(s) sg(s)], sty, 'Color', [0.75 0 0], ...
            'LineWidth', lw);
        if lgOnce && s == 1
            h.DisplayName = 'lowest (ONAN) rating stage'; lgOnce = false;
        else
            h.Annotation.LegendInformation.IconDisplayStyle = 'off';
        end
    end
    % One stacked caption per transformer instead of one label per stage line.
    % On a log axis 460 and 515 MVA are ~5 % apart and their labels overlapped
    % into an unreadable smear; 19 and 25 MVA did the same.
    if ~isempty(sg)
        text(ax, j+0.48, sg(1), sprintf('%s MVA\n', strjoin(compose('%g', sg(:)'), ' / ')), ...
            'FontSize', 8, 'Color', [0.55 0 0], 'VerticalAlignment', 'bottom', ...
            'HorizontalAlignment', 'center');
    end
end
set(ax, 'XTick', 1:nt, 'XTickLabel', texsafe(txn), 'FontSize', 9.5, 'YScale', 'log', ...
    'TickLabelInterpreter', 'tex');
ylim(ax, [1e-3 2e3]);
ylabel(ax, 'S at the more loaded terminal  (MVA, log scale)');
title(ax, ['Transformer loading, absolute - LOG axis, because a linear one puts ' ...
    'the GSUT at 375 MVA and the open-bay GAT at 0.003 MVA on the same picture'], ...
    'FontSize', 10);
legend(ax, 'Location', 'southwest', 'FontSize', 8.5, 'Interpreter', 'none', ...
    'NumColumns', 2);

% --- per cent of the lowest documented stage: where the overload shows --
axP = nexttile(tl); hold(axP, 'on'); grid(axP, 'on');
hb = bar(axP, L, 'grouped');
for c = 1:nc, hb(c).FaceColor = col(c,:); hb(c).DisplayName = char(casesD(c)); end
yline(axP, 100, 'r-', 'LineWidth', 2.0, 'DisplayName', 'lowest documented stage = 100 %');
for j = 1:nt
    for c = 1:nc
        if L(j,c) > 100
            text(axP, j + hb(c).XOffset, L(j,c), sprintf('%.2f %%\n', L(j,c)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.6 0 0]);
        end
    end
end
set(axP, 'XTick', 1:nt, 'XTickLabel', texsafe(txn), 'FontSize', 9.5, ...
    'TickLabelInterpreter', 'tex');
ylim(axP, [0 max(L(:))*1.28]);
ylabel(axP, '% of LOWEST documented stage');
title(axP, {['Loading against the LOWEST documented cooling stage ' ...
    '(GSUT 355 MVA ONAN, UAT/GAT 19 MVA ONAN)'], ...
    ['FOUR CROSSINGS: GSUT 105.87 % / 104.20 % at rated dispatch - needs forced ' ...
     'cooling, normal for a GSU'], ...
    ['UAT 109.50 % / 101.39 % in the LOOPED cases - that one is CIRCULATING ' ...
     'power through the closed GAT loop, not load']}, 'FontSize', 9.5);
legend(axP, 'Location', 'northeast', 'FontSize', 8.5, 'Interpreter', 'none', ...
    'NumColumns', 2);
save_png(f2, fullfile(outd, 'transformer_loading.png'), opt.Show);

% =====================================================================
% 3. BRANCH LOADING  (filename kept: line_loading.png)
% =====================================================================
% There are NO transmission lines in South scope - approved answer Q7a puts the
% grid equivalent at the plant boundary and forbids inventing the outgoing line.
% So the modelled branches are the grid equivalent and two 230 kV switching
% devices, and the honest loading question is CURRENT against the one documented
% 230 kV GIS-level continuous-current limit in the source set: the 3150 A
% bus-coupler/busbar module rating (bays are 2000 A modules; conductor ampacity
% MISSING — see §2 reconciliation).
IBUS_A = 3150;   % GIS bus-coupler/busbar module continuous rating - documented; NOT a bay or conductor rating

f3 = figure('Visible', vis, 'Position', [60 60 1180 800]);
tl = tiledlayout(f3, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

axI = nexttile(tl); hold(axI, 'on'); grid(axI, 'on');
% Bay currents come from the transformer table because the breakers themselves
% are zero-impedance merged elements - the current THROUGH a bay is the current
% at the transformer HV terminal it serves, which is a measured column.
pathNames = ["ZGRID (grid equivalent)", "GSUT bay 10BAY11", "GAT bay 10BAY20"];
I = nan(3, nc);
for c = 1:nc
    m = Ln.Case == cases(c) & Ln.Branch == "ZGRID (grid equivalent)";
    if any(m), I(1,c) = Ln.I_A(find(m, 1)); end
    m = Tx.Case == cases(c) & Tx.Transformer == "GSUT 10BAT10";
    if any(m), I(2,c) = Tx.I_HV_A(find(m, 1)); end
    m = Tx.Case == cases(c) & Tx.Transformer == "GAT 10BBT20";
    if any(m), I(3,c) = Tx.I_HV_A(find(m, 1)); end
end
hb = bar(axI, I, 'grouped');
for c = 1:nc, hb(c).FaceColor = col(c,:); hb(c).DisplayName = char(casesD(c)); end
yline(axI, IBUS_A, 'r-', 'LineWidth', 2.0, ...
    'DisplayName', sprintf('bus-coupler/busbar module rating %d A (documented; bays 2000 A)', IBUS_A));
for j = 1:3
    text(axI, j, max(I(j,:)), sprintf('  max %.1f A = %.1f %% of %d A\n', ...
        max(I(j,:)), 100*max(I(j,:))/IBUS_A, IBUS_A), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8.5);
end
set(axI, 'XTick', 1:3, 'XTickLabel', texsafe(pathNames), 'FontSize', 9.5, ...
    'TickLabelInterpreter', 'tex');
ylim(axI, [0 IBUS_A*1.12]);
ylabel(axI, 'current (A rms)');
title(axI, {['230 kV branch and bay currents against the documented 3150 A ' ...
    'bus-coupler/busbar module rating (bays 2000 A)'], ...
    ['BUS COUPLER 10BAY12 is absent: it is a zero-impedance CLOSED breaker, so ' ...
     'the solver merges BUS 1 and BUS 2'], ...
    ['Its flow is NOT OBSERVABLE from bus voltages - unobservable, not zero']}, ...
    'FontSize', 9.5);
legend(axI, 'Location', 'northwest', 'FontSize', 8.5, 'Interpreter', 'none', ...
    'NumColumns', 2);

axS = nexttile(tl); hold(axS, 'on'); grid(axS, 'on');
Z = nan(nc, 3);
for c = 1:nc
    m = find(Ln.Case == cases(c) & Ln.Branch == "ZGRID (grid equivalent)", 1);
    Z(c,:) = [-Ln.P_from_MW(m), -Ln.Q_from_MVAr(m), Ln.S_from_MVA(m)];
end
hb = bar(axS, Z, 'grouped');
nm = {'P exported (MW)', 'Q exported (MVAr)', 'S (MVA)'};
for k = 1:3, hb(k).DisplayName = nm{k}; end
% Headroom BEFORE the labels are placed. Without it MATLAB fits ylim to the bars,
% the 375.9502 MVA labels land in the top few pixels of the axes, and the second
% title line prints straight through them - which is what the previous render did.
ylo = min(0, min(Z(:))) * 1.45;
yhi = max(Z(:)) * 1.30;
ylim(axS, [ylo yhi]);
for c = 1:nc
    % Over the THIRD bar of the group, not the group centre: XOffset is the only
    % way to know where a grouped bar actually sits.
    text(axS, c + hb(3).XOffset, Z(c,3), sprintf('%.4f MVA', Z(c,3)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', 8.5, 'Margin', 1);
end
yline(axS, 0, 'k-', 'HandleVisibility', 'off');
set(axS, 'XTick', 1:nc, 'XTickLabel', casesD, 'FontSize', 9.5, ...
    'TickLabelInterpreter', 'tex');
ylabel(axS, 'flow at the plant boundary');
title(axS, {'Flow through the grid equivalent, signed as seen LEAVING the plant', ...
    'The plant exports MW and ABSORBS MVAr in all four cases', ...
    ['This branch carries the weakest number in the model: |Z| is ESTIMATED and ' ...
     'X/R is ASSUMED infinite (assumption A1)']}, 'FontSize', 9.5);
legend(axS, 'Location', 'eastoutside', 'FontSize', 8.5);
save_png(f3, fullfile(outd, 'line_loading.png'), opt.Show);

% =====================================================================
% 4. POWER BALANCE
% =====================================================================
f4 = figure('Visible', vis, 'Position', [60 60 1180 800]);
tl = tiledlayout(f4, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

axA = nexttile(tl); hold(axA, 'on'); grid(axA, 'on');
bar(axA, [Sy.P_export_MW, Sy.P_aux_MW, Sy.P_loss_MW], 'stacked');
plot(axA, 1:nc, Sy.P_gen_MW, 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 9, ...
    'LineStyle', 'none', 'DisplayName', 'P generated (dispatch setpoint)');
set(axA, 'XTick', 1:nc, 'XTickLabel', casesD, 'FontSize', 9.5, ...
    'TickLabelInterpreter', 'tex');
ylabel(axA, 'MW');
legend(axA, {'export at boundary', 'auxiliary load', 'losses (too thin to see)', ...
    'P generated (setpoint)'}, 'Location', 'eastoutside', 'FontSize', 9);
% The loss band is real but 0.2 % of the bar. Saying so stops a reader deciding
% it was left out.
for c = 1:nc
    text(axA, c, Sy.P_gen_MW(c), sprintf('%.4f MW\n', Sy.P_gen_MW(c)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8.5);
end
ylim(axA, [0 max(Sy.P_gen_MW)*1.14]);
title(axA, {['Real power balance: export + auxiliary + losses = generation ' ...
    '(marker sits on the stack top)'], ...
    ['Closes to 6e-13 MW in every case. The loss band IS drawn but is 0.2 % of ' ...
     'the bar - it is legible in the lower panel, not this one']}, 'FontSize', 9.5);

axB = nexttile(tl); hold(axB, 'on'); grid(axB, 'on');
yyaxis(axB, 'left');
b = bar(axB, Sy.P_loss_MW, 0.5); b.FaceColor = [0.30 0.45 0.70];
ylabel(axB, 'total loss (MW)');
for c = 1:nc
    text(axB, c, Sy.P_loss_MW(c), sprintf('%.5f MW\n(%.4f %% of gen)', ...
        Sy.P_loss_MW(c), Sy.Loss_pct_of_gen(c)), 'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', 'FontSize', 8.5);
end
ylim(axB, [0 max(Sy.P_loss_MW)*1.45]);
yyaxis(axB, 'right');
plot(axB, 1:nc, Sy.Worst_KCL_residual_MVA, 'r-s', 'LineWidth', 1.5, ...
    'MarkerFaceColor', 'r');
set(axB, 'YScale', 'log');
ylabel(axB, 'worst KCL residual (MVA, log)');
set(axB, 'XTick', 1:nc, 'XTickLabel', casesD, 'FontSize', 9.5, ...
    'TickLabelInterpreter', 'tex');
title(axB, {['Losses, and the independent cross-check: branch flows rebuilt ' ...
    'OUTSIDE the solver close KCL at every bus to the residual shown'], ...
    ['The looped cases sit four orders higher (6e-04 MVA) than the radial ones ' ...
     '(9e-08 MVA) - a closed loop is genuinely harder to close, and 6e-04 MVA ' ...
     'is still 1.6e-06 of the 375 MVA flowing']}, 'FontSize', 9.5);
save_png(f4, fullfile(outd, 'power_balance.png'), opt.Show);

fprintf('  4 figures written to %s\n', outd);
end

% =====================================================================
function save_png(f, path, keepOpen)
exportgraphics_compat(f, path);
[~, n, e] = fileparts(path);
fprintf('  %-32s written\n', [n e]);
if ~keepOpen, close(f); end
end

function exportgraphics_compat(f, path)
% exportgraphics exists from R2020a; print is the fallback. Checked rather than
% assumed, because an obsolete call is a documented project hazard.
if exist('exportgraphics', 'file')
    exportgraphics(f, path, 'Resolution', 150);
else
    print(f, path, '-dpng', '-r150');
end
end

function s = texsafe(x)
%TEXSAFE  Escape the three characters the TeX interpreter would consume.
%   Bus, branch and transformer names are read from CSVs, so they are data, not
%   literals in this file: an underscore in one of them must survive to the axis
%   as an underscore. Escaping here keeps the TeX interpreter available for the
%   log-axis exponents on the same figures.
s = cellstr(x);
for i = 1:numel(s)
    s{i} = regexprep(s{i}, '([_^\\])', '\\$1');
end
end
