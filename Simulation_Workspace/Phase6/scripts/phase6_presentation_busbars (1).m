function phase6_presentation_busbars(mdl)
%PHASE6_PRESENTATION_BUSBARS Explicit ideal buses at existing electrical nodes.
% Each AC bar is three separate ideal phase conductors. No phases are joined.
% Reapplication is idempotent; no equipment rating or relay setting is changed.
mdl=char(mdl);
insert(mdl,'B01 Generator 22 kV bus',[mdl '/Generator'],'RConn', ...
 [415 745 660 780],'up','blue','B01 | GENERATOR 22 kV');
insert(mdl,'B02 Unit 22 kV bus',[mdl '/Generator Breaker'],'RConn', ...
 [395 565 705 605],'up','blue','B02 | UNIT BUS 22 kV');
insert([mdl '/Switchyard'],'B03 GIS 230 kV bus',[mdl '/Switchyard/Bus incoming CT'],'RConn', ...
 [350 275 525 315],'down','red','B03 | GIS 230 kV');
insert([mdl '/Grid'],'B04 PGCB 230 kV bus',[mdl '/Grid/Grid CT and VT'],'LConn', ...
 [65 140 100 265],'right','red','B04');
insert([mdl '/Auxiliaries'],'B05 Auxiliary 6.6 kV bus',[mdl '/Auxiliaries/UAT 10BBT10'],'RConn', ...
 [165 325 340 360],'down','darkGreen','B05 | BUS 6.6 kV');
shortRoute([mdl '/Generator'],'RConn');
shortRoute([mdl '/B01 Generator 22 kV bus'],'RConn');
shortRoute([mdl '/Generator Breaker'],'RConn');

set_param([mdl '/Switchyard'],'ForegroundColor','red');
set_param([mdl '/Transmission Line'],'ForegroundColor','red');
set_param([mdl '/Grid'],'ForegroundColor','red');
set_param([mdl '/Generator'],'ForegroundColor','blue');
set_param([mdl '/Generator Breaker'],'ForegroundColor','blue');
set_param([mdl '/Transformer'],'ForegroundColor','blue');
set_param([mdl '/Auxiliaries'],'ForegroundColor','darkGreen');
set_param([mdl '/DC Supply'],'ForegroundColor','magenta');
set_param([mdl '/Protection'],'ForegroundColor','black');
set_param([mdl '/Breaker Control'],'ForegroundColor','black');
set_param([mdl '/Switchyard'],'MaskDisplay', ...
 'color(''red'');patch([.05 .95 .95 .05],[.62 .62 .72 .72],[1 0 0]);text(.5,.35,''B03 | 230 kV GIS BUS'',''horizontalAlignment'',''center'');');
set_param([mdl '/Auxiliaries'],'MaskDisplay', ...
 'text(.5,.83,''UAT / GAT'',''horizontalAlignment'',''center'');color(''darkGreen'');patch([.05 .95 .95 .05],[.51 .51 .60 .60],[0 .5 0]);text(.5,.32,''B05 | 6.6 kV BUS'',''horizontalAlignment'',''center'');text(.5,.10,''14 MW'',''horizontalAlignment'',''center'');');
set_param([mdl '/DC Supply'],'MaskDisplay', ...
 'color(''magenta'');patch([.05 .95 .95 .05],[.68 .68 .78 .78],[.65 0 .65]);text(.5,.45,''B06 | 110 V DC BUS'',''horizontalAlignment'',''center'');text(.5,.16,''Battery / Charger'',''horizontalAlignment'',''center'');');
set_param([mdl '/Grid'],'MaskDisplay', ...
 'color(''red'');patch([.05 .95 .95 .05],[.65 .65 .75 .75],[1 0 0]);text(.5,.40,''B04 | 230 kV PGCB'',''horizontalAlignment'',''center'');text(.5,.15,''Grid equivalent'',''horizontalAlignment'',''center'');');

% Voltage labels on apparatus supplement color and persist in printed exports.
styleElectrical([mdl '/Generator'],'blue');
styleElectrical([mdl '/Switchyard'],'red');
styleElectrical([mdl '/Transmission Line'],'red');
styleElectrical([mdl '/Grid'],'red');
styleElectrical([mdl '/Auxiliaries'],'darkGreen');
set_param([mdl '/Auxiliaries/UAT 10BBT10'],'ForegroundColor','blue');
set_param([mdl '/Auxiliaries/GAT 10BBT20'],'ForegroundColor','red');
set_param([mdl '/Auxiliaries/GAT incomer'],'ForegroundColor','red');
set_param([mdl '/Transformer/GSUT 10BAT10'],'ForegroundColor','blue');
set_param([mdl '/Transformer/LV CT'],'ForegroundColor','blue');
set_param([mdl '/Transformer/HV CT'],'ForegroundColor','red');
set_param([mdl '/DC Supply/Battery charger and DC bus'],'ForegroundColor','magenta', ...
 'BackgroundColor','[1 .94 1]');

% A left-hand connection index identifies buses visible inside subsystem masks.
notes={ ...
 'BUS CONNECTIONS',[45 300],14,'black'; ...
 sprintf('B03 | 230 kV GIS\nGSUT via Q0\nLine circuits + GAT'),[45 340],11,'red'; ...
 sprintf('B04 | 230 kV PGCB\nRemote line + grid'),[45 440],11,'red'; ...
 sprintf('B02 | 22 kV UNIT\nGenerator via 52G\nGSUT + UAT'),[45 530],11,'blue'; ...
 sprintf('B01 | 22 kV GENERATOR\nGenerator + 52G'),[45 750],11,'blue'; ...
 sprintf('B05 | 6.6 kV AUXILIARY\nUAT + standby GAT\nAuxiliary load groups'),[45 835],11,'darkGreen'; ...
 sprintf('B06 | 110 V DC\nCharger + battery\nControl / trip loads'),[45 935],11,'magenta'};
for k=1:size(notes,1),putNote(mdl,['P6Presentation_' num2str(k)],notes{k,1},notes{k,2},notes{k,3},notes{k,4});end
putNote([mdl '/DC Supply'],'P6Presentation_DCBus', ...
 sprintf('B06 | 110 V DC BUS\nComputed inside Battery charger and DC bus\nCharger + battery -> control / trip load'),[690 380],11,'magenta');
putNote([mdl '/Auxiliaries'],'P6Presentation_AuxBus', ...
 'B05: 6.6 kV switchboard equivalent | Transformer secondaries: 6.9 kV',[85 785],11,'darkGreen');
putNote([mdl '/Grid'],'P6Presentation_GridBus','B04 | 230 kV receiving bus',[65 300],11,'red');
aa=find_system(mdl,'FindAll','on','SearchDepth',1,'Type','annotation');
for h=reshape(aa,1,[])
 a=get_param(h,'Object');
 if contains(a.Text,'Color key')
  a.Text='BUS COLORS: red 230 kV | blue 22 kV | green 6.6 kV | purple 110 V DC';
  a.Position=[410 1190];a.FontSize=12;
 end
end
phase6_color_wires(mdl);
set_param(mdl,'ZoomFactor','FitSystem');
end

function insert(parent,name,anchor,side,position,orientation,color,label)
path=[parent '/' name];
rgb='[0 0 1]';if strcmp(color,'red'),rgb='[1 0 0]';elseif strcmp(color,'darkGreen'),rgb='[0 .5 0]';end
if position(4)-position(2)>position(3)-position(1)
 drawing=sprintf('color(''%s'');patch([.35 .65 .65 .35],[.12 .12 .93 .93],%s);text(.5,.04,''%s'',''horizontalAlignment'',''center'');',color,rgb,label);
else
 drawing=sprintf('color(''%s'');patch([.02 .98 .98 .02],[.50 .50 .70 .70],%s);text(.5,.18,''%s'',''horizontalAlignment'',''center'');',color,rgb,label);
end
if getSimulinkBlockHandle(path)>0
 set_param(path,'Position',position,'MaskDisplay',drawing);return;
end
ph=get_param(anchor,'PortHandles');anchorPorts=ph.(side);anchorPorts=anchorPorts(1:3);
endpoints=cell(1,3);roots=zeros(1,3);
for k=1:3
 root=get_param(anchorPorts(k),'Line');
 assert(root>0,'Phase6:MissingBusNet','Missing phase %d at %s',k,anchor);
 while get_param(root,'LineParent')>0,root=get_param(root,'LineParent');end
 roots(k)=root;endpoints{k}=allEndpoints(root);
 assert(ismember(anchorPorts(k),endpoints{k})&&numel(endpoints{k})>=2,'Phase6:BusNet','Invalid bus net.');
end
assert(numel(unique(roots))==3,'Phase6:BusPhases','Phase nets must be separate.');
add_block('built-in/Subsystem',path,'Position',position,'Orientation',orientation);
for q=1:2
 for k=1:3
  n=[path '/' char(64+k) sprintf('%d',q)];
  add_block('built-in/PMIOPort',n,'Port',num2str(k+3*(q-1)), ...
   'Side',pick(q==1,'Left','Right'),'Position',[40+190*(q-1) 40+60*k 60+190*(q-1) 60+60*k]);
 end
end
% PMIO port reordering may migrate side attributes while ports are created.
% Assign the final sides only after all six sequential port numbers exist.
for k=1:3
 set_param([path '/' char(64+k) '1'],'Side','Left');
 set_param([path '/' char(64+k) '2'],'Side','Right');
 p1=get_param([path '/' char(64+k) '1'],'PortHandles');
 p2=get_param([path '/' char(64+k) '2'],'PortHandles');
 add_line(path,[p1.LConn p1.RConn],[p2.LConn p2.RConn],'autorouting','on');
end
set_param(path,'Mask','on','MaskDisplay',drawing, ...
 'MaskIconUnits','normalized','MaskIconOpaque','opaque','MaskIconRotate','off', ...
 'ForegroundColor',color,'BackgroundColor','white','FontSize','10','FontWeight','bold','ShowName','off', ...
 'Description','Presentation busbar: three separate ideal phase conductors inserted at an existing electrical junction.');
bp=get_param(path,'PortHandles');
assert(numel(bp.LConn)==3&&numel(bp.RConn)==3,'Phase6:BusPorts','Expected three ports on each side.');
for k=1:3
 delete_line(roots(k));
 for endpoint=reshape(endpoints{k},1,[])
  remaining=get_param(endpoint,'Line');
  if remaining>0,delete_line(remaining);end
 end
 add_line(parent,anchorPorts(k),bp.LConn(k),'autorouting','on');
 rest=endpoints{k}(endpoints{k}~=anchorPorts(k));
 for p=reshape(rest,1,[]),add_line(parent,bp.RConn(k),p,'autorouting','on');end
end
end

function p=allEndpoints(line)
% SPS connection branches may expose reciprocal child references, unlike
% directed Simulink signals. Traverse the connection graph with a visited set.
p=[];pending=line;seen=[];
while ~isempty(pending)
 current=pending(1);pending(1)=[];
 if current<=0||ismember(current,seen),continue;end
 seen(end+1)=current; %#ok<AGROW>
 p=[p;get_param(current,'SrcPortHandle');reshape(get_param(current,'DstPortHandle'),[],1)]; %#ok<AGROW>
 children=get_param(current,'LineChildren');
 pending=[pending reshape(children,1,[])]; %#ok<AGROW>
end
p=unique(p(p>0));
% For SPS junctions the leaf segment's Src/DstPortHandle can both be -1.
% The owning electrical ports still report that segment through their Line.
parent=get_param(line,'Parent');
allLines=find_system(parent,'FindAll','on','SearchDepth',1,'Type','line');
changed=true;
while changed
 previous=numel(seen);
 for candidate=reshape(allLines,1,[])
  adjacent=[candidate;reshape(get_param(candidate,'LineChildren'),[],1)];
  if any(ismember(adjacent,seen)),seen=unique([seen reshape(adjacent,1,[])]);end
 end
 changed=numel(seen)>previous;
end
blocks=find_system(parent,'SearchDepth',1,'Type','block');
for b=1:numel(blocks)
 if strcmp(blocks{b},parent),continue;end
 handles=get_param(blocks{b},'PortHandles');
 for port=reshape([handles.LConn handles.RConn],1,[])
  if ismember(get_param(port,'Line'),seen),p(end+1,1)=port;end %#ok<AGROW>
 end
end
p=unique(p);
end

function styleElectrical(system,color)
bb=find_system(system,'SearchDepth',1,'Type','block');
for k=2:numel(bb)
 hp=get_param(bb{k},'PortHandles');
 if ~isempty(hp.LConn)||~isempty(hp.RConn),set_param(bb{k},'ForegroundColor',color);end
end
end

function putNote(system,tag,text,pos,size,color)
aa=find_system(system,'FindAll','on','SearchDepth',1,'Type','annotation');found=[];
for h=reshape(aa,1,[]),if strcmp(get_param(h,'Tag'),tag),found=h;break;end,end
if isempty(found),a=Simulink.Annotation(system,text);a.Tag=tag;else,a=get_param(found,'Object');a.Text=text;end
a.Position=pos;a.FontSize=size;a.ForegroundColor=color;
end
function s=pick(tf,a,b),if tf,s=a;else,s=b;end,end

function shortRoute(block,side)
ports=get_param(block,'PortHandles');
for p=reshape(ports.(side),1,[])
 line=get_param(p,'Line');ends=allEndpoints(line);
 if numel(ends)~=2,continue;end
 start=get_param(line,'SrcPortHandle');finish=get_param(line,'DstPortHandle');
 if start<=0||numel(finish)~=1||finish<=0,continue;end
 a=get_param(start,'Position');b=get_param(finish,'Position');y=round((a(2)+b(2))/2);
 points=unique([a;a(1) y;b(1) y;b],'rows','stable');
 set_param(line,'Points',points);
end
end
