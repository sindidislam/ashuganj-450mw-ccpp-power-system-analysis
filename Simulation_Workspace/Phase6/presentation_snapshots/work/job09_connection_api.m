mdl='PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP';
hp=get_param([mdl '/Generator Breaker'],'PortHandles');ln=get_param(hp.RConn(1),'Line');
fprintf('ANCHOR %g LINE %g\n',hp.RConn(1),ln);
disp(get_param(ln,'ObjectParameters'));
ll=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','line');
for h=reshape(ll,1,[])
 fprintf('NETLINE %g parent=%s children=%s src=%s dst=%s\n',h,mat2str(get_param(h,'LineParent')),mat2str(get_param(h,'LineChildren')),mat2str(get_param(h,'SrcPortHandle')),mat2str(get_param(h,'DstPortHandle')));
end
for name={'Generator Breaker','Transformer','Auxiliaries'}
 hp=get_param([mdl '/' name{1}],'PortHandles');
 for h=reshape([hp.LConn hp.RConn],1,[]),fprintf('ENDPOINT %s %g line=%g\n',name{1},h,get_param(h,'Line'));end
end
