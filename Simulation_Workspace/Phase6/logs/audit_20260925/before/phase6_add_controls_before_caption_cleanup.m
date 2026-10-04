function ctrl=phase6_add_controls(mdl,P,S,net,LF)
%PHASE6_ADD_CONTROLS Connect measured protection, station DC and machine control.
R=phase6_relay_parameters(P);D=phase6_dc_parameters(P);C=phase6_control_parameters(P,LF);
mw=get_param(mdl,'ModelWorkspace');assignin(mw,'R',R);assignin(mw,'D',D);assignin(mw,'C',C);
ctrl.parameters=C;
ctrl.relayParameters=R;
names={'genInner','genTerminal','gsutLV','gsutHV','busIn','busOut','gatHV', ...
    'lineLocal','lineRemote','aux','grid','neutral','faultGEN','faultLV','faultHV', ...
    'faultGIS','faultLINE','faultGRID','faultAUX'};

% A synchronized measurement chain makes all relay comparisons use one clock.
meas=sub('Measurements',[1090 490 1290 610]);ctrl.measurements=meas;
groups={1:4,5:9,10:12,13:19};titles={'Generator and transformer','Switchyard and line','Auxiliary and neutral','Fault currents'};
for j=1:4
    path=[meas '/' titles{j}];add_block('built-in/Subsystem',path,'Position',[50 70+135*(j-1) 270 145+135*(j-1)]);
    mx=add('simulink/Signal Routing/Mux',[path '/Voltage and current channels'],[340 35 345 80+65*numel(groups{j})]);
    set_param(mx,'Inputs',num2str(2*numel(groups{j})));
    for q=1:numel(groups{j})
        k=groups{j}(q);
        fr(path,[names{k} ' voltage'],['P6_' names{k} '_V'],[35 40+80*(q-1) 190 60+80*(q-1)],mx,2*q-1);
        fr(path,[names{k} ' current'],['P6_' names{k} '_I'],[35 70+80*(q-1) 190 90+80*(q-1)],mx,2*q);
    end
    out=add('simulink/Sinks/Out1',[path '/Measured abc'],[460 100 490 120]);line(path,mx,1,out,1);
end
all=add('simulink/Signal Routing/Mux',[meas '/All measured channels'],[360 85 365 520]);set_param(all,'Inputs','4');
for j=1:4,line(meas,[meas '/' titles{j}],1,all,j);end
gain=add('simulink/Math Operations/Gain',[meas '/CT measurement test factors'],[435 220 560 280]);
set_param(gain,'Gain','kron(S.measurementScale,ones(1,6))','Multiplication','Element-wise(K.*u)');line(meas,all,1,gain,1);
df=sf(meas,'Synchronized RMS and phasors','phase6_measurement_sfun','',[650 200 860 310]);line(meas,gain,1,df,1);
go(meas,'Primary phasors','P6_PHASORS',df,1,[940 195 1100 225]);
go(meas,'Waveform RMS','P6_RMS',df,2,[940 245 1100 275]);
go(meas,'Measurement ready','P6_VALID',df,3,[940 295 1100 325]);
logsignal(meas,all,1,'phase6_raw',[430 390 595 420],'0.0002');
logsignal(meas,df,1,'phase6_phasors',[930 375 1090 405],'-1');
logsignal(meas,df,2,'phase6_rms',[930 435 1090 465],'-1');
note(meas,'CT / VT measurements   |   primary V and A',[45 15],15);
note(meas,'One 50 Hz cycle, synchronized 1 ms sampling. Relay inputs become valid after the first complete window.',[45 600],11);

prot=sub('Protection',[680 710 890 825]);ctrl.protection=prot;
rel=sf(prot,'Pickup and relay timing','phase6_relay_sfun','R,S',[305 75 520 170]);
fr(prot,'CT phasors','P6_PHASORS',[30 70 195 100],rel,1);
fr(prot,'Measurement ready','P6_VALID',[30 130 195 160],rel,2);
go(prot,'Relay indications','P6_RELAY',rel,1,[615 70 770 100]);
go(prot,'Trip requests','P6_REQUESTS',rel,2,[615 135 770 165]);
logsignal(prot,rel,1,'phase6_relay',[615 205 790 235],'-1');
sc=add('simulink/Sinks/Scope',[prot '/Relay pickup and timing'],[625 285 710 335]);line(prot,rel,1,sc,1);
note(prot,'51 / 51N     87G     87T     87B     87L',[40 15],15);
note(prot,'Measured currents → CT ratios → pickup / timing → trip request',[40 390],12);
note(prot,'Open the algorithm block to inspect the tested equations. Trip requests pass through the DC supply and breaker mechanism.',[40 425],10);

dc=sub('DC Supply',[680 935 890 1050]);ctrl.dc=dc;
getRms=fr(dc,'Auxiliary AC measurements','P6_RMS',[35 80 205 110]);
sel=select(dc,'Auxiliary phase voltage',[55:57],[270 75 335 115]);line(dc,getRms,1,sel,1);
mag=add('built-in/Fcn',[dc '/AC supply magnitude'],[395 75 595 115]);set_param(mag,'Expr','sqrt((u(1)^2+u(2)^2+u(3)^2)/3)*sqrt(3)/6600');line(dc,sel,1,mag,1);
dcb=sf(dc,'Battery charger and DC bus','phase6_dc_sfun','D,S',[690 80 920 190]);line(dc,mag,1,dcb,1);
req=fr(dc,'Protection trip demand','P6_REQUESTS',[35 205 220 235]);
anyTrip=add('built-in/Fcn',[dc '/Trip coil demand'],[395 205 595 240]);set_param(anyTrip,'Expr','u(1)+u(2)+u(3)+u(4)+u(5)+u(6)>0');line(dc,req,1,anyTrip,1);line(dc,anyTrip,1,dcb,2);
go(dc,'DC measurements and alarms','P6_DC',dcb,1,[1000 100 1190 135]);
logsignal(dc,dcb,1,'phase6_dc',[1000 190 1190 220],'-1');
sc=add('simulink/Sinks/Scope',[dc '/DC voltage current and SOC'],[1020 275 1110 330]);line(dc,dcb,1,sc,1);
note(dc,'110 V station DC supply',[40 15],16);
note(dc,'AC supply → charger   |   battery ↔ DC bus → control loads and trip coils',[40 350],13);
note(dc,'55-cell, 200 Ah study bank. The bus solves battery resistance, charger limits, load demand and SOC at each time step.',[40 400],11);

trip=sub('Breaker Control',[1090 720 1290 830]);ctrl.breaker=trip;
br=sf(trip,'DC trip path and mechanism','phase6_breaker_sfun','C,S',[380 80 615 180]);
fr(trip,'Protection requests','P6_REQUESTS',[40 60 240 90],br,1);
dctag=fr(trip,'DC supply status','P6_DC',[40 190 240 220]);
healthy=select(trip,'DC healthy',6,[275 190 340 220]);line(trip,dctag,1,healthy,1);line(trip,healthy,1,br,2);
go(trip,'Breaker indications','P6_BREAKERS',br,1,[850 365 1040 395]);
keys={'GCB','Q0','LineLocal','LineRemote','GAT','UNIT_TRIP'};
for k=1:6
    sl=select(trip,keys{k},k,[680 40+55*(k-1) 745 70+55*(k-1)]);line(trip,br,1,sl,1);
    if k<6,tag=['P6_BR_' keys{k}];else,tag='P6_UNIT_TRIP';end
    go(trip,[keys{k} ' output'],tag,sl,1,[835 40+55*(k-1) 1000 70+55*(k-1)]);
end
logsignal(trip,br,1,'phase6_breakers',[385 290 590 320],'-1');
note(trip,'Trip circuits and breaker mechanisms',[40 15],15);
note(trip,'DC supply → trip coil → 50 ms mechanism → breaker command. Open commands latch until the next run.',[40 455],11);

control=sub('Turbine and AVR',[50 930 300 1050]);ctrl.machineControl=control;
bs=add('simulink/Signal Routing/Bus Selector',[control '/Machine voltage and speed'],[220 85 225 225]);set_param(bs,'OutputSignals','w,vd,vq,delta');
fr(control,'Machine measurements','P6_MACHINE',[30 115 175 150],bs,1);
vtmx=add('simulink/Signal Routing/Mux',[control '/dq voltage'],[300 145 305 195]);set_param(vtmx,'Inputs','2');line(control,bs,2,vtmx,1);line(control,bs,3,vtmx,2);
vt=add('built-in/Fcn',[control '/Terminal voltage'],[365 145 490 185]);set_param(vt,'Expr','sqrt(u(1)^2+u(2)^2)');line(control,vtmx,1,vt,1);
mx=add('simulink/Signal Routing/Mux',[control '/Controller measurements'],[560 85 565 270]);set_param(mx,'Inputs','3');line(control,bs,1,mx,1);line(control,vt,1,mx,2);
fr(control,'Unit trip','P6_UNIT_TRIP',[325 250 490 280],mx,3);
cb=sf(control,'Governor turbine and AVR','phase6_control_sfun','C',[645 125 860 220]);line(control,mx,1,cb,1);
pm=select(control,'Mechanical power',1,[920 105 985 145]);vf=select(control,'Field voltage',2,[920 210 985 250]);line(control,cb,1,pm,1);line(control,cb,1,vf,1);
go(control,'Mechanical input','P6_PM',pm,1,[1045 105 1185 145]);go(control,'Excitation input','P6_VF',vf,1,[1045 210 1185 250]);
mm=add('simulink/Signal Routing/Mux',[control '/Machine state record'],[330 385 335 540]);set_param(mm,'Inputs','4');
line(control,bs,1,mm,1);line(control,bs,4,mm,2);line(control,pm,1,mm,3);line(control,vf,1,mm,4);
go(control,'Machine state record tag','P6_MACHINE_RECORD',mm,1,[440 420 660 450]);
logsignal(control,mm,1,'phase6_machine',[440 500 660 530],'-1');
note(control,'Turbine, governor and voltage regulator',[35 20],16);
note(control,'Generic 5% droop; finite governor and turbine lags. AVR and mechanical power start at the solved load flow.',[35 585],11);
% Replace only the temporary load-flow Pm/Vf constants with active controllers.
hp=get_param(net.generator,'PortHandles');
for k=1:2,h=get_param(hp.Inport(k),'Line');if h~=-1,delete_line(h);end;end
delete_block(net.pmInitial);delete_block(net.vfInitial);
fr(net.subsystems.generator,'Mechanical power input','P6_PM',[10 65 110 95],net.generator,1);
fr(net.subsystems.generator,'Field voltage input','P6_VF',[130 65 230 95],net.generator,2);

mon=sub('Results',[1090 940 1290 1050]);ctrl.results=mon;
mb=sf(mon,'Plant quantities','phase6_monitor_sfun','',[370 70 575 245]);
tags={'P6_PHASORS','P6_MACHINE_RECORD','P6_RELAY','P6_BREAKERS','P6_DC'};
for k=1:5,fr(mon,strrep(tags{k},'P6_',''),tags{k},[45 45+65*(k-1) 250 75+65*(k-1)],mb,k);end
go(mon,'Plant summary','P6_SUMMARY',mb,1,[690 80 870 110]);
logsignal(mon,mb,1,'phase6_summary',[690 150 890 180],'-1');
sc=add('simulink/Sinks/Scope',[mon '/Dynamic response'],[690 245 790 310]);line(mon,mb,1,sc,1);
note(mon,'Dynamic measurements and event records',[35 15],15);
note(mon,'All records come from this simulation. Run export_phase6_results to create labelled plots and CSV tables.',[35 420],11);

% Save the numerical interfaces with the model and the exported report.
ctrl.sensorNames=names;
ctrl.summaryNames={'Generator_P_MW','Generator_Q_MVAr','Generator_V_kV','Generator_I_kA', ...
    'Frequency_Hz','Rotor_speed_pu','Machine_delta','GSUT_HV_I_kA','Bus230_V_kV', ...
    'Grid_I_kA','Fault_I_kA','Relay_pickup','Relay_trip','GCB_closed','Q0_closed', ...
    'Line_local_closed','Line_remote_closed','DC_V','Battery_SOC_pct','DC_healthy', ...
    'Auxiliary_V_kV','Grid_P_MW','Grid_Q_MVAr','DC_alarm'};
assignin(mw,'Phase6Metadata',ctrl);

    function p=sub(n,pos),p=[mdl '/' n];add_block('built-in/Subsystem',p,'Position',pos,'FontSize','13');end
    function p=add(lib,p,pos),add_block(lib,p,'Position',pos,'FontSize','11');end
    function p=sf(parent,n,f,prm,pos)
        p=add('simulink/User-Defined Functions/Level-2 MATLAB S-Function',[parent '/' n],pos);
        set_param(p,'FunctionName',f,'Parameters',prm);
    end
    function line(parent,a,pa,b,pb)
        ha=get_param(a,'PortHandles');hb=get_param(b,'PortHandles');add_line(parent,ha.Outport(pa),hb.Inport(pb),'autorouting','on');
    end
    function p=fr(parent,n,t,pos,dst,in)
        p=add('simulink/Signal Routing/From',[parent '/' n],pos);set_param(p,'GotoTag',t);
        if nargin>=5,line(parent,p,1,dst,in);end
    end
    function go(parent,n,t,src,out,pos)
        p=add('simulink/Signal Routing/Goto',[parent '/' n],pos);set_param(p,'GotoTag',t,'TagVisibility','global');line(parent,src,out,p,1);
    end
    function p=select(parent,n,idx,pos)
        p=add('simulink/Signal Routing/Selector',[parent '/' n],pos);set_param(p,'NumberOfDimensions','1','InputPortWidth','-1','IndexMode','One-based','IndexOptionArray',{'Index vector (dialog)'},'IndexParamArray',{mat2str(idx)});
    end
    function logsignal(parent,src,port,n,pos,ts)
        p=add('simulink/Sinks/To Workspace',[parent '/' n],pos);set_param(p,'VariableName',n,'SaveFormat','Timeseries','MaxDataPoints','inf','SampleTime',ts);line(parent,src,port,p,1);
    end
    function note(parent,t,pos,sz)
        a=Simulink.Annotation(parent,t);a.Position=pos;a.FontSize=sz;
    end
end

