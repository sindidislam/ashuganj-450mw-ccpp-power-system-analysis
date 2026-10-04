function counts=phase6_color_wires(mdl)
%PHASE6_COLOR_WIRES Restore voltage/control colors without changing topology.
% R2024a hilite_system documents these five custom highlighting schemes and
% implements them by setting HiliteAncestors on each object. Set that same
% property directly here so loading a model does not open every subsystem.
% Highlight styles are session data, so style_phase6_model adds a reload hook.
if nargin<1,mdl=bdroot;end
mdl=char(mdl);
colors={'blue','red','darkGreen','magenta','gray'};
schemes={'user1','user2','user3','user4','user5'};
styles=struct('HiliteType',schemes,'ForegroundColor',colors, ...
 'BackgroundColor',repmat({'white'},1,5));
set_param(0,'HiliteAncestorsData',styles);
counts=zeros(1,5);
domains={'Generator',1;'Transformer',1;'Switchyard',2;'Transmission Line',2; ...
 'Grid',2;'Auxiliaries',3;'DC Supply',4;'Measurements',5;'Results',5; ...
 'Turbine and AVR',5;'Protection',5;'Breaker Control',5;'Live Meter Signals',5};
for k=1:size(domains,1)
 path=[mdl '/' domains{k,1}];
 if getSimulinkBlockHandle(path)<0,continue;end
 lines=find_system(path,'FindAll','on','LookUnderMasks','all','Type','line');
 for h=reshape(lines,1,[])
  ports=[get_param(h,'SrcPortHandle');reshape(get_param(h,'DstPortHandle'),[],1)];ports=ports(ports>0);
  signal=false;
  for port=reshape(ports,1,[])
   signal=signal||ismember(lower(get_param(port,'PortType')),{'inport','outport'});
  end
  if signal,set_param(h,'HiliteAncestors',schemes{5});else,set_param(h,'HiliteAncestors',schemes{domains{k,2}});end
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
 % SPS leaf branches have no source/destination handle; their peer list is
 % carried by another member of the undirected connection graph.
 for candidate=reshape(lines,1,[])
  peers=get_param(candidate,'LineChildren');
  if ismember(h,peers),rootLine=candidate;break;end
 end
 for segment=unique([rootLine h])
  source=get_param(segment,'SrcBlockHandle');destination=get_param(segment,'DstBlockHandle');
  blocks=[blocks;source(:);destination(:)]; %#ok<AGROW>
 end
 names=cell(1,0);
 for b=reshape(unique(blocks(blocks>0)),1,[])
  names{end+1}=get_param(b,'Name'); %#ok<AGROW>
 end
 domain=5;
 if any(ismember(names,{'Live Meter Signals'}))
  domain=5;
 elseif any(ismember(names,{'GCB command'}))
  domain=5;
 elseif any(ismember(names,{'Switchyard','Transmission Line','Grid'}))
  domain=2;
 elseif any(ismember(names,{'Generator','Generator Breaker','Transformer','B01 Generator 22 kV bus','B02 Unit 22 kV bus'}))
  domain=1;
 elseif any(ismember(names,{'Auxiliaries'}))
  domain=3;
 end
 set_param(h,'HiliteAncestors',schemes{domain});
 counts(domain)=counts(domain)+1;
end
% Mixed-voltage subsystems need terminal-specific coloring.
paint([mdl '/Transformer/LV CT'],'LConn','user1');paint([mdl '/Transformer/LV CT'],'RConn','user1');
paint([mdl '/Transformer/HV CT'],'LConn','user2');paint([mdl '/Transformer/HV CT'],'RConn','user2');
paint([mdl '/Auxiliaries/UAT 10BBT10'],'LConn','user1');
paint([mdl '/Auxiliaries/GAT incomer'],'LConn','user2');paint([mdl '/Auxiliaries/GAT incomer'],'RConn','user2');
% Highlighting a child line can tint ancestor subsystem icons. Keep each
% equipment icon's own persistent voltage color while retaining wire colors.
blocks=find_system(mdl,'SearchDepth',1,'Type','block');
for k=1:numel(blocks),set_param(blocks{k},'HiliteAncestors','none');end
palette={'Generator','blue';'Generator Breaker','blue';'Transformer','blue'; ...
 'Switchyard','red';'Transmission Line','red';'Grid','red';'Auxiliaries','darkGreen';'DC Supply','magenta'};
for k=1:size(palette,1)
 path=[mdl '/' palette{k,1}];if getSimulinkBlockHandle(path)>0,set_param(path,'ForegroundColor',palette{k,2});end
end
end

function paint(path,side,scheme)
if getSimulinkBlockHandle(path)<0,return;end
hp=get_param(path,'PortHandles');parent=get_param(path,'Parent');
lines=find_system(parent,'FindAll','on','SearchDepth',1,'Type','line');
for p=reshape(hp.(side),1,[])
 h=get_param(p,'Line');if h<=0,continue;end
 peers=h;
 for candidate=reshape(lines,1,[])
  children=get_param(candidate,'LineChildren');
  if candidate==h||ismember(h,children),peers=unique([peers candidate reshape(children,1,[])]);end
 end
 for line=reshape(peers,1,[]),set_param(line,'HiliteAncestors',scheme);end
end
end
