function s = um_esc(s)
%UM_ESC  HTML-escape text taken from a file or a dataset field.
%   Ampersand first, or the replacements escape each other.
s = strrep(s, '&', '&amp;');
s = strrep(s, '<', '&lt;');
s = strrep(s, '>', '&gt;');
end
