function T = gui_struct2list(S, prefix)
%GUI_STRUCT2LIST  Flatten a scalar struct into a Field/Value table.
%
%   T = GUI_STRUCT2LIST(S) walks a SCALAR struct such as D.meta or D.base and
%   returns a two-column table, Field and Value, with one row per leaf. Nested
%   scalar structs are recursed into and their rows prefixed with 'parent.', so
%   D.base.Sbase_MVA appears as the row 'Sbase_MVA' and a nested
%   D.grid.Thevenin.X_pu would appear as 'Thevenin.X_pu'.
%
%   A nested struct ARRAY is not recursed into - it is a register, not
%   metadata, and belongs in a table of its own via GUI_STRUCT2TABLE. Such a
%   field is listed with its element count so the reader knows it exists and
%   where to look.
%
%   See also GUI_STRUCT2TABLE, GUI_TAB_OVERVIEW.

if nargin < 2, prefix = ''; end

names  = string.empty(0,1);
values = string.empty(0,1);

if isempty(S) || ~isstruct(S) || ~isscalar(S)
    T = table(names, values, 'VariableNames', {'Field','Value'});
    return
end

f = fieldnames(S);
for i = 1:numel(f)
    v    = S.(f{i});
    name = string(prefix) + string(f{i});

    if isstruct(v) && isscalar(v)
        sub    = gui_struct2list(v, char(name + "."));
        names  = [names;  sub.Field];    %#ok<AGROW>
        values = [values; sub.Value];    %#ok<AGROW>
    elseif isstruct(v)
        names(end+1,1)  = name;                                    %#ok<AGROW>
        values(end+1,1) = sprintf("<register: %d entries, %s>", ...
                              numel(v), strjoin(fieldnames(v)', ", "));  %#ok<AGROW>
    else
        names(end+1,1)  = name;                          %#ok<AGROW>
        values(end+1,1) = gui_textify(v);                 %#ok<AGROW>
    end
end

T = table(names, values, 'VariableNames', {'Field','Value'});
end
