function gui_tab_overview(tab, fig)
%GUI_TAB_OVERVIEW  Overview tab: metadata, system base, the case matrix.
%
%   Three panes:
%     left    every leaf of D.meta and D.base, as Field/Value
%     top     the LF1..LF4 case matrix, one row per case
%     bottom  what the study excludes, and the structural notes the dataset
%             carries about itself
%
%   The exclusions are given the same visual weight as the data. This study is
%   SOUTH plant only and load flow only; the North plant, the 400 kV network,
%   short circuit, protection coordination and transient stability are out of
%   scope. A reader who takes a number from this window needs to see that in
%   the window, not only in a header comment.
%
%   See also ASHUGANJ_GUI, GUI_STRUCT2LIST, GUI_STRUCT2TABLE.

app = fig.UserData;
D   = app.D;

g = uigridlayout(tab, [2 2]);
g.ColumnWidth = {'1x', '1.4x'};
g.RowHeight   = {'1.6x', '1x'};
g.Padding     = [8 8 8 8];

% ------------------------------------------------- left: metadata and base
pl = uipanel(g, 'Title', 'Project metadata and system base');
pl.Layout.Row    = [1 2];
pl.Layout.Column = 1;
gl = uigridlayout(pl, [1 1]);

meta.Project_metadata = D.meta;
meta.System_base      = D.base;
tl = uitable(gl);
tl.Data           = gui_struct2list(meta);
tl.ColumnWidth    = {230, 'auto'};
tl.ColumnSortable = false;   % Field/Value order is meaningful; sorting hides it

% ------------------------------------------------------ top right: cases
pc = uipanel(g, 'Title', 'Case matrix - all four cases are solved, not two');
pc.Layout.Row    = 1;
pc.Layout.Column = 2;
gc = uigridlayout(pc, [2 1]);
gc.RowHeight = {'1x', 54};

tc = uitable(gc);
tc.Data           = gui_struct2table(D.cases);
tc.ColumnSortable = true;

note = uilabel(gc);
note.Text     = char(gui_textify(getfield_or(D, 'case_matrix_note', ...
    'Dispatch (Q2c) and GAT in/out (Q4c) are independent, so the two choices define a 2x2 matrix.')));
note.WordWrap = 'on';
note.FontAngle = 'italic';

% ------------------------------------------- bottom right: scope and notes
ps = uipanel(g, 'Title', 'Scope, exclusions and structural notes');
ps.Layout.Row    = 2;
ps.Layout.Column = 2;
gs = uigridlayout(ps, [1 1]);

lines = [ "OUT OF SCOPE at this phase:"
          "  - " + strjoin(string(D.meta.Out_of_scope), newline + "  - ")
          ""
          "SCOPE: South plant, project " + string(D.meta.Project_no) + ...
              ". There is no 400 kV node anywhere in this dataset."
          "" ];

lines = [lines; describe_block("Structural notes", D, 'structural')];
lines = [lines; describe_block("Weakest link",     D, 'weakest_link')];
lines = [lines; describe_block("Superseded",       D, 'superseded')];

ta = uitextarea(gs);
ta.Value    = cellstr(splitlines(strjoin(lines, newline)));
ta.Editable = 'off';
ta.FontName = 'Consolas';
end

% =====================================================================
function out = describe_block(title, D, field)
%DESCRIBE_BLOCK  Render one optional top-level field as titled text lines.
%
%   The dataset gains and loses these self-description fields as it evolves -
%   D.superseded empties out when a superseded assumption is deleted outright.
%   A missing field is skipped silently rather than drawn as an error, so this
%   tab does not need editing every time the register list changes.
out = string.empty(0,1);
if ~isfield(D, field) || isempty(D.(field))
    return
end
v = D.(field);
out(end+1,1) = upper(title) + ":";
if isstruct(v) && isscalar(v)
    L = gui_struct2list(v);
    for i = 1:height(L)
        out(end+1,1) = "  " + L.Field(i) + " = " + L.Value(i);   %#ok<AGROW>
    end
elseif isstruct(v)
    out(end+1,1) = sprintf("  %d entries: %s", numel(v), strjoin(fieldnames(v)', ", "));
else
    out(end+1,1) = "  " + gui_textify(v);
end
out(end+1,1) = "";
end

% =====================================================================
function v = getfield_or(S, name, dflt)
%GETFIELD_OR  S.(name) if it exists, otherwise dflt.
if isfield(S, name) && ~isempty(S.(name))
    v = S.(name);
else
    v = dflt;
end
end
