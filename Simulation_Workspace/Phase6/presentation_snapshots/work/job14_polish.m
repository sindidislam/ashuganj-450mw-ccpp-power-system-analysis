out=fileparts(fileparts(mfilename('fullpath')));p6=fileparts(out);
mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
clear phase6_color_wires phase6_presentation_busbars;
phase6_presentation_busbars(mdl);phase6_color_wires(mdl);
save_system(mdl,fullfile(p6,[mdl '.slx']));
print(['-s' mdl],'-dpng','-r160',fullfile(out,'raw','000_Plant_overview.png'));
fprintf('FINAL_OVERVIEW_POLISHED\n');
