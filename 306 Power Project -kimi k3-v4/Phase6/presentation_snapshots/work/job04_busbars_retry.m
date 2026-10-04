out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
close_system(mdl,0);load_system(fullfile(p6,[mdl '.slx']));
run(fullfile(out,'work','job02_busbars.m'));
