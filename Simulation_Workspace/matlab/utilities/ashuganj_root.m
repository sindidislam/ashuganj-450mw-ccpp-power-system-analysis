function r = ashuganj_root()
%ASHUGANJ_ROOT  Absolute path of the project root directory.
%
%   This file lives in <root>/matlab/utilities/, so the root is three levels
%   up.  Every script derives its paths from here rather than assuming a
%   current working directory, because the project path contains a space and
%   relative paths are fragile.

r = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
