function net = phase6_add_network(mdl,P,S)
%PHASE6_ADD_NETWORK Actual SPS circuits, conserving ports and measured zones.
B=sps_blocks(); E=phase6_electrical_profile(P,S);
noteCount=0;
net=struct('model',mdl,'profile',E,'measurements',struct(),'faults',struct(),'breakers',struct());
net.sensorNames={'genInner','genTerminal','gsutLV','gsutHV','busIn','busOut', ...
    'gatHV','lineLocal','lineRemote','aux','grid','neutral', ...
    'faultGEN','faultLV','faultHV','faultGIS','faultLINE','faultGRID','faultAUX'};

% Generator. The neutral equivalent belongs to the machine side of the CTs.
g=subsystem('Generator',[260 705 440 835],'up');
net.generator=[g '/Synchronous machine'];
add(B.syncmachine,net.generator,[70 170 210 310]);
set_param(net.generator,'RotorType','Round','dAxisTimeConstants','Open-circuit', ...
    'qAxisTimeConstants','Open-circuit','MeasurementBus','on','SetSaturation','off', ...
    'IterativeDiscreteModel',E.machineDiscreteSolver, ...
    'NominalParameters',num([P.machine.Sn_VA P.machine.Vn_V P.f_Hz]), ...
    'Reactances1',num(P.machine.reactances_pu),'TimeConstants2',num(P.machine.timeConstants_s), ...
    'StatorResistance',num(P.machine.Rs_pu),'Mechanical',num([P.machine.H_s P.machine.damping_pu P.machine.polePairs]), ...
    'BusType','PV','Pref',num(S.dispatch_MW*1e6),'Qmin','-inf','Qmax','inf');
machineNode=port(net.generator,'R');
grounding(g,machineNode);
sh=[g '/Numerical terminal shunt'];add(B.load,sh,[270 390 360 455]);
set_param(sh,'NominalVoltage','22000','NominalFrequency','50','ActivePower',num(P.numericalShunt_W), ...
    'InductivePower','0','CapacitivePower','0','LoadType','constant Z','Configuration','Y (grounded)');
wire(g,machineNode,port(sh,'L'));
ct1=sensor(g,'Generator inner CT','genInner',[270 170 320 245]);wire(g,machineNode,port(ct1,'L'));
genFault=port(ct1,'R'); fault(g,'Generator fault','GEN','faultGEN',genFault,[365 335 425 390]);
ct2=sensor(g,'Generator terminal CT','genTerminal',[425 170 475 245]);wire(g,genFault,port(ct2,'L'));
out=connector(g,'22 kV',1,'Right',[630 170 650 190]);wire(g,port(ct2,'R'),out);
net.pmInitial=[g '/Mechanical power']; add('simulink/Sources/Constant',net.pmInitial,[10 65 100 90]);
set_param(net.pmInitial,'Value',num(S.dispatch_MW*1e6/P.machine.Sn_VA));
net.vfInitial=[g '/Field voltage'];add('simulink/Sources/Constant',net.vfInitial,[125 65 210 90]);set_param(net.vfInitial,'Value','1.8');
add_line(g,'Mechanical power/1','Synchronous machine/1','autorouting','on');
add_line(g,'Field voltage/1','Synchronous machine/2','autorouting','on');
tag(g,'Machine states',net.generator,1,'P6_MACHINE',[260 85 390 110]);
note(g,'Generator 10MKA10  |  458 MVA, 22 kV, 50 Hz', [65 15],14);
note(g,'The internal fault is a terminal equivalent inside the two CT boundaries.',[65 495],10);

% Generator breaker is visible on the master SLD.
net.breakers.GCB=breaker(mdl,'Generator Breaker',[307 605 393 648],'GCB','up',true);
wire(mdl,port(g,'R'),port(net.breakers.GCB,'L'));

% Transformer: both CTs enclose selectable LV and HV faults.
t=subsystem('Transformer',[260 355 440 460],'down');
hv=connector(t,'230 kV',1,'Left',[70 85 90 105]);
lv=connector(t,'22 kV',4,'Right',[650 365 670 385]);
tx=transformer(t,'GSUT 10BAT10','GSUT',[290 220 390 315]);
ctLV=sensor(t,'LV CT','gsutLV',[480 365 530 425]);wire(t,lv,port(ctLV,'L'));
lvNode=port(ctLV,'R');wire(t,lvNode,port(tx,'R'));
fault(t,'LV connection fault','GSUT_LV','faultLV',lvNode,[410 495 465 550]);
ctHV=sensor(t,'HV CT','gsutHV',[180 85 230 150]);wire(t,port(tx,'L'),port(ctHV,'L'));
fault(t,'HV winding equivalent fault','GSUT_HV','faultHV',port(tx,'L'),[440 110 500 165]);
wire(t,port(ctHV,'R'),hv);
net.transformer=tx;
note(t,'GSUT 10BAT10  |  515 MVA, 230 / 22 kV, YNd1',[70 20],14);
note(t,'87T compares both CTs with ratio and vector-group compensation.',[70 590],10);
wire(mdl,port(net.breakers.GCB,'R'),port(t,'R'));

% GIS bus zone, with a real Q0 and branch CT boundaries.
sw=subsystem('Switchyard',[260 135 465 245],'right');
hvIn=connector(sw,'GSUT',1,'Left',[40 195 60 215]);
lineOut=connector(sw,'Line',4,'Right',[740 115 760 135]);
gatOut=connector(sw,'GAT',7,'Right',[740 365 760 385]);
net.breakers.Q0=breaker(sw,'GSUT breaker Q0',[140 165 210 245],'Q0','right',true);
wire(sw,hvIn,port(net.breakers.Q0,'L'));
cbi=sensor(sw,'Bus incoming CT','busIn',[255 165 305 245]);wire(sw,port(net.breakers.Q0,'R'),port(cbi,'L'));
bus=port(cbi,'R');
cbo=sensor(sw,'Line feeder CT','busOut',[570 95 620 170]);wire(sw,bus,port(cbo,'L'));wire(sw,port(cbo,'R'),lineOut);
cbg=sensor(sw,'GAT feeder CT','gatHV',[570 345 620 415]);wire(sw,bus,port(cbg,'L'));wire(sw,port(cbg,'R'),gatOut);
fault(sw,'GIS bus fault','GIS230','faultGIS',bus,[385 470 445 525]);
note(sw,'230 kV GIS  |  bus differential zone',[65 25],14);
note(sw,'Q0: GSUT bay equivalent. Line and bus breaker sets are study equivalents.',[65 575],10);
wire(mdl,port(t,'L'),port(sw,'L'));

% Two physical PI circuits with a midpoint fault on circuit 1.
l=subsystem('Transmission Line',[680 135 890 245],'right');
li=connector(l,'Plant',1,'Left',[30 260 50 280]);lo=connector(l,'Remote',4,'Right',[1130 260 1150 280]);
net.breakers.LineLocal=breaker(l,'Local line breaker',[115 245 180 320],'LineLocal','right',true);
cl=sensor(l,'Local line CT','lineLocal',[225 240 275 320]);wire(l,li,port(net.breakers.LineLocal,'L'));wire(l,port(net.breakers.LineLocal,'R'),port(cl,'L'));
cr=sensor(l,'Remote line CT','lineRemote',[840 240 890 320]);
net.breakers.LineRemote=breaker(l,'Remote line breaker',[965 245 1030 320],'LineRemote','right',true);
wire(l,port(cr,'R'),port(net.breakers.LineRemote,'L'));wire(l,port(net.breakers.LineRemote,'R'),lo);
for circuit=1:2
    y=110+(circuit-1)*340;
    a=[l sprintf('/Circuit %d - plant half',circuit)];b=[l sprintf('/Circuit %d - remote half',circuit)];
    add(B.pisection,a,[365 y 475 y+75]);add(B.pisection,b,[600 y 710 y+75]);
    for blk={a,b}
        set_param(blk{1},'Length',num(E.length_km/2),'Frequency','50', ...
            'Resistances',num([E.Rline E.R0line]/E.length_km), ...
            'Inductances',num([E.Xline E.X0line]/(2*pi*50*E.length_km)), ...
            'Capacitances',num([E.Cline E.C0line]/E.length_km));
    end
    wire(l,port(cl,'R'),port(a,'L'));wire(l,port(a,'R'),port(b,'L'));wire(l,port(b,'R'),port(cr,'L'));
    if circuit==1,fault(l,'Line midpoint fault','LINE230','faultLINE',port(a,'R'),[515 290 570 345]);end
end
note(l,'South connection  |  0.7 km, two circuits',[80 20],14);
note(l,'87L uses synchronized currents at both ends. Both circuits use the line-end breaker sets.',[80 595],10);
swPorts=port(sw,'R');wire(mdl,swPorts(1:3),port(l,'L'));

% Grid uses a sequence impedance element so Z0 is not accidentally Z1.
gr=subsystem('Grid',[1100 135 1280 245],'right');
gp=connector(gr,'230 kV',1,'Left',[25 180 45 200]);
gc=sensor(gr,'Grid CT and VT','grid',[125 155 180 225]);wire(gr,gp,port(gc,'L'));
gz=[gr '/Grid sequence impedance'];
add(['spsThreePhaseMutualInductanceZ1Z0Lib/Three-Phase' newline 'Mutual Inductance' newline 'Z1-Z0'],gz,[300 155 420 225]);
set_param(gz,'PositiveSequence',num([E.Rgrid E.Xgrid/(2*pi*50)]),'ZeroSequence',num([E.R0grid E.X0grid/(2*pi*50)]));
wire(gr,port(gc,'R'),port(gz,'L'));
gridSource=[gr '/PGCB voltage source'];add(B.source,gridSource,[515 150 625 230]);
set_param(gridSource,'NonIdealSource','off','InternalConnection','Yg','Voltage','230000','BaseVoltage','230000','PhaseAngle','0','Frequency','50','BusType','swing');
wire(gr,port(gz,'R'),port(gridSource,'R'));
fault(gr,'Remote bus fault','GRID230','faultGRID',gp,[245 355 305 410]);
note(gr,'PGCB equivalent  |  230 kV, 50 Hz',[60 25],14);
note(gr,strrep(E.name,'_',' '),[60 470],11);
wire(mdl,port(l,'R'),port(gr,'L'));

% Auxiliary transformers, explicit 6.9kV windings and 6.6kV switchboard loads.
a=subsystem('Auxiliaries',[680 465 890 580],'right');
ua=connector(a,'Unit 22 kV',1,'Left',[40 125 60 145]);ga=connector(a,'GIS 230 kV',4,'Right',[815 125 835 145]);
uat=transformer(a,'UAT 10BBT10','UAT',[210 195 305 290]);
gat=transformer(a,'GAT 10BBT20','GAT',[600 195 695 290]);
wire(a,ua,port(uat,'L'));
net.breakers.GAT=breaker(a,'GAT incomer',[615 85 680 145],'GAT','down',S.GAT_in);
wire(a,ga,port(net.breakers.GAT,'L'));wire(a,port(net.breakers.GAT,'R'),port(gat,'L'));
auxBus=port(uat,'R');wire(a,auxBus,port(gat,'R'));
ac=sensor(a,'Auxiliary bus CT and VT','aux',[375 375 430 450]);wire(a,auxBus,port(ac,'L'));
loadBus=port(ac,'R');
for k=1:numel(E.loads)
    d=E.loads(k);bl=[a sprintf('/%s',strrep(d.Label,'/','-'))];
    add(B.load,bl,[120+230*(k-1) 590 225+230*(k-1) 660]);
    set_param(bl,'NominalVoltage',num(d.Vnom_V),'NominalFrequency','50','ActivePower',num(d.P_MW*1e6), ...
        'InductivePower',num(d.Q_MVAr*1e6),'CapacitivePower','0','LoadType','constant PQ','Configuration',E.auxLoadConfiguration);
    wire(a,loadBus,port(bl,'L'));
end
fault(a,'Auxiliary bus fault','AUX66','faultAUX',auxBus,[785 430 845 485]);
note(a,'Plant auxiliaries  |  14 MW, 0.85 power factor',[85 20],14);
note(a,'6.9 kV transformer windings; 6.6 kV switchboard. GAT is normally out of service.',[85 730],10);
wire(mdl,port(net.breakers.GCB,'R'),port(a,'L'));
wire(mdl,swPorts(4:6),port(a,'R'));
net.subsystems=struct('generator',g,'transformer',t,'switchyard',sw,'line',l,'grid',gr,'auxiliaries',a);

    function path=subsystem(name,pos,orientation)
        path=[mdl '/' name];add_block('built-in/Subsystem',path);set_param(path,'Orientation',orientation,'Position',pos,'FontSize','13');
    end
    function add(lib,path,pos)
        add_block(lib,path);set_param(path,'Position',pos,'FontSize','11');
    end
    function h=port(path,side)
        ph=get_param(path,'PortHandles');h=ph.([upper(side) 'Conn']);
        if strcmp(get_param(path,'MaskType'),'Three-Phase Transformer (Two Windings)'),h=h(1:3);end
    end
    function wire(parent,x,y)
        assert(numel(x)==numel(y),'Phase6:Ports','Electrical port counts disagree.');
        for z=1:numel(x),add_line(parent,x(z),y(z),'autorouting','on');end
    end
    function h=connector(parent,name,first,side,pos)
        h=zeros(1,3);
        for ph=1:3
            path=[parent '/' name ' ' char(64+ph)];add('built-in/PMIOPort',path,pos+[0 35*(ph-1) 0 35*(ph-1)]);
            set_param(path,'Port',num2str(first+ph-1),'Side',side);
            hp=get_param(path,'PortHandles');h(ph)=[hp.LConn hp.RConn];
        end
    end
    function path=sensor(parent,name,key,pos)
        path=[parent '/' name];add(B.vimeas,path,pos);
        set_param(path,'VoltageMeasurement','phase-to-ground','CurrentMeasurement','yes','Vpu','off','Ipu','off');
        tag(parent,[name ' voltage'],path,1,['P6_' key '_V'],[pos(1)+20 pos(2)-55 pos(1)+140 pos(2)-35]);
        tag(parent,[name ' current'],path,2,['P6_' key '_I'],[pos(1)+20 pos(2)-28 pos(1)+140 pos(2)-8]);
        net.measurements.(key)=path;
    end
    function tag(parent,name,source,out,tagName,pos)
        dst=[parent '/' name];add('simulink/Signal Routing/Goto',dst,pos);set_param(dst,'GotoTag',tagName,'TagVisibility','global');
        h=get_param(source,'PortHandles');d=get_param(dst,'PortHandles');add_line(parent,h.Outport(out),d.Inport(1),'autorouting','on');
    end
    function path=breaker(parent,name,pos,key,orientation,initial)
        path=[parent '/' name];add(B.breaker,path,pos);set_param(path,'Orientation',orientation,'Position',pos, ...
            'InitialState',choose(initial,'closed','open'),'External','on','BreakerResistance',num(E.breakerRon_ohm), ...
            'SnubberResistance',num(E.breakerSnubber_ohm),'SnubberCapacitance','inf');
        f=[parent '/' key ' command'];add('simulink/Signal Routing/From',f,[pos(1)-120 pos(2)-45 pos(1)-15 pos(2)-20]);set_param(f,'GotoTag',['P6_BR_' key]);
        hf=get_param(f,'PortHandles');hp=get_param(path,'PortHandles');add_line(parent,hf.Outport(1),hp.Inport(1),'autorouting','on');
    end
    function path=transformer(parent,name,which,pos)
        d=E.transformers(strcmp({E.transformers.Name},which));path=[parent '/' name];add(B.tx2,path,pos);
        set_param(path,'Orientation','down','Position',pos,'UNITS','pu','NominalPower',num([d.S_rating_MVA*1e6 P.f_Hz]), ...
            'Winding1',num([d.V_HV_V d.R1_pu d.L1_pu]),'Winding2',num([d.V_LV_V d.R2_pu d.L2_pu]), ...
            'Winding1Connection',d.Conn_HV,'Winding2Connection',d.Conn_LV,'CoreType',d.Model_coretype, ...
            'SetSaturation','off','Rm',num(d.Rm_pu),'Lm',num(d.Lm_pu),'L0',num(d.L0_pu));
        if ismember(which,{'UAT','GAT'})
            set_param(path,'Winding2Connection','Yn');
            hp=get_param(path,'PortHandles');
            rn=[parent '/' which ' neutral resistor'];add('sps_lib/Passives/Series RLC Branch',rn,[pos(1)+105 pos(2)+85 pos(1)+170 pos(2)+115]);
            set_param(rn,'BranchType','R','Resistance',num(E.auxNeutral_ohm));
            er=[parent '/' which ' earth'];add(B.ground,er,[pos(1)+195 pos(2)+90 pos(1)+215 pos(2)+115]);
            hr=get_param(rn,'PortHandles');he=get_param(er,'PortHandles');
            add_line(parent,hp.RConn(4),hr.LConn(1),'autorouting','on');add_line(parent,hr.RConn(1),he.LConn(1),'autorouting','on');
        end
    end
    function fault(parent,name,location,key,node,pos)
        sense=sensor(parent,[name ' measurement'],key,pos+[-70 -40 -70 -40]);wire(parent,node,port(sense,'L'));
        path=[parent '/' name];add(B.fault,path,pos+[70 50 70 50]);wire(parent,port(sense,'R'),port(path,'L'));
        phases=[1 1 1];earth=false;
        switch upper(S.faultType)
            case {'SLG','LG'},phases=[1 0 0];earth=true;
            case 'LL',phases=[0 1 1];
            case 'LLG',phases=[0 1 1];earth=true;
        end
        times=[1e6 1e6+1];if S.faultEnabled && strcmpi(S.faultLocation,location),times=[S.faultStart_s S.faultStart_s+S.faultDuration_s];end
        set_param(path,'FaultA',choose(phases(1),'on','off'),'FaultB',choose(phases(2),'on','off'), ...
            'FaultC',choose(phases(3),'on','off'),'GroundFault',choose(earth,'on','off'), ...
            'SwitchTimes',num(times),'FaultResistance',num(S.faultResistance_ohm), ...
            'GroundResistance',num(S.groundResistance_ohm),'SnubberResistance',num(E.faultSnubber_ohm),'SnubberCapacitance','inf');
        net.faults.(location)=path;
    end
    function grounding(parent,node)
        gt=[parent '/Machine zero-sequence equivalent'];
        add(['spsGroundingTransformerLib/Grounding' newline 'Transformer '],gt,[400 405 510 465]);
        set_param(gt,'UNITS','pu','NominalPower',num([P.machine.Sn_VA P.f_Hz]),'NominalVoltage',num(P.machine.Vn_V), ...
            'ZeroSequenceImpedance_pu',num(E.generatorZ0),'MagnetizationBranch_pu',num(E.groundMagnetization_pu),'Measurements','None');
        h=get_param(gt,'PortHandles');allp=[h.LConn h.RConn];wire(parent,node,allp(1:3));
        nr=[parent '/Neutral resistor'];add(['sps_lib/Passives/Series RLC Branch'],nr,[620 435 685 470]);set_param(nr,'BranchType','R','Resistance',num(E.Rneutral));
        ni=[parent '/Neutral current'];add('sps_lib/Sensors and Measurements/Current Measurement',ni,[545 410 575 435]);
        hi=get_param(ni,'PortHandles');hr=get_param(nr,'PortHandles');add_line(parent,allp(4),hi.LConn(1),'autorouting','on');add_line(parent,hi.RConn(1),hr.LConn(1),'autorouting','on');
        gd=[parent '/Neutral earth'];add(B.ground,gd,[735 440 755 460]);hg=get_param(gd,'PortHandles');add_line(parent,hr.RConn(1),hg.LConn(1),'autorouting','on');
        % Pack physical neutral current into a three-phase-sized measurement pair.
        z=[parent '/Neutral padding'];add('simulink/Sources/Constant',z,[550 540 610 565]);set_param(z,'Value','[0 0 0]');
        tag(parent,'Neutral voltage tag',z,1,'P6_neutral_V',[660 535 775 560]);
        mx=[parent '/Neutral current vector'];add('simulink/Signal Routing/Mux',mx,[650 580 655 650]);set_param(mx,'Inputs','3');
        zz=[parent '/Zero'];add('simulink/Sources/Constant',zz,[555 665 610 685]);set_param(zz,'Value','0');
        add_line(parent,'Neutral current/1','Neutral current vector/1','autorouting','on');add_line(parent,'Zero/1','Neutral current vector/2','autorouting','on');add_line(parent,'Zero/1','Neutral current vector/3','autorouting','on');
        tag(parent,'Neutral current tag',mx,1,'P6_neutral_I',[705 605 815 630]);
    end
    function note(parent,text,pos,size)
        noteCount=noteCount+1;an=Simulink.Annotation(sprintf('%s/Note%d',parent,noteCount));an.Text=text;an.Position=pos;an.FontSize=size;
    end
end
function s=num(x),s=mat2str(x,15);end
function s=choose(tf,a,b),if tf,s=a;else,s=b;end;end
