out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
clear phase6_color_wires export_all_snapshots;
phase6_color_wires(mdl);save_system(mdl,fullfile(p6,[mdl '.slx']));
export_all_snapshots(mdl,out);
