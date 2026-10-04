mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
fprintf('DIAG_LOADED %d\n',bdIsLoaded(mdl));
if bdIsLoaded(mdl)
 bb=find_system(mdl,'LookUnderMasks','all','FollowLinks','off','Type','block','RegExp','on','Name','B0[1-5].*');
 disp(bb);
 p=get_param([mdl '/Generator'],'PortHandles');
 for k=1:3
  ln=get_param(p.RConn(k),'Line');
  fprintf('GEN_LINE %g parent=%g children=%s\n',ln,get_param(ln,'LineParent'),mat2str(get_param(ln,'LineChildren')));
 end
end
fprintf('DIAG_DONE\n');
