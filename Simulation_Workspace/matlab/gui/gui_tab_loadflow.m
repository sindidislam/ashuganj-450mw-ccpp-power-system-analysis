function gui_tab_loadflow(tab, fig)
%GUI_TAB_LOADFLOW  Load Flow tab: pick the cases, solve them, read the outcome.
%
%   A checkbox per case in D.cases, the Write and SaveModels toggles
%   run_load_flow_study takes, a Solve button, one summary row per case with the
%   unit in every heading and the verdict cell coloured pass or fail, and the
%   captured solver output verbatim in a monospace pane.
%
%   NOTHING IS SOLVED TO DRAW THIS TAB: the rows come from system_summary.csv
%   through GUI_READ_RESULTS, so opening it is free and the numbers on screen are
%   the ones the plots and the report quote. A solve is 12-28 s for the first case
%   of a session while Simscape Electrical and powergui load and about 60 s for
%   all four, cannot be cancelled once entered, and runs on the thread that draws
%   this window - which therefore stops repainting and may be labelled "Not
%   Responding". Read as a crash that gets MATLAB killed mid-build, leaving a
%   half-wired model loaded, so the cost is stated beside the button AND again in
%   a confirmation naming the cases.
%
%   See also RUN_LOAD_FLOW_STUDY, GUI_RUN_CAPTURE, GUI_READ_RESULTS, GUI_SYMBOLS.

app = fig.UserData;  D = app.D;
h   = struct('fig', fig, 'root', app.root, 'D', D, 'ids', {{D.cases.ID}});

g = uigridlayout(tab, [3 1], 'RowHeight', {150, '1.05x', '1x'}, ...
    'Padding', [8 8 8 8], 'RowSpacing', 6);

% --------------------------------------------------------------- what to solve
gc = uigridlayout(uipanel(g, 'Title', 'What to solve'), [3 1], 'RowHeight', ...
    {28, 30, '1x'}, 'Padding', [8 6 8 6], 'RowSpacing', 4);
nc = numel(D.cases);
gk = uigridlayout(gc, [1 nc], 'Padding', [0 0 0 0], ...
    'ColumnWidth', repmat({'1x'}, 1, nc));
gat = {'out', 'in'};   h.cb = gobjects(1, nc);
for i = 1:nc
    C = D.cases(i);
    h.cb(i) = uicheckbox(gk, 'Value', true, 'Text', ...
        sprintf('%s  %s, GAT %s', C.ID, C.Gen_scenario, gat{1 + C.GAT_in}), ...
        'Tooltip', sprintf('%s\n%s\nP dispatch %.2f MW, %s topology', ...
                           C.Name, C.Purpose, C.Gen_P_MW, C.Topology));
end

gb = uigridlayout(gc, [1 5], 'Padding', [0 0 0 0], ...
    'ColumnWidth', {110, 215, 150, 205, '1x'});
h.write = uicheckbox(gb, 'Text', 'Write CSVs', 'Value', true, 'Tooltip', ...
    'Rewrite the six tables in results/load_flow and the per-case .rep reports');
h.save  = uicheckbox(gb, 'Text', 'Save the 6 deliverable .slx', 'Value', false, ...
    'Tooltip', 'Also rebuild simulink/main and simulink/studies (slower)');
h.btn   = uibutton(gb, 'Text', 'Solve selected', 'FontWeight', 'bold');
h.dir   = uibutton(gb, 'Text', 'Open results/load_flow');

uilabel(gc, 'WordWrap', 'on', 'FontColor', [0.45 0.20 0], 'Text', ...
 {['WHAT A SOLVE COSTS.  One build and one power_loadflow solve per case: 12-28 s ' ...
   'for the first of a MATLAB session, 1-2 s per case warm, about 60 s for all ' ...
   'four. It cannot be cancelled, and this window stops repainting until it ends.']
  ['WHAT IT OVERWRITES.  With Write on, the six CSVs and the per-case .rep in ' ...
   'results/load_flow - what every other tab reads. With SaveModels on, ' ...
   'simulink/main and the five study models, the old main backed up first. Turn ' ...
   'both off to solve and look without changing anything on disk.']});

% ------------------------------------------------------- summary, then the log
gs = uigridlayout(uipanel(g, 'Title', 'Case summary'), [3 1], 'RowHeight', ...
    {'1x', 24, 32}, 'Padding', [8 6 8 6], 'RowSpacing', 3);
h.tbl  = uitable(gs, 'ColumnSortable', false, 'SelectionType', 'row');
h.leg  = uilabel(gs, 'FontSize', 13);
h.stat = uilabel(gs, 'WordWrap', 'on');

gl = uigridlayout(uipanel(g, 'Title', 'Solver output, captured verbatim'), ...
    [2 1], 'RowHeight', {'1x', 26}, 'Padding', [8 6 8 6], 'RowSpacing', 3);
h.log = uitextarea(gl, 'Editable', 'off', 'FontName', 'Consolas');
gr = uigridlayout(gl, [1 2], 'Padding', [0 0 0 0], 'ColumnWidth', {340, '1x'});
h.rep = uibutton(gr, 'Text', 'Open the powergui .rep of the selected case');

% Wired only now, so each closure captures a COMPLETE h - one wired earlier would
% hold a copy of h taken before h.tbl and h.log existed.
[~, ~, leg] = spec();
if ~isempty(leg), h.leg.Interpreter = 'latex';  h.leg.Text = leg; end
h.btn.ButtonPushedFcn = @(s,e) do_solve(h);
h.dir.ButtonPushedFcn = @(s,e) open_it(h, 'dir');
h.rep.ButtonPushedFcn = @(s,e) open_it(h, 'rep');

Res = cached_results(h, false);
refresh(h, Res.system, false, sprintf('From system_summary.csv - %s.  %s', ...
        Res.staleness.Verdict, Res.staleness.Detail));
h.log.Value = cellstr([ ...
    "Nothing has been run in this session yet. This pane fills with everything the"
    "study prints, captured verbatim, error report included if it fails."
    "Tables above read from: " + string(Res.dir)]);
end

% =====================================================================
function do_solve(h)
%DO_SOLVE  Confirm the cost, run the study through GUI_RUN_CAPTURE, show both.
sel = h.ids(logical([h.cb.Value]));
if isempty(sel)
    uialert(h.fig, 'Select at least one case to solve.', 'Nothing selected');
    return
end
n = numel(sel);  w = logical(h.write.Value);  sv = logical(h.save.Value);
onoff = {'off', 'on'};
msg = { sprintf('Solve %d case(s): %s.   Write CSVs: %s.   Save .slx: %s.', ...
                n, strjoin(sel, ', '), onoff{1+w}, onoff{1+sv})
        sprintf(['Expect roughly %d to %d s, plus 12-28 s more if this is the ' ...
                 'first solve of the MATLAB session.'], (8+5*sv)*n, (20+10*sv)*n)
        ['It cannot be cancelled, and the window cannot repaint while it runs: ' ...
         'the tabs will not respond and Windows may add "Not Responding". Do not ' ...
         'click, and do not press Ctrl-C - an interrupt lands mid-build and ' ...
         'leaves a half-wired model loaded in Simulink.'] };
if ~strcmp(uiconfirm(h.fig, msg, 'Solve now?', 'Options', {'Solve', 'Cancel'}, ...
        'DefaultOption', 2, 'CancelOption', 2, 'Icon', 'warning'), 'Solve')
    return
end

[ok, txt, S] = gui_run_capture(h.fig, sprintf('Solving %s', strjoin(sel, ' ')), ...
    @() run_load_flow_study('Cases', sel, 'Write', w, 'SaveModels', sv), 1);
h.log.Value = cellstr(splitlines(string(txt)));
if ~ok
    h.stat.Text = 'The run FAILED; the error report is at the end of the log below.';
    return
elseif ~(isstruct(S) && ~isempty(S))
    h.stat.Text = 'The study returned no cases - see the log below.';
    return
end

disk = {['Write was off: nothing on disk changed, so every other tab still shows ' ...
         'the previous run.'], 'The six CSVs and the per-case .rep were rewritten.'};
bad  = sum(arrayfun(@(x) isempty(x.B), S));
note = sprintf('%d case(s) solved, %d with a bus solution, %d without.  %s', ...
               numel(S), numel(S) - bad, bad, disk{1+w});
if w, Res = cached_results(h, true);
    note = sprintf('%s  Tables on disk now dated %s.', note, Res.newest_str);
end
refresh(h, S, true, note);
end

% =====================================================================
function refresh(h, src, fromS, note)
%REFRESH  Build the summary table from either source, colour it, caption it.
%   One column spec serves system_summary.csv and the struct array the study
%   returns, so the two views cannot drift apart, and a column the CSV does not
%   carry degrades to NaN or "" rather than throwing. Green is for a literal OK
%   only: anything else is the study's check failures or the solver's own
%   non-convergence message, and either way that row must not be quoted.
[sp, names] = spec();
if fromS, n = numel(src); else, n = height(src); end
c = cell(1, size(sp,1));
for j = 1:size(sp,1)
    num = sp{j,5};
    if num, c{j} = nan(n,1); else, c{j} = strings(n,1); end
    for i = 1:n
        v = [];
        if fromS
            if isfield(src, sp{j,4}), v = src(i).(sp{j,4}); end
        elseif any(strcmp(src.Properties.VariableNames, sp{j,3}))
            u = src.(sp{j,3});  v = u(i);
        end
        if ~num, c{j}(i) = gui_textify(v);  continue, end
        if isempty(v), v = NaN; end
        if ~(isnumeric(v) || islogical(v)), v = str2double(string(v(1))); end
        c{j}(i) = double(v(1));
    end
end
T = table(c{:}, 'VariableNames', sp(:,1)');

% Convergence is judged on .B, never on the verdict prose; and only the struct
% array can carry a case with no solution at all.
if fromS && isfield(src, 'B')
    for i = 1:n
        if isempty(src(i).B), T.Verdict(i) = "DID NOT CONVERGE - " + T.Verdict(i); end
    end
end
h.tbl.Data = T;  h.tbl.ColumnName = names;  removeStyle(h.tbl);  h.stat.Text = note;
if n == 0
    h.stat.Text = ['Nothing on disk yet: results/load_flow/system_summary.csv is ' ...
        'absent or empty. Pick the cases above and press Solve selected.'];
    return
end
sty  = { uistyle('BackgroundColor', [0.97 0.86 0.86], 'FontColor', [0.6 0 0], ...
         'FontWeight', 'bold'), uistyle('BackgroundColor', [0.86 0.94 0.86], ...
         'FontColor', [0 0.35 0]) };
pass = strcmpi(strtrim(T.Verdict), "OK");
for k = 0:1
    r = find(pass == k);
    if ~isempty(r), addStyle(h.tbl, sty{k+1}, 'cell', [r(:) r(:)*0 + width(T)]); end
end
h.tbl.Selection = 1;
end

% =====================================================================
function [sp, names, leg] = spec()
%SPEC  variable | caption | CSV column | field of S | numeric | fallback symbol.
%   uitable draws column names as plain text, so the unit lives in the caption;
%   the symbol is typeset in a uilabel with Interpreter latex, the only in-window
%   typesetting R2024a offers - MathJax cannot run inside uihtml. GUI_SYMBOLS owns
%   both strings, the symbol below is the fallback for a key it lacks, and the unit
%   then comes from the _MW/_MVAr naming the registers use - so no quantity is
%   shown without its unit and no unit is typed twice.
sp = { 'Case',          'Case',        'Case',          'ID',            false, ''
       'Description',   'Description', 'Description',   'Name',          false, ''
       'P_gen_MW',      'P generated', 'P_gen_MW',      'Gen_P_MW',      true,  'P_{gen}'
       'Q_gen_MVAr',    'Q generated', 'Q_gen_MVAr',    'Gen_Q_MVAr',    true,  'Q_{gen}'
       'P_export_MW',   'P export',    'P_export_MW',   'Export_P_MW',   true,  'P_{exp}'
       'Q_export_MVAr', 'Q export',    'Q_export_MVAr', 'Export_Q_MVAr', true,  'Q_{exp}'
       'P_loss_MW',     'P loss',      'P_loss_MW',     'Loss_P_MW',     true,  'P_{loss}'
       'Iterations',    'Iterations',  'Iterations',    'Iterations',    true,  ''
       'Worst_KCL_MVA', 'Worst KCL residual', 'Worst_KCL_residual_MVA', ...
                                              'Worst_Residual_MVA',     true,  '\Delta S'
       'Verdict',       'Verdict',     'Checks',        'Verdict',       false, '' };
if nargout < 2, return, end

names = sp(:,2);  bits = string.empty(1,0);
for i = 1:numel(names)
    u = '';  tex = sp{i,6};
    try
        q = gui_symbols(sp{i,3});
        if isfield(q, 'units'), u = char(gui_textify(q.units)); end
        if isfield(q, 'latex')
            t = strrep(char(gui_textify(q.latex)), '$', '');
            if ~isempty(t), tex = t; end
        end
    catch
        % Not in the map, or the map is not on the path yet: fall back below.
    end
    if any(strcmpi(u, {'-', '1', 'none', 'dimensionless', 'count'})), u = ''; end
    if isempty(u)
        m = regexp(sp{i,3}, '_(MVAr|MVA|MW|kV|pu|pct|deg|Hz)$', 'tokens', 'once');
        if ~isempty(m), u = strrep(m{1}, 'pct', '%'); end
    end
    if isempty(u), continue, end   % Iterations is a count; a unit there is noise
    names{i} = sprintf('%s  [%s]', names{i}, u);
    if ~isempty(tex)
        bits(end+1) = string(tex) + "\;[\mathrm{" + strrep(u, '%', '\%') + "}]"; %#ok<AGROW>
    end
end
leg = '';
if ~isempty(bits), leg = ['$' char(strjoin(bits, "\quad ")) '$']; end
end

% =====================================================================
function Res = cached_results(h, force)
%CACHED_RESULTS  GUI_READ_RESULTS, cached in fig.UserData, never fatal.
%   The shell rebuilds every tab on Reload, so the six readtable calls happen once
%   per dataset load - unless a solve has just rewritten the files (force).
app = h.fig.UserData;
if ~force && isfield(app, 'lf_results') && isstruct(app.lf_results)
    Res = app.lf_results;  return
end
try
    Res = gui_read_results(h.root, h.D);
catch err
    Res = struct('dir', fullfile(h.root, 'results', 'load_flow'), ...
        'system', table(), 'newest_str', '', ...
        'staleness', struct('Verdict', 'UNREADABLE', 'Detail', err.message));
end
app.lf_results = Res;  h.fig.UserData = app;
end

% =====================================================================
function open_it(h, what)
%OPEN_IT  Hand the results folder, or the selected case's .rep, to the shell.
%   The .rep is the solver speaking - its SUMMARY totals only the auxiliary
%   subnetwork - so it is opened verbatim and never parsed for a project figure.
p = fullfile(h.root, 'results', 'load_flow');
if strcmp(what, 'rep')
    r = h.tbl.Selection;
    if isempty(h.tbl.Data) || isempty(r)
        uialert(h.fig, 'Select a case row in the summary table first.', 'No case');
        return
    end
    p = fullfile(p, char(h.tbl.Data.Case(r(1)) + "_powergui_report.rep"));
end
if ~(isfile(p) || isfolder(p))
    uialert(h.fig, sprintf('%s does not exist yet. Solve first.', p), 'Nothing there');
    return
end
try
    winopen(p);
catch err
    uialert(h.fig, err.message, 'Could not open');
end
end
