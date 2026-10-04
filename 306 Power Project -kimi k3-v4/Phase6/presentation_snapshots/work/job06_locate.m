mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
fprintf('LOCATE_BEFORE_HELPER\n');
clear phase6_presentation_busbars;
try,phase6_presentation_busbars(mdl);
catch err
 fprintf('LOCATE_ERROR %s\n',err.message);disp(err.stack);rethrow(err);
end
fprintf('LOCATE_AFTER_HELPER\n');
