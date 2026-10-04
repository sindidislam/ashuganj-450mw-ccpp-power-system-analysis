% Open the interactive Ashuganj South model from this project folder.
phase6StartRoot=fileparts(mfilename('fullpath'));
addpath(fullfile(phase6StartRoot,'scripts'));
setup_phase6_workspace();
phase6StartFile=fullfile(phase6StartRoot,'model','PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx');
if ~isfile(phase6StartFile)
    build_phase6_model();
end
load_system(phase6StartFile);
phase6StartModel='PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';
open_system(phase6StartModel);
set_param(phase6StartModel,'ZoomFactor','FitSystem');
if exist('phase6_interactive_settings','file')==2
    phase6_interactive_settings(phase6StartModel);
end
clear phase6StartRoot phase6StartFile phase6StartModel;
