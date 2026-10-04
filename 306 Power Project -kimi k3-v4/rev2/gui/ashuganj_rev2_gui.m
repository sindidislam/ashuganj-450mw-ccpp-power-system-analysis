function fig = ashuganj_rev2_gui(varargin)
%ASHUGANJ_REV2_GUI Rev2 project GUI (Sep-10 master truth).
% Tabs: Overview | Load Flow | Fault Analysis | Protection | Results |
%       Documents | Model | Tests | Animation.
% Usage: ashuganj_rev2_gui()  (run from rev2/ with data+tests on path, or
%   standalone - paths resolve from this file's location).
% Headless check: ashuganj_rev2_gui('Visible','off') returns fig for tests.
p=inputParser; addParameter(p,'Visible','on'); parse(p,varargin{:});
here=fileparts(mfilename('fullpath'));
root=fileparts(here);                    % rev2/
proj=fileparts(root);                    % project root
addpath(fullfile(root,'data')); addpath(fullfile(root,'tests')); addpath(fullfile(root,'simulink'));

fig=uifigure('Name','Ashuganj South 450MW CCPP - Rev2 (EEE 306 G03)','Visible',p.Results.Visible, ...
  'Position',[60 40 1180 720]);
fig.UserData=struct('root',root,'proj',proj,'here',here);
tg=uitabgroup(fig,'Position',[10 10 1160 670]);

mkTab=@(t) uitab(tg,'Title',t);
tabOverview=mkTab('Overview'); tabLF=mkTab('Load Flow'); tabFault=mkTab('Fault Analysis');
tabProt=mkTab('Protection'); tabRes=mkTab('Results'); tabDoc=mkTab('Documents');
tabModel=mkTab('Model'); tabTest=mkTab('Tests'); tabAnim=mkTab('Animation');

buildOverview(tabOverview,fig);
buildLF(tabLF,fig);
buildFault(tabFault,fig);
buildProt(tabProt,fig);
buildResults(tabRes,fig);
buildDocs(tabDoc,fig);
buildModel(tabModel,fig);
buildTests(tabTest,fig);
buildAnim(tabAnim,fig);
end

function R=paths(fig)
R=fig.UserData;
end

function T=readcsv(fig,sub,name)
T=readtable(fullfile(paths(fig).root,sub,name),'FileType','text');
end

%% ---------------- Overview ----------------
function buildOverview(tab,fig)
g=uigridlayout(tab,[4 2]); g.RowHeight={'fit','fit','fit','1x'}; g.ColumnWidth={'1x','1x'};
gl(uilabel(g,'Text','Ashuganj South 450MW CCPP --- Rev2 final (Sep-10 master truth, 100MVA/50Hz)', ...
  'FontSize',15,'FontWeight','bold'),1,[1 2]);
gl(uilabel(g,'Text',['Phase 1 load flow [x] - Phase 2 faults + Simulink [x] - Phase 3 protection [x] - ' ...
  'Phase 4 report [x] | run_full_project(''All'') reproduces everything.']),2,[1 2]);
tx=gl(uitextarea(g,'Editable','off'),3,[1 2]);
tx.Value={ ...
  'P1A base: 354MW gross -> 340.91MW export (354-12-1.09), V_B02 1.0004, V_B11 0.9328 LOW, GSUT 96.45% ONAN.'; ...
  'Worst faults: B01 122.36kA (22kV) | B02/B03 46-48kA (matches PGCB-2019 45.01kA).'; ...
  'Breakers vs 50kA: ALL PASS, Q1/Q2 margin only +1.94kA. Strong-grid sens: 64.4kA EXCEEDS rating (F8).'; ...
  'Protection: 5/5 grading margins >=0.300s; GSUT-HV sensitivity thin at 2.15x (87B covers).'; ...
  'Simulink V2 cross-check: grid-share RMS +0.2..+5.5% (6/6 simmed cases).'};
tbl=gl(uitable(g,'ColumnName',{'File','Purpose'}),4,[1 2]);
tbl.Data={ ...
  'results/phase1_system_summary.csv','Load-flow cases'; ...
  'results/phase2_fault_currents.csv','9 faults + 36 sens rows'; ...
  'results/phase2_breaker_duty.csv','Breaker duty vs 50kA'; ...
  'results/phase2_simulink_check.csv','Simulink cross-check'; ...
  'results/phase3_settings.csv','Relay settings'; ...
  'results/phase3_coordination.csv','Grading margins'; ...
  'reports/Rev2_Final_Report.md','Final report (F1-F8)'; ...
  'reports/DEMO_GUIDE.md','Viva walkthrough'; ...
  'simulink/studies/Load_Flow_V2.slx','Simulink model (clone of Load_Flow)'};
end

%% ---------------- Load Flow ----------------
function buildLF(tab,fig)
g=uigridlayout(tab,[3 3]); g.RowHeight={'fit','1x','fit'}; g.ColumnWidth={220,'1x',300};
gl(uilabel(g,'Text','Case:'),1,1);
dd=gl(uidropdown(g,'Items',{'P1A','P1B','P1C','P1D','P1E','P1F','P1G'}),1,2);
btn=gl(uibutton(g,'Text','Reload table'),1,3);
tbl=gl(uitable(g),2,[1 3]);
img=gl(uiimage(g),3,[1 3]);
img.ImageSource=fullfile(paths(fig).root,'plots','phase1_bus_voltage.png');
img.ScaleMethod='fit';
refresh=@() lfRefresh(fig,tbl,dd.Value);
set(btn,'ButtonPushedFcn',@(~,~) refresh());
refresh();
fig.UserData.lfRefresh=refresh;
end

function lfRefresh(fig,tbl,caseid)
T=readcsv(fig,'results','phase1_system_summary.csv');
r=find(strcmp(T.CaseID,caseid),1);
v=T.Properties.VariableNames;
tbl.ColumnName=v; tbl.Data=table2cell(T(r,:));
end

%% ---------------- Fault Analysis ----------------
function buildFault(tab,fig)
g=uigridlayout(tab,[4 3]); g.RowHeight={'fit','fit','1x','fit'}; g.ColumnWidth={220,'1x',300};
gl(uilabel(g,'Text','Fault case:'),1,1);
cases={'F1-B01-LLL','F2-B01-LG','F3-B01-LL','F4-B01-LLG','F5-B02-LLL','F6-B02-LG','F7-B02-LL','F8-B02-LLG','F9-B03-LLL'};
dd=gl(uidropdown(g,'Items',cases),1,2);
bShow=gl(uibutton(g,'Text','Show engine row'),1,3);
gl(uilabel(g,'Text','Simulink single-case run (B01/B02, ~2-3 min):'),2,1);
bRun=gl(uibutton(g,'Text','RUN selected in Simulink','FontWeight','bold'),2,2);
st=gl(uilabel(g,'Text','idle'),2,3);
tbl=gl(uitable(g),3,[1 3]);
ax=gl(uiaxes(g),4,[1 3]); ax.Visible='off';
set(bShow,'ButtonPushedFcn',@(~,~) faultShow(fig,tbl,dd.Value));
set(bRun,'ButtonPushedFcn',@(~,~) faultRun(fig,tbl,ax,st,dd.Value));
faultShow(fig,tbl,dd.Value);
end

function faultShow(fig,tbl,caseid)
T=readcsv(fig,'results','phase2_fault_currents.csv');
r=find(strcmp(T.CaseID,caseid),1);
v={'CaseID','Bus','FaultType','Isym_kA','Ipeak_kA','XR_pos','FaultMVA','Igen_kA_22kV','Igrid_kA_230kV','Vfault_min_pu','Note_StatusC'};
tbl.ColumnName=v; tbl.Data=table2cell(T(r,v));
end

function faultRun(fig,tbl,ax,st,caseid)
% Single-case time-domain run on Load_Flow_V2 + waveform plot.
R=paths(fig); mdl='Load_Flow_V2';
bus=caseid(4:6); typ=caseid(8:end);
if strcmp(bus,'B03'), st.Text='B03 engine-only (lumped node)'; return; end
st.Text='running...'; drawnow;
tapTool=fullfile(R.root,'simulink','xml_fault_tap.ps1');
xt=@(a,b) system(sprintf('powershell -ExecutionPolicy Bypass -File "%s" -Action %s -Bus %s',tapTool,a,b));
cd(R.root);
load_system(fullfile(R.proj,'simulink','studies',[mdl '.slx']));
set_param(mdl,'StopTime','0.25','SaveTime','on');
blk=[mdl '/F_' bus];
set_param(blk,'SwitchTimes','[0.05]','External','off','FaultResistance','1e-4','GroundResistance','1e-4','Measurements','None');
switch typ
  case 'LLL', set_param(blk,'FaultA','on','FaultB','on','FaultC','on','GroundFault','off');
  case 'LG',  set_param(blk,'FaultA','on','FaultB','off','FaultC','off','GroundFault','on');
  case 'LL',  set_param(blk,'FaultA','off','FaultB','on','FaultC','on','GroundFault','off');
  case 'LLG', set_param(blk,'FaultA','off','FaultB','on','FaultC','on','GroundFault','on');
end
try
  o=sim(mdl,'StopTime','0.25');
  assert(numel(o.tout)>1000,'sim stalled (solver wall: B01-LLL/LL engine-only)');
  Ig=getsig(o,'Igrid'); t=getsigT(o,'Igrid');
  Vb=getsig(o,['Vb' bus(2:3) '_1']);
  ax.Visible='on'; cla(ax);
  plot(ax,t,Ig/1e3); grid(ax,'on'); hold(ax,'on');
  plot(ax,t,Vb/max(abs(Vb))*max(abs(Ig))/1e3,'--');
  xlabel(ax,'s'); ylabel(ax,'kA (Igrid) + V scaled');
  title(ax,sprintf('%s: Igrid + %s voltage (fault at 0.05s)',caseid,bus));
  legend(ax,{'Igrid kA','Vbus scaled'});
  rmsG=max(sqrt(mean(Ig(end-199:end,:).^2,1)))/1e3;
  st.Text=sprintf('done: Igrid RMS %.2fkA',rmsG);
catch ME
  st.Text=['FAILED: ' ME.message(1:min(60,end))];
end
set_param(blk,'FaultA','off','FaultB','off','FaultC','off','GroundFault','off');
save_system(mdl); close_system(mdl,0);
end

function M=getsig(o,name)
S=o.get(name); M=double(squeeze(S.signals.values));
if isvector(M), M=M(:); end
end

function t=getsigT(o,name)
t=o.get(name); t=t.time;
end

%% ---------------- Protection ----------------
function buildProt(tab,fig)
g=uigridlayout(tab,[3 2]); g.RowHeight={'fit','1x','1x'}; g.ColumnWidth={'1x','1x'};
gl(uilabel(g,'Text','Relay settings (pickup 1.2xFL-C, IEC-SI, TMS solved for 0.3s-C):'),1,1);
gl(uilabel(g,'Text','Coordination pairs:'),1,2);
t1=gl(uitable(g),2,1);
T=readcsv(fig,'results','phase3_settings.csv');
t1.ColumnName=T.Properties.VariableNames; t1.Data=table2cell(T);
t1.ColumnWidth={110,70,70,80,70,60,90,90,90,90,70};
t2=gl(uitable(g),2,2);
C=readcsv(fig,'results','phase3_coordination.csv');
t2.ColumnName=C.Properties.VariableNames; t2.Data=table2cell(C);
img=gl(uiimage(g),3,[1 2]);
img.ImageSource=fullfile(paths(fig).root,'plots','phase3_tcc.png');
img.ScaleMethod='fit';
end

%% ---------------- Results ----------------
function buildResults(tab,fig)
g=uigridlayout(tab,[2 2]); g.RowHeight={'fit','1x'}; g.ColumnWidth={300,'1x'};
d=dir(fullfile(paths(fig).root,'results','*.csv'));
items={d.name};
dd=gl(uidropdown(g,'Items',items),1,1);
b=gl(uibutton(g,'Text','Load'),1,2);
tbl=gl(uitable(g),2,[1 2]);
load1=@() resLoad(fig,tbl,dd.Value);
set(b,'ButtonPushedFcn',@(~,~) load1());
set(dd,'ValueChangedFcn',@(~,~) load1());
load1();
end

function resLoad(fig,tbl,name)
T=readcsv(fig,'results',name);
tbl.ColumnName=T.Properties.VariableNames;
D=table2cell(T);
if size(D,1)>200, D=D(1:200,:); end
tbl.Data=D;
end

%% ---------------- Documents ----------------
function buildDocs(tab,fig)
g=uigridlayout(tab,[2 2]); g.RowHeight={'fit','1x'}; g.ColumnWidth={300,'1x'};
items={'reports/Rev2_Final_Report.md','reports/DEMO_GUIDE.md','PROGRESS.md', ...
  'Ashuganj_South_Final_Master_Data_and_Assumptions (1).md', ...
  'results/phase1_registry_snapshot.txt'};
dd=gl(uidropdown(g,'Items',items),1,1);
b=gl(uibutton(g,'Text','Load'),1,2);
tx=gl(uitextarea(g,'Editable','off'),2,[1 2]);
load1=@() docLoad(fig,tx,dd.Value);
set(b,'ButtonPushedFcn',@(~,~) load1());
set(dd,'ValueChangedFcn',@(~,~) load1());
load1();
end

function docLoad(fig,tx,rel)
R=paths(fig);
if startsWith(rel,'reports/')||startsWith(rel,'results/')
  p=fullfile(R.root,rel);
else
  p=fullfile(R.proj,rel);
end
try
  c=fileread(p); L=strsplit(c,newline);
  if numel(L)>400, L=[L(1:400); '... (truncated, open file for full text)']; end
  tx.Value=L(:);
catch ME
  tx.Value={['Cannot read: ' ME.message]};
end
end

%% ---------------- Model ----------------
function buildModel(tab,fig)
g=uigridlayout(tab,[5 2]); g.RowHeight={'fit','fit','fit','fit','1x'}; g.ColumnWidth={'1x','1x'};
gl(uilabel(g,'Text','studies/Load_Flow_V2.slx (clone of Load_Flow.slx; originals untouched)','FontWeight','bold'),1,[1 2]);
b1=gl(uibutton(g,'Text','Open V2 model'),2,1);
b2=gl(uibutton(g,'Text','Open original Load_Flow'),2,2);
b3=gl(uibutton(g,'Text','Rebuild V2 (clone+correct)'),3,1);
b4=gl(uibutton(g,'Text','Format V2 (SLD+captions+DC)'),3,2);
tx=gl(uitextarea(g,'Editable','off'),5,[1 2]);
set(b1,'ButtonPushedFcn',@(~,~) openSys(fig,'Load_Flow_V2'));
set(b2,'ButtonPushedFcn',@(~,~) openSys(fig,'Load_Flow'));
set(b3,'ButtonPushedFcn',@(~,~) modelMsg(fig,tx,'rebuild'));
set(b4,'ButtonPushedFcn',@(~,~) modelMsg(fig,tx,'format'));
gl(uilabel(g,'Text','Rebuild/format run in MATLAB console (they save the .slx).'),4,[1 2]);
modelInfo(fig,tx);
end

function openSys(fig,which)
R=paths(fig);
if strcmp(which,'Load_Flow_V2')
  load_system(fullfile(R.proj,'simulink','studies','Load_Flow_V2.slx'));
else
  load_system(fullfile(R.proj,'simulink','studies','Load_Flow.slx'));
end
open_system(which);
end

function modelInfo(fig,tx)
R=paths(fig);
load_system(fullfile(R.proj,'simulink','studies','Load_Flow_V2.slx'));
bl=find_system('Load_Flow_V2','Type','block');
an=find_system('Load_Flow_V2','FindAll','on','Type','annotation');
tx.Value={sprintf('V2 blocks=%d annotations=%d',numel(bl),numel(an)); ...
  'AC: G1(354MW+SCL) GSUT UAT GAT(open) 3 aux loads ZGRID-lumped VI_GRID 6 VM taps'; ...
  'DC island: BAT_110V 200Ah + R_DCDB 4.03ohm + I_DC + Idc sink (conceptual C)'; ...
  'Fault blocks F_B01/F_B02 present, UNTAPPED in file (runner taps per case).'};
close_system('Load_Flow_V2',0);
end

function modelMsg(fig,tx,what)
if strcmp(what,'rebuild')
  tx.Value={'Run in console:';'cd rev2/simulink';'build_loadflow_v2()'};
else
  tx.Value={'Run in console:';'cd rev2/simulink';'format_loadflow_v2()'};
end
end

%% ---------------- Tests ----------------
function buildTests(tab,fig)
g=uigridlayout(tab,[3 2]); g.RowHeight={'fit','1x','fit'}; g.ColumnWidth={250,'1x'};
gl(uilabel(g,'Text','Select tests:'),1,1);
lst=gl(uilistbox(g,'Items',{'test_rev2_registry','test_phase2_fault','test_phase2_kcl','test_phase3_protection'}, ...
  'Multiselect','on','Value',{'test_rev2_registry'}),2,1);
tx=gl(uitextarea(g,'Editable','off'),2,2);
b=gl(uibutton(g,'Text','RUN SELECTED','FontWeight','bold'),3,1);
res=gl(uilabel(g,'Text','not run'),3,2);
set(b,'ButtonPushedFcn',@(~,~) runTests(fig,tx,res,lst.Value));
end

function runTests(fig,tx,res,items)
R=paths(fig); out={}; np=0;
for k=1:numel(items)
  try
    s=evalc([items{k} '()']);
    L=strsplit(strtrim(s),newline);
    out=[out; {['== ' items{k} ' ==']}; L(:)];
    if ~contains(s,'FAIL')&&~contains(s,'Error'), np=np+1; end
  catch ME
    out=[out; {['== ' items{k} ' CRASHED: ' ME.message]}];
  end
end
tx.Value=out;
if np==numel(items), res.Text=sprintf('ALL %d PASS',np); res.FontColor=[0 0.5 0];
else, res.Text=sprintf('%d/%d pass',np,numel(items)); res.FontColor=[0.8 0 0]; end
end

%% ---------------- Animation ----------------
function buildAnim(tab,fig)
g=uigridlayout(tab,[3 2]); g.RowHeight={'fit','1x','fit'}; g.ColumnWidth={250,'1x'};
gl(uilabel(g,'Text','Fault case:'),1,1);
cases={'F5-B02-LLL','F6-B02-LG','F7-B02-LL','F8-B02-LLG','F9-B03-LLL','F2-B01-LG','F4-B01-LLG'};
dd=gl(uidropdown(g,'Items',cases),2,1);
ax=gl(uiaxes(g),2,2);
b=gl(uibutton(g,'Text','PLAY fault animation','FontWeight','bold'),3,1);
st=gl(uilabel(g,'Text','idle: prefault -> fault@0.05s -> trip@0.11s'),3,2);
set(b,'ButtonPushedFcn',@(~,~) playAnim(fig,ax,st,dd.Value));
drawSLD(ax,[],'');
end

function drawSLD(ax,F,stage)
% Simplified one-line: GEN-B01-GSUT-B02-LINE-B03-GRID + UAT-B11 branch.
cla(ax); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
xlim(ax,[0 10]); ylim(ax,[0 4]);
bus=@(x,y) plot(ax,x,y,'ks','MarkerSize',14,'MarkerFaceColor','k');
lbl=@(x,y,s) text(ax,x,y+0.25,s,'HorizontalAlignment','center','FontSize',9);
% chain y=2
X=[0.5 2 3.5 5.5 7 8.5 9.5]; N={'GEN','B01','GSUT','B02','LINE','B03','GRID'};
Isym=46; Igrid=43;
if ~isempty(F)
  Isym=F.Isym; Igrid=F.Igrid;
end
wG=1+5*min(Igrid/50,1); wS=1+5*min((Isym-Igrid)/50,1);
plot(ax,[X(1) X(2)], [2 2],'b-','LineWidth',2);
plot(ax,[X(2) X(4)], [2 2],'b-','LineWidth',2+wS);
plot(ax,[X(4) X(6)], [2 2],'b-','LineWidth',2+wG);
plot(ax,[X(6) X(7)], [2 2],'b-','LineWidth',2+wG);
for k=[2 4 6], bus(X(k),2); end
for k=1:numel(X), lbl(X(k),2,N{k}); end
% aux branch
plot(ax,[X(2) X(2)],[2 0.8],'b-','LineWidth',1); bus(X(2),0.8); lbl(X(2),0.8,'B11');
% breakers Q0 (gen side) Q9 (line)
q0=rectangle(ax,'Position',[X(3)-0.12 1.85 0.24 0.3],'FaceColor','g','EdgeColor','k');
q9=rectangle(ax,'Position',[X(5)-0.12 1.85 0.24 0.3],'FaceColor','g','EdgeColor','k');
text(ax,X(3),1.6,'Q0','HorizontalAlignment','center'); text(ax,X(5),1.6,'Q9','HorizontalAlignment','center');
% fault marker
fh=plot(ax,NaN,NaN,'r*','MarkerSize',22,'Visible','off');
title(ax,'Ashuganj South one-line (schematic, widths ~ current share)');
ax.UserData=struct('q0',q0,'q9',q9,'fh',fh,'X',X);
end

function playAnim(fig,ax,st,caseid)
T=readcsv(fig,'results','phase2_fault_currents.csv');
r=find(strcmp(T.CaseID,caseid),1);
F=struct('Isym',T.Isym_kA(r),'Igrid',T.Igrid_kA_230kV(r),'bus',T.Bus{r});
drawSLD(ax,F,'');
U=ax.UserData;
fx=U.X(4); if strcmp(F.bus,'B01'), fx=U.X(2); end
if strcmp(F.bus,'B03'), fx=U.X(6); end
set(U.fh,'XData',fx,'YData',2,'Visible','on');
st.Text='FAULT APPLIED (t=0.05s) - Isym RED, widths = shares'; drawnow;
pause(1.2);
set(U.q0,'FaceColor','r'); set(U.q9,'FaceColor','r');
st.Text=sprintf('TRIPPED Q0+Q9 (t=0.11s, 60ms C) - cleared %.1fkA',F.Isym); drawnow;
pause(1.2);
set(U.fh,'Visible','off');
st.Text='CLEARED - system healthy. Replay or pick another case.';
end



function h=gl(h,r,c)
%GL Place a uigridlayout child (Layout must be GridLayoutOptions).
h.Layout.Row=r; h.Layout.Column=c;
end




