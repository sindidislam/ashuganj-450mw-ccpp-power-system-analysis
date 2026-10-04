function s = gui_textify(v)
%GUI_TEXTIFY  One-line string for any value a register field can hold.
%
%   s = GUI_TEXTIFY(v) returns a scalar string suitable for a uitable cell,
%   whatever v is: char, string, numeric scalar, numeric vector, logical, cell
%   array, or struct.
%
%   WHY EVERYTHING COLLAPSES TO ONE LINE
%   ------------------------------------
%   uitable renders an embedded newline as a box glyph, so the multi-line
%   Reason prose that every assumption file carries would arrive as a row of
%   boxes. Whitespace runs are therefore collapsed. The unflattened text is
%   still available - the Assumptions tab shows it in a uitextarea, which does
%   honour line breaks.
%
%   A nested struct is NAMED, not expanded. Expanding it inline would put one
%   element's sub-fields into a column shared with elements that have none.
%
%   See also GUI_STRUCT2TABLE, GUI_STRUCT2LIST.

if isempty(v)
    s = "";
elseif isstring(v)
    s = strjoin(cellstr(v(:))', " | ");
elseif ischar(v)
    s = string(v);
elseif iscell(v)
    parts = strings(1, numel(v));
    for k = 1:numel(v)
        parts(k) = gui_textify(v{k});
    end
    s = strjoin(parts, " | ");
elseif islogical(v)
    s = strjoin(string(double(v(:)))', " ");
elseif isnumeric(v)
    if isscalar(v)
        s = string(num2str(v, '%.6g'));
    else
        s = "[" + strjoin(string(compose('%.6g', double(v(:))))', " ") + "]";
    end
elseif isstruct(v)
    s = sprintf("<struct: %s>", strjoin(fieldnames(v)', ", "));
else
    s = "<" + string(class(v)) + ">";
end

s = string(regexprep(char(s), '\s+', ' '));
end
