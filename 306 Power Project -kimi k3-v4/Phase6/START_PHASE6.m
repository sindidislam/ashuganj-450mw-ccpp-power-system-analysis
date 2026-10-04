% Open the interactive Ashuganj South model from this project folder.
phase6StartRoot=fileparts(mfilename('fullpath'));
addpath(fullfile(phase6StartRoot,'scripts'));
addpath(fullfile(fileparts(phase6StartRoot),'matlab','phase6'));
setup_phase6_workspace();
phase6StartFile=fullfile(phase6StartRoot,'PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx');
if ~isfile(phase6StartFile)
    build_dynamic_protection_sim();
end
load_system(phase6StartFile);
phase6StartModel='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
assert(strcmpi(char(java.io.File(get_param(phase6StartModel,'FileName')).getCanonicalPath()), ...
    char(java.io.File(phase6StartFile).getCanonicalPath())), ...
    'Phase6:WrongProject','Close the same-name model from another folder, then run START_PHASE6 again.');
phase6StartContext=phase6_interactive_settings(phase6StartModel,'get');
assert(strcmp(phase6StartContext.info.model,phase6StartModel),'Phase6:RebuildRequired', ...
    'Run build_dynamic_protection_sim once to replace the old copied placeholder model.');
open_system(phase6StartModel);
set_param(phase6StartModel,'ZoomFactor','FitSystem');
if exist('phase6_interactive_settings','file')==2
    phase6_interactive_settings(phase6StartModel);
end
clear phase6StartRoot phase6StartFile phase6StartModel phase6StartContext;
