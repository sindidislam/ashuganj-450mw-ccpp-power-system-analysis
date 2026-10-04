out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
addpath(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
clear phase6_presentation_busbars phase6_color_wires export_all_snapshots;
phase6_presentation_busbars(mdl);
set_param(mdl,'SimulationCommand','update');
phase6_color_wires(mdl);
save_system(mdl,fullfile(p6,[mdl '.slx']));
export_all_snapshots(mdl,out);
