function counts=phase6_color_wires(mdl)
%PHASE6_COLOR_WIRES Restore voltage/control colors without changing topology.
% R2024a hilite_system documents these five custom highlighting schemes and
% implements them by setting HiliteAncestors on each object. Set that same
% property directly here so loading a model does not open every subsystem.
% Highlight styles are session data, so style_phase6_model adds a reload hook.
if nargin<1,mdl=bdroot;end
mdl=char(mdl);
colors={'orange','blue','magenta','darkGreen','red'};
schemes={'user1','user2','user3','user4','user5'};
styles=struct('HiliteType',schemes,'ForegroundColor',colors, ...
 'BackgroundColor',repmat({'white'},1,5));
set_param(0,'HiliteAncestorsData',styles);
counts=zeros(1,5);
domains={'Generator',1;'Transformer',1;'Switchyard',2;'Transmission Line',2; ...
 'Grid',2;'Auxiliaries',3;'DC Supply',3;'Measurements',4;'Results',4; ...
 'Turbine and AVR',4;'Protection',5;'Breaker Control',5;'Live Meter Signals',4};
for k=1:size(domains,1)
 path=[mdl '/' domains{k,1}];
 if getSimulinkBlockHandle(path)<0,continue;end
 lines=find_system(path,'FindAll','on','LookUnderMasks','all','Type','line');
 for h=reshape(lines,1,[])
  set_param(h,'HiliteAncestors',schemes{domains{k,2}});
 end
 counts(domains{k,2})=counts(domains{k,2})+numel(lines);
end
lines=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','line');
for h=reshape(lines,1,[])
 % Branch segments may have no source. Follow the parent line and use
 % exact equipment names, so a "Generator MW" meter is never treated as AC.
 rootLine=h;parent=get_param(rootLine,'LineParent');
 while parent>0&&parent~=rootLine
  rootLine=parent;parent=get_param(rootLine,'LineParent');
 end
 blocks=[];
 for segment=unique([rootLine h])
  source=get_param(segment,'SrcBlockHandle');destination=get_param(segment,'DstBlockHandle');
  blocks=[blocks;source(:);destination(:)]; %#ok<AGROW>
 end
 names=cell(1,0);
 for b=reshape(unique(blocks(blocks>0)),1,[])
  names{end+1}=get_param(b,'Name'); %#ok<AGROW>
 end
 domain=4;
 if any(ismember(names,{'Live Meter Signals'}))
  domain=4;
 elseif any(ismember(names,{'GCB command'}))
  domain=5;
 elseif any(ismember(names,{'Switchyard','Transmission Line','Grid'}))
  domain=2;
 elseif any(ismember(names,{'Generator','Generator Breaker','Transformer'}))
  domain=1;
 elseif any(ismember(names,{'Auxiliaries'}))
  domain=3;
 end
 set_param(h,'HiliteAncestors',schemes{domain});
 counts(domain)=counts(domain)+1;
end
end
