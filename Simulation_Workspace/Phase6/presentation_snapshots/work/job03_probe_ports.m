mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
path=[mdl '/B01 Generator 22 kV bus'];
bb=find_system(path,'SearchDepth',1,'Type','block');
for k=2:numel(bb)
 fprintf('BUS_PORT %s %s %s\n',bb{k},get_param(bb{k},'Port'),get_param(bb{k},'Side'));
end
disp(get_param(path,'PortHandles'));
fprintf('PORT_INITDONE\n');
