function T = gui_struct2table(S)
%GUI_STRUCT2TABLE  Turn any register struct array into a displayable table.
%
%   T = GUI_STRUCT2TABLE(S) accepts a struct array such as D.buses, D.tx or
%   D.gen and returns a table with one row per element and one column per
%   field, suitable for uitable.
%
%   WHY THIS IS NOT struct2table
%   ----------------------------
%   struct2table fails on this dataset. The registers deliberately mix types
%   inside one field - a Status field holds char, an Exclusion_reason field is
%   empty for most elements and a sentence for one, a Cooling field holds a
%   cell array of stage names, and several fields hold vectors. struct2table
%   errors on the non-scalar cases and produces unreadable cell columns for
%   the rest.
%
%   The rule here: a field whose every element is a real numeric or logical
%   SCALAR becomes a numeric column, so uitable can sort it numerically.
%   Everything else becomes a string column, rendered by TEXTIFY below. That
%   keeps the numbers sortable and makes the prose readable, which is what a
%   reader of a register actually needs.
%
%   Empty input returns an empty 0x0 table rather than erroring, because a
%   register can legitimately be empty (D.superseded, once nothing is
%   superseded) and a tab must still draw.
%
%   See also GUI_TAB_EQUIPMENT, GUI_TEXTIFY, GUI_STRUCT2LIST.

if isempty(S) || ~isstruct(S)
    T = table();
    return
end

S = S(:);
f = fieldnames(S);
n = numel(S);
cols = cell(1, numel(f));

for i = 1:numel(f)
    vals = {S.(f{i})};

    isNumScalar = cellfun(@(v) (isnumeric(v) || islogical(v)) && isscalar(v), vals);
    if all(isNumScalar)
        c = zeros(n, 1);
        for k = 1:n
            c(k) = double(vals{k});
        end
        cols{i} = c;
    else
        c = strings(n, 1);
        for k = 1:n
            c(k) = gui_textify(vals{k});
        end
        cols{i} = c;
    end
end

% Field names such as 'P_load_alloc_MW' are already valid MATLAB names because
% they are struct fields, so no renaming happens and the column headings match
% the register exactly. VariableNames is set explicitly for that reason.
T = table(cols{:}, 'VariableNames', f);
end
