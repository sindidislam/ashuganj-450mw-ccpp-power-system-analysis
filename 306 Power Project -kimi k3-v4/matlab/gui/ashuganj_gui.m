function fig = ashuganj_gui()
%ASHUGANJ_GUI  Interactive front end for the Ashuganj SOUTH load flow study.
%
%   ASHUGANJ_GUI opens one window with eleven tabs:
%
%     Overview      project metadata, system base, the LF1..LF4 case matrix
%     Formulation   the mathematics of this study, rendered as LaTeX
%     Equipment     every register in the dataset, as a sortable table
%     Assumptions   the disclosed assumptions, with the reason for each
%     Load Flow     pick cases, solve them, read the solver's own output
%     Results       the written CSVs in results/load_flow/
%     Analysis      the GAT effect and the dispatch effect, separated
%     Plots         the written PNGs in results/plots/ and results/diagrams/
%     Model         open or rebuild the Simulink models
%     Tests         run the test suite and read the outcome
%     Export        compile everything into one standalone HTML report
%
%   NOTHING HERE REQUIRES FINDING A FILE BY HAND
%   --------------------------------------------
%   Every artefact the study produces is reachable from a button: the .slx
%   models open in Simulink, the PNGs render in the window, the CSVs are shown
%   as tables, the solver's own .rep reports open, and Export writes one
%   self-contained HTML document with the equations typeset. Browsing
%   matlab/ and simulink/ by hand is no longer part of using this study.
%
%   THIS GUI OWNS NO NUMBERS
%   ------------------------
%   Every value shown here is read from ashuganj_master_data or from the CSVs
%   that run_load_flow_study wrote. Nothing is recomputed and nothing is typed
%   twice, for the same reason make_load_flow_plots reads the CSVs instead of
%   re-solving: a display that silently disagrees with the tables is worse than
%   no display. If a table looks stale, re-solve on the Load Flow tab.
%
%   WHY THE TABS LIVE IN SEPARATE FILES
%   -----------------------------------
%   One file per tab (gui_tab_*.m), not one monolith. A single 2000-line app
%   file is what an earlier attempt at this GUI choked on: it could not be
%   written or reviewed in one piece. Each tab here is independently readable
%   and independently editable, and this shell only wires them together.
%
%   Requires R2024a (the project toolchain) for uifigure/uigridlayout.
%
%   See also ASHUGANJ_MASTER_DATA, RUN_LOAD_FLOW_STUDY, MAKE_LOAD_FLOW_PLOTS.

% The dataset is loaded ONCE here and cached in fig.UserData. Every register in
% ashuganj_master_data is self-validating, so loading it costs real time; a tab
% that reloaded it on each click would make the window feel broken.
app.D    = ashuganj_master_data();
app.root = ashuganj_root();

fig = uifigure('Name', 'Ashuganj 450 MW CCPP (South) - Load Flow Study', ...
               'Position', [80 60 1280 800]);
fig.UserData = app;

outer = uigridlayout(fig, [2 1]);
outer.RowHeight   = {46, '1x'};
outer.ColumnWidth = {'1x'};
outer.Padding     = [8 8 8 8];
outer.RowSpacing  = 6;

% ------------------------------------------------------------------- header
head = uigridlayout(outer, [1 2]);
head.ColumnWidth = {'1x', 200};
head.Padding     = [4 0 4 0];
head.Layout.Row  = 1;

ttl = uilabel(head);
ttl.Text       = sprintf('%s   |   %s   |   base %g MVA, %g Hz', ...
                         app.D.meta.Project, app.D.meta.Study, ...
                         app.D.base.Sbase_MVA, app.D.base.f_Hz);
ttl.FontSize   = 14;
ttl.FontWeight = 'bold';

btn = uibutton(head);
btn.Text = 'Reload dataset';
btn.Tooltip = 'Re-run ashuganj_master_data and rebuild every tab';
btn.ButtonPushedFcn = @(s,e) reload_all(fig, outer);

% --------------------------------------------------------------------- tabs
build_tabs(fig, outer);
end

% =====================================================================
function build_tabs(fig, outer)
%BUILD_TABS  Create the tab group and hand each tab to its own builder.
tg = uitabgroup(outer);
tg.Layout.Row = 2;
tg.Tag        = 'MainTabs';

specs = { 'Overview',    @gui_tab_overview    ; ...
          'Formulation', @gui_tab_formulation ; ...
          'Equipment',   @gui_tab_equipment   ; ...
          'Assumptions', @gui_tab_assumptions ; ...
          'Load Flow',   @gui_tab_loadflow    ; ...
          'Results',     @gui_tab_results     ; ...
          'Analysis',    @gui_tab_analysis    ; ...
          'Plots',       @gui_tab_plots       ; ...
          'Model',       @gui_tab_model       ; ...
          'Tests',       @gui_tab_tests       ; ...
          'Export',      @gui_tab_export      };

for i = 1:size(specs, 1)
    t = uitab(tg, 'Title', specs{i,1});
    name = func2str(specs{i,2});
    name = erase(name, '@');

    % A tab whose builder has not been written yet says so, plainly, instead of
    % throwing "Unrecognized function". The app is built one tab per file
    % precisely so that an unfinished tab costs nothing; this is what that
    % promise looks like from the window.
    if isempty(which(name))
        pending_pane(t, specs{i,1}, name);
        continue
    end

    % A tab that errors must not take the rest of the window with it: the
    % other tabs are still usable, and the failure is shown where the tab
    % would have been rather than only in the command window.
    try
        specs{i,2}(t, fig);
    catch err
        g = uigridlayout(t, [1 1]);
        lab = uilabel(g);
        lab.Text = sprintf('This tab failed to build:\n\n%s\n\n(%s)', ...
                           err.message, err.identifier);
        lab.WordWrap    = 'on';
        lab.FontColor   = [0.6 0 0];
        lab.HorizontalAlignment = 'center';
    end
end
end

% =====================================================================
function pending_pane(tab, title, name)
%PENDING_PANE  Placeholder for a tab whose builder file does not exist yet.
g = uigridlayout(tab, [1 1]);
lab = uilabel(g);
lab.Text = sprintf(['The %s tab is not built yet.\n\n' ...
    'It will live in matlab/gui/%s.m\n\n' ...
    'Every other tab works without it. Nothing in the dataset, the study or ' ...
    'the results depends on this file.'], title, name);
lab.WordWrap  = 'on';
lab.FontColor = [0.35 0.35 0.35];
lab.HorizontalAlignment = 'center';
end

% =====================================================================
function reload_all(fig, outer)
%RELOAD_ALL  Re-read the dataset and rebuild every tab from it.
d = uiprogressdlg(fig, 'Title', 'Reloading', ...
                  'Message', 'Running ashuganj_master_data...', ...
                  'Indeterminate', 'on');
cleanup = onCleanup(@() close(d));

app = fig.UserData;
app.D = ashuganj_master_data();
fig.UserData = app;

old = findobj(outer, 'Tag', 'MainTabs');
delete(old);
build_tabs(fig, outer);
end
