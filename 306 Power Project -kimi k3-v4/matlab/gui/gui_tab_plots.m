function gui_tab_plots(tab, fig)
%GUI_TAB_PLOTS  Plots tab: the written PNGs, and what each one is actually showing.
%
%   Left    every figure this study writes, present or absent, with its size.
%   Right   the selected PNG, and under it what the figure shows, why its axis
%           scale was chosen, and the symbol and unit of every quantity on it.
%
%   THE PNGs ARE READ FROM DISK, NEVER REDRAWN HERE
%   -----------------------------------------------
%   MAKE_LOAD_FLOW_PLOTS owns these four charts and builds them from the same
%   CSVs the report quotes. A tab that plotted its own copy would put a second
%   set of numbers on screen with no way to tell which set the report was built
%   from - the same reason GUI_READ_RESULTS reads the written tables instead of
%   re-solving. Regenerate calls that function unmodified, through
%   GUI_RUN_CAPTURE, and then re-reads what it wrote.
%
%   WHY EVERY CAPTION ARGUES ABOUT A SCALE
%   --------------------------------------
%   Three of the four charts are unreadable on the obvious axis: the open-bay GAT
%   at 0.065 MVA vanishes beside the GSUT at 376 MVA on a linear axis, the radial
%   cases' 9e-08 MVA KCL residual flattens onto zero beside the looped 6e-04, and
%   the floating GAT HV terminal drags the voltage profile down until every
%   busbar looks sick. The log axes, the per-cent-of-lowest-stage panel and the
%   split GAT panel are those three decisions. A reader not told that a scale was
%   chosen will read the choice as the result, so the scale is in the caption.
%
%   A MISSING PNG IS NAMED, NOT BLANK: the caption gives the command that writes
%   it and what that command costs, because the annotated sheets cost about 90 s
%   and a full re-solve while the charts cost about 10 s and touch no Simulink.
%
%   See also MAKE_LOAD_FLOW_PLOTS, MAKE_ANNOTATED_DIAGRAMS, GUI_RUN_CAPTURE.

app = fig.UserData;
% figspec() is a struct ARRAY, so it is wrapped in a cell: struct() would
% otherwise replicate h into one element per figure.
h = struct('fig', fig, 'root', app.root, 'spec', {figspec()});

g = uigridlayout(tab, [2 2]);
g.ColumnWidth = {360, '1x'};  g.RowHeight = {'1x', 235};
g.Padding     = [8 8 8 8];    g.RowSpacing = 6;

% ------------------------------------------------------------ left: the gallery
pl = uipanel(g, 'Title', 'Figures this study writes');
pl.Layout.Row = [1 2];  pl.Layout.Column = 1;
gl = uigridlayout(pl, [5 1]);
gl.RowHeight = {'1x', 28, 28, 30, 116};  gl.Padding = [8 6 8 6];  gl.RowSpacing = 5;

h.list  = uilistbox(gl, 'FontName', 'Consolas', 'Items', {'(reading)'});
h.open  = uibutton(gl, 'Text', 'Open the selected PNG in the image viewer');
h.dir   = uibutton(gl, 'Text', 'Open the folder it lives in');
h.regen = uibutton(gl, 'Text', 'Regenerate the 4 charts (about 10 s)', ...
                   'FontWeight', 'bold');
uilabel(gl, 'WordWrap', 'on', 'FontColor', [0.45 0.20 0], 'Text', ...
 {['REGENERATE runs make_load_flow_plots(): it re-reads four CSVs from ' ...
   'results/load_flow and OVERWRITES the four PNGs in results/plots. No Simulink, ' ...
   'no re-solve - so the charts show whatever the last solve wrote.']
  ['The annotated sheets are NOT rebuilt here. make_annotated_diagrams re-solves ' ...
   'every case and drives Simulink for about 90 s; run it from the command window.']});

% ------------------------------------------------------------- right: the image
pi = uipanel(g, 'Title', 'Scaled to fit - use the viewer button to zoom');
pi.Layout.Row = 1;  pi.Layout.Column = 2;
h.img = uiimage(uigridlayout(pi, [1 1]), 'ScaleMethod', 'fit');

% ----------------------------------------------------------- right: the caption
pc = uipanel(g, 'Title', 'What this figure shows, and what its scale was chosen for');
pc.Layout.Row = 2;  pc.Layout.Column = 2;
gc = uigridlayout(pc, [2 1]);
gc.RowHeight = {'1x', 26};  gc.Padding = [8 6 8 6];  gc.RowSpacing = 3;
h.cap = uitextarea(gc, 'Editable', 'off', 'FontName', 'Consolas', 'WordWrap', 'on');
h.leg = uilabel(gc, 'FontSize', 13, 'Interpreter', 'latex');

% Wired only now, so every closure holds a COMPLETE h: one wired earlier would
% carry a copy of the struct taken before h.cap and h.leg existed.
h.list.ValueChangedFcn  = @(s,e) show_one(h);
h.open.ButtonPushedFcn  = @(s,e) open_it(h, 'file');
h.dir.ButtonPushedFcn   = @(s,e) open_it(h, 'dir');
h.regen.ButtonPushedFcn = @(s,e) do_regen(h);

refresh_list(h);
if isfield(app, 'plots_selected')
    k = find(strcmp({h.spec.Key}, app.plots_selected), 1);
    if ~isempty(k), h.list.Value = k; end
end
show_one(h);
end

% =====================================================================
function S = figspec()
%FIGSPEC  The gallery: where each figure lives, what writes it, what it says.
%   The captions describe the CONSTRUCTION of each figure - quantity, axis,
%   reference line - and quote no result. The figure titles cannot be reused for
%   this: they are literals inside MAKE_LOAD_FLOW_PLOTS and several have drifted
%   from the CSVs (the sheet calls the open-bay GAT bar 0.003 MVA, which is its
%   HV terminal alone, where the bar is max of the two terminals, 0.065 MVA).
S = entry('plots', 'bus_voltage_profile.png', ...
    'make_load_flow_plots()   - the Regenerate button runs exactly this', ...
    'about 10 s, reads four CSVs, no Simulink', {'V_pu', 'V', 'pu'}, [
 "UPPER  |V| at the four SOLVED buses in electrical path order, one line per case,"
 "       1.00 pu dotted.  LOWER  the GAT HV terminal, alone."
 "SCALE  Linear, each bus on ITS OWN nominal - not a common base. Merged nodes are"
 "       omitted: the three 6.6 kV register buses are ONE solved node (feeder"
 "       impedances MISSING), and so are the two 230 kV busbars (coupler closed)."
 "SPLIT  With bay 10BAY20 open the GAT HV terminal floats at the 230/6.9 kV turns"
 "       ratio, near 0.957 pu - not a system voltage. On the profile axis it reads as"
 "       a busbar undervoltage, and flattens the four real buses into one line."
 "READ   B22 is exactly 1.000 pu because it was SET there, not solved. B6_6 is one"
 "       node on two bases (conflict C13); the profile uses the 6600 V nominal." ]);

S(2) = entry('plots', 'transformer_loading.png', S(1).Writer, S(1).Cost, ...
    {'S_HV_MVA', 'S', 'MVA'; 'Loading_pct_lowest_stage', 'S/S_{ONAN}', '%'}, [
 "UPPER  S at the more loaded terminal, max(S_LV, S_HV), per transformer per case,"
 "       with every documented cooling stage drawn across it: lowest stage solid,"
 "       higher stages dashed.  LOWER  the same flow as per cent of the lowest."
 "SCALE  LOG MVA above, 1e-3 to 2e3, because the GSUT near 376 MVA and the open-bay"
 "       GAT near 0.065 MVA cannot share a linear axis - the GAT bar becomes white"
 "       space and reads as ZERO rather than as magnetising current."
 "WHY THE LOWEST STAGE  The red 100 % line is the ONAN rating (GSUT 355 MVA, UAT and"
 "       GAT 19 MVA): what the unit carries with no forced cooling running, so a"
 "       crossing means cooling MUST run. Nothing crosses the highest stage." ]);

S(3) = entry('plots', 'line_loading.png', S(1).Writer, S(1).Cost, ...
    {'I_A', 'I', 'A'; 'P_from_MW', 'P', 'MW'; 'Q_from_MVAr', 'Q', 'MVAr'
     'S_from_MVA', 'S', 'MVA'}, [
  "UPPER  Current in the three 230 kV paths that have an observable one - the grid"
  "       equivalent, GSUT bay 10BAY11, GAT bay 10BAY20 - against the documented"
  "       3150 A bus-coupler/busbar module rating (bays 2000 A), drawn in red."
  "SCALE  Linear A rms, axis pinned at 3150 A x 1.12 so the rating stays in frame and"
  "       the headroom reads straight off the gap. That is the only GIS-level current limit this"
  "       dataset documents: the 50 kA equipment withstand (1 s+3 s) and 125 kA peak"
  "       are 1 s/peak ratings, not continuous ones, so they are deliberately not drawn."
 "ABSENT BUS COUPLER 10BAY12 is a zero-impedance CLOSED breaker, so the solver merges"
 "       BUS 1 with BUS 2 and its flow is NOT OBSERVABLE from bus voltages: NaN in"
 "       line_results.csv, which is not the same as zero."
 "LOWER  Grid-equivalent flow signed as LEAVING the plant - MW out, MVAr in, in all"
 "       four cases. Its |Z| is ESTIMATED and X/R assumed infinite: the weakest"
 "       number in the model sits on this one branch." ]);

S(4) = entry('plots', 'power_balance.png', S(1).Writer, S(1).Cost, ...
    {'P_gen_MW', 'P_{gen}', 'MW'; 'P_export_MW', 'P_{exp}', 'MW'
     'P_loss_MW', 'P_{loss}', 'MW'; 'Worst_KCL_residual_MVA', '\Delta S', 'MVA'}, [
 "UPPER  Export, auxiliary load and losses stacked in MW, with P generated as a black"
 "       triangle: the marker sitting on the stack top IS the balance check."
 "LOWER  Total loss in MW on the left axis, worst KCL residual in MVA on the right."
 "SCALE  Linear MW above; the loss band IS drawn, but it is 0.2 % of the bar and too"
 "       thin to see, which is why the lower panel exists at all. LOG on the right"
 "       axis below - the looped cases sit four orders above the radial ones, near"
 "       6e-04 against 9e-08 MVA, and linear would flatten the radial pair onto zero."
 "READ   That residual is an INDEPENDENT check, not the solver marking its own work:"
 "       branch flows are rebuilt outside power_loadflow and closed against KCL at"
 "       every unmerged bus. The study fails a case above 0.05 MVA." ]);

% The four annotated sheets differ only in the case they carry, so one caption
% serves all four, and each is listed whether or not it exists - the last run of
% make_annotated_diagrams may have covered one case only.
for c = 1:4
    id = sprintf('LF%d', c);
    S(end+1) = entry('diagrams', ['Load_Flow_' id '_Annotated.png'], ...
        sprintf('make_annotated_diagrams(''Cases'', {''%s''})', id), ...
        ['about 90 s: it re-solves the case with Write off, rebuilds the model ' ...
         'with the solution stamped on the sheet, then prints it at -r100'], ...
        {'V_pu', 'V', 'pu'; 'P_MW', 'P', 'MW'; 'Q_MVAr', 'Q', 'MVAr'}, [
 "The whole single-line Simulink sheet for " + id + ", printed at -r100 (1.3916 px per"
 "model unit, the resolution that keeps the 8 pt footer legible at slide width), with"
 "THIS case's solved result stamped into the footer band by build_ashuganj_main."
 "SCALE  None: it is a printed model sheet, not a chart, so no axis was chosen. The"
 "       pane above shrinks 2608 x 1803 px to fit and the footer text does not survive"
 "       that - open it in the viewer to read the stamp."
 "READ   simulink/studies/Load_Flow_" + id + ".slx is the same network without the"
 "       numbers. simulink/main is deliberately never annotated: a stamp would date"
 "       the deliverable model to one case." ]);                          %#ok<AGROW>
end
end

% =====================================================================
function S = entry(folder, file, writer, cost, sym, txt)
%ENTRY  One gallery record. Cell-wrapped values keep it a SCALAR struct.
[~, key] = fileparts(file);
S = struct('Key', key, 'Folder', folder, 'File', file, 'Writer', writer, ...
           'Cost', cost, 'Sym', {sym}, 'Text', {txt});
end

% =====================================================================
function refresh_list(h)
%REFRESH_LIST  Re-stat every figure and relabel the picker, keeping the choice.
%   Nothing is cached: the whole point of Regenerate is that these files change
%   underneath the tab, so the inventory is taken again on every redraw.
n = numel(h.spec);  items = cell(1, n);
for i = 1:n
    d  = dir(fullfile(h.root, 'results', h.spec(i).Folder, h.spec(i).File));
    st = 'ABSENT';
    if ~isempty(d), st = sprintf('%.0f kB', d(1).bytes / 1024); end
    items{i} = sprintf('%-28s %8s', h.spec(i).File, st);
end
was = 1;
if isnumeric(h.list.Value) && ~isempty(h.list.Value), was = h.list.Value; end
h.list.Items     = items;
h.list.ItemsData = 1:n;
h.list.Value     = min(max(1, was), n);
end

% =====================================================================
function show_one(h)
%SHOW_ONE  Render the selected PNG, its file facts, its caption, its symbols.
S = h.spec(h.list.Value);
f = fullfile(h.root, 'results', S.Folder, S.File);
d = dir(f);

if isempty(d)
    h.img.ImageSource = '';   % the documented empty value; a bad path would error
    head = [ "THIS FIGURE HAS NOT BEEN WRITTEN YET."
             "expected at  " + string(f)
             "written by   " + string(S.Writer)
             "that costs   " + string(S.Cost)
             "" ];
else
    h.img.ImageSource = f;
    px = "";
    try
        q  = imfinfo(f);      % header only, so this stays cheap on a 570 kB sheet
        px = sprintf(', %d x %d px', q(1).Width, q(1).Height);
    catch
        px = "";              % uiimage may still draw what imfinfo cannot describe
    end
    head = [ "FILE   " + string(f)
             sprintf('       %.0f kB%s, written %s', d(1).bytes/1024, px, ...
                 char(string(datetime(d(1).datenum, 'ConvertFrom', 'datenum'), ...
                             'yyyy-MM-dd HH:mm')))
             "" ];
end
h.cap.Value = cellstr([head; S.Text]);
h.leg.Text  = symbol_legend(S.Sym);

% Cached so the shell's Reload, which deletes and rebuilds every tab, returns to
% the figure that was on screen instead of to the first one.
app = h.fig.UserData;  app.plots_selected = S.Key;  h.fig.UserData = app;
end

% =====================================================================
function leg = symbol_legend(sym)
%SYMBOL_LEGEND  LaTeX symbol and unit for every quantity the figure plots.
%   Interpreter latex on a uilabel is the only typesetting available in-window:
%   uihtml cannot reach a CDN, so MathJax will not run there. GUI_SYMBOLS owns
%   both strings; the pair given per figure is the fallback for a key the map
%   does not carry, so no quantity is ever shown without its unit.
bits = strings(1, 0);
for i = 1:size(sym, 1)
    tex = sym{i,2};  u = sym{i,3};
    try
        q = gui_symbols(sym{i,1});
        if isstruct(q) && isscalar(q)
            if isfield(q, 'units') && ~isempty(q.units)
                u = char(gui_textify(q.units));
            end
            if isfield(q, 'latex')
                t = strrep(char(gui_textify(q.latex)), '$', '');
                if ~isempty(t), tex = t; end
            end
        end
    catch
        % Absent from the map, or the map is not on the path yet: keep the pair.
    end
    bits(end+1) = string(tex) + "\;[\mathrm{" + strrep(u, '%', '\%') + "}]"; %#ok<AGROW>
end
leg = '';
if ~isempty(bits), leg = ['$' char(strjoin(bits, "\quad ")) '$']; end
end

% =====================================================================
function do_regen(h)
%DO_REGEN  Run MAKE_LOAD_FLOW_PLOTS through GUI_RUN_CAPTURE, then re-read disk.
%   nOut is 0 because the function declares no outputs, so asking it for one is
%   an error rather than an empty. It overwrites four PNGs, hence the confirm.
msg = { 'Run make_load_flow_plots() now?'
        ['It re-reads bus_results, transformer_results, line_results and ' ...
         'system_summary from results/load_flow and OVERWRITES the four PNGs in ' ...
         'results/plots. About 10 s, no Simulink, and it does not re-solve.']
        ['It builds four real figure windows with Visible off and closes them ' ...
         'itself. This window cannot repaint until it returns.'] };
if ~strcmp(uiconfirm(h.fig, msg, 'Regenerate the charts?', 'Options', ...
        {'Regenerate', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 2), 'Regenerate')
    return
end

[ok, txt] = gui_run_capture(h.fig, 'make_load_flow_plots', ...
                            @() make_load_flow_plots(), 0);
refresh_list(h);
show_one(h);
h.cap.Value = [ cellstr(splitlines(string(txt)))
                {''; 'Pick a figure in the list to return to its caption.'} ];
if ~ok
    uialert(h.fig, ['make_load_flow_plots did not finish - its output and the error ' ...
        'report are in the caption pane. If it names missingTable, the CSVs it ' ...
        'plots have not been written: solve on the Load Flow tab first.'], ...
        'Regenerate failed');
end
end

% =====================================================================
function open_it(h, what)
%OPEN_IT  Hand the selected PNG, or the folder it lives in, to the shell.
%   winopen rather than a uihyperlink: this project root contains two spaces, and
%   a file:/// URL would need percent-encoding to survive them.
S = h.spec(h.list.Value);
p = fullfile(h.root, 'results', S.Folder);
if strcmp(what, 'file'), p = fullfile(p, S.File); end
if ~(isfile(p) || isfolder(p))
    uialert(h.fig, sprintf('%s\n\ndoes not exist yet. It is written by\n\n  %s\n\n%s', ...
            p, S.Writer, S.Cost), 'Nothing there');
    return
end
try
    winopen(p);
catch err
    uialert(h.fig, err.message, 'Could not open');
end
end
