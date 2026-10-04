function test_phase6_build()
% End-to-end contract for the isolated model builder.
here = fileparts(mfilename('fullpath'));
phase6 = fileparts(fileparts(here));
addpath(fullfile(phase6,'scripts'));
out = fullfile(phase6,'model','PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL.slx');
assert(~exist(out,'file') || startsWith(out,phase6));
info = build_phase6_model('SavePath',out,'Close',true);
assert(exist(out,'file') == 2);
assert(strcmp(info.model,'PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL'));
load_system(out);
mdl = info.model;
assert(~isempty(find_system(mdl,'LookUnderMasks','all','MaskType','Synchronous Machine')));
assert(~isempty(find_system(mdl,'LookUnderMasks','all','MaskType','Three-Phase Fault')));
assert(~isempty(find_system(mdl,'LookUnderMasks','all','MaskType','Three-Phase Breaker')));
assert(numel(find_system(mdl,'LookUnderMasks','all','MaskType','PSB option menu block')) == 1);
set_param(mdl,'SimulationCommand','update');
close_system(mdl,0);
end
