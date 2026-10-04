% Continue in the visible MATLAB desktop; preserve original Phase 1-5 data.
p6root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(p6root,'scripts'),fullfile(p6root,'scripts','tests'));
p6log=fullfile(p6root,'logs','resume_20260924');
diary(fullfile(p6log,'desktop.log'));
try
    test_phase6_dc_recovery;
catch err
    fprintf('DC_REGRESSION_RED %s: %s\n',err.identifier,err.message);
end
run(fullfile(p6root,'START_PHASE6.m'));
mdl='PHASE6_ASHUGANJ_CCPP_DYNAMIC_MODEL';
assert(startsWith(get_param(mdl,'FileName'),p6root));
copyfile(get_param(mdl,'FileName'),fullfile(p6log,'model_before_presentation.slx'));
clear style_phase6_model phase6_color_wires;
style_phase6_model(mdl);
set_param(mdl,'SimulationCommand','update');
save_system(mdl);
print(['-s' mdl],'-dpng','-r120',fullfile(p6log,'model.png'));
fprintf('PRESENTATION_UPDATE_PASS\n');
diary off;
