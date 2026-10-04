function paths=phase6_trip_paths(outDir,root)
%PHASE6_TRIP_PATHS Resolve this v4 installation and protect evidence paths.
owner=fileparts(fileparts(fileparts(mfilename('fullpath'))));
if nargin<2||isempty(root),root=owner;end
assert((ischar(root)&&isrow(root))||(isstring(root)&&isscalar(root)), ...
    'Phase6:Root','root must be a scalar project path.');
root=char(java.io.File(char(root)).getCanonicalPath());
assert(strcmpi(root,char(java.io.File(owner).getCanonicalPath())), ...
    'Phase6:Root','Use the project root containing this function: %s',owner);
phase6=fullfile(root,'Phase6');base=char(java.io.File(fullfile(phase6,'results')).getCanonicalPath());
if nargin<1||isempty(outDir),outDir=fullfile(base,'closed_loop_trip');end
assert((ischar(outDir)&&isrow(outDir))||(isstring(outDir)&&isscalar(outDir)), ...
    'Phase6:Output','outDir must be a scalar path inside Phase6/results.');
outDir=char(java.io.File(char(outDir)).getCanonicalPath());
assert(startsWith(lower(outDir),[lower(base) filesep]), ...
    'Phase6:UnsafeOutput','Choose a result subfolder inside %s.',base);
addpath(fullfile(phase6,'scripts'));
setup_phase6_workspace();
paths=struct('project',root,'phase6',phase6,'output',outDir, ...
    'model','PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP', ...
    'file',fullfile(phase6,'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx'));
end
