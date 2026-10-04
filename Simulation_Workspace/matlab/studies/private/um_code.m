function um_code(fid, txt)
%UM_CODE  Print a command block exactly as it must be typed.
%
%   The text arrives as an ARGUMENT and is printed through a '%s', so it is never
%   rescanned for format escapes: a percent sign in a MATLAB comment inside TXT
%   must be written once, not doubled. Doubling it reaches the page doubled.
fprintf(fid, '<pre class="code">%s</pre>\n', um_esc(txt));
end
