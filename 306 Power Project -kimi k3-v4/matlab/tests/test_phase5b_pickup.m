function [np,nf]=test_phase5b_pickup()
% Exercise pickup conversions and numerical inverse/DT behavior from real rows.
T=t_case('test_phase5b_pickup'); R=phase5b_registry(); ids={R.devices.device_id};
names={'GEN-51','GEN-51N','GSUT-HV-51','GIS-Q0-51'};
loadA=[14309,0,870.772573866956,870.772573866956];
pick=[17170.8,4,1380,1500]; sec=[1.14472,.20,.8625,.9375]; tm=[.10,.15,.55,.80];
for k=1:numel(names)
 d=R.devices(strcmp(ids,names{k})); P=phase5b_pickup(d,loadA(k),2*pick(k));
 T=T.chk(abs(P.setting-pick(k))<1e-9&&abs(P.setting_sec_A-sec(k))<1e-12,[names{k} ' primary and secondary pickups on correct CT base']);
 T=T.chk(strcmp(P.curve,'SI')&&P.use_phase5_time&&abs(P.tms-tm(k))<1e-12,[names{k} ' uses adopted SI timer']);
 observed=phase5_time(2*P.setting_sec_A,P.setting_sec_A,P.tms,P.curve);
 expected=.14*tm(k)/(2^.02-1);
 T=T.chk(abs(observed-expected)<1e-10&&isinf(phase5_time(P.setting,P.setting,P.tms,P.curve)),[names{k} ' matches IEC SI formula and does not trip at pickup']);
 T=T.chk(strlength(string(P.source))>0&&strlength(string(P.basis))>0,[names{k} ' carries setting provenance']);
end
g=R.devices(strcmp(ids,'GEN-51')); a=g;a.device_id='GEN-51-SI';
Pa=phase5b_pickup(a,14309,55049);T=T.chk(abs(Pa.setting-17170.8)<1e-9,'GEN-51-SI alias preserves the numerical pickup');
e=R.devices(strcmp(ids,'GEN-51N')); Pe=phase5b_pickup(e,0,7.27200442799167);
te=phase5_time(7.27200442799167,Pe.setting,Pe.tms,Pe.curve);
T=T.chk(te>1.7&&te<1.8,'dedicated neutral 4 A setting detects the 7.272 A F1 LG residual');
e5=e;e5.device_id='GEN-51N-5A-SENS';P5=phase5b_pickup(e5,0,7.27200442799167);
T=T.chk(P5.setting==5&&P5.setting_sec_A==.25&&strcmp(P5.assumption_class,'SENSITIVITY')&&Pe.setting==4,'5 A alternative cannot replace the primary 4 A setting');
q=phase5b_pickup(R.devices(strcmp(ids,'GIS-Q0-51')),870.77,3200);
T=T.chk(strcmp(q.assumption_class,'CONDITIONAL'),'Q0 numerical pickup preserves conditional scope');
bl=R.devices(strcmp(ids,'GEN-51-SIEMENS-BL')); Pb=phase5b_pickup(bl,14309,55049);
T=T.chk(abs(Pb.setting-17170.8)<.5&&abs(Pb.setting_sec_A-Pb.setting/15000)<1e-12,'DT comparator primary and secondary values are consistent');
T=T.chk(strcmp(Pb.curve,'DT')&&Pb.tdef==3&&strcmp(Pb.assumption_class,'SENSITIVITY'),'DT comparator has numerical 3 s timing and sensitivity scope');
T=T.chk(phase5_time(2*Pb.setting,Pb.setting,Pb.tdef,Pb.curve)==3&&isinf(phase5_time(.5*Pb.setting,Pb.setting,Pb.tdef,Pb.curve)),'DT comparison executes 3 s above pickup and Inf below');
try,phase5_curve(2,'DT',3);T=T.chk(false,'DT cannot enter inverse curve engine');catch ME,T=T.chk(startsWith(ME.identifier,'phase5'),'DT cannot enter inverse curve engine');end
checks={@()phase5b_pickup(g,-1,55049),'phase5b_pickup:load';@()phase5b_pickup(g,0,NaN),'phase5b_pickup:fault'; ...
 @()phase5b_pickup(struct('device_id',''),0,1),'phase5b_pickup:device'; ...
 @()phase5b_pickup(R.devices(strcmp(ids,'GIS-Q0-50')),0,3200),'phase5b_pickup:disabled'; ...
 @()phase5b_pickup(R.devices(strcmp(ids,'LINE-21-note')),0,3200),'phase5b_pickup:unsupported'};
for k=1:size(checks,1),try,checks{k,1}();T=T.chk(false,checks{k,2});catch ME,T=T.chk(strcmp(ME.identifier,checks{k,2}),checks{k,2});end,end
bad=g;bad.ct_ratio=16000;
try,phase5b_pickup(bad,14309,55049);T=T.chk(false,'legacy CT cannot enter primary GEN setting');catch ME,T=T.chk(strcmp(ME.identifier,'phase5b_pickup:ct'),'legacy CT cannot enter primary GEN setting');end
[np,nf]=T.done();
end
