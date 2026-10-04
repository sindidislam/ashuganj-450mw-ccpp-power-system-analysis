function [tables,signals,metadata] = phase6_result_tables(out,info)
%PHASE6_RESULT_TABLES Label and summarize the actual logged simulation data.
% No simulation, file writes, expected-value substitution, or default relay
% reconstruction occurs here. Structs of timeseries are accepted for unit
% tests; export_phase6_results requires an actual SimulationOutput object.
required={'phase6_raw','phase6_phasors','phase6_rms','phase6_relay', ...
    'phase6_dc','phase6_breakers','phase6_machine','phase6_summary'};
widths=[114 228 114 43 12 6 4 24];
keys={'raw','phasors','rms','relay','dc','breakers','machine','summary'};
assert(isstruct(info)&&isfield(info,'scenario')&&isfield(info,'controls'), ...
    'Phase6:ResultMetadata','info.scenario and info.controls are required.');
sensorNames=string(info.controls.sensorNames(:));
summaryNames=string(info.controls.summaryNames(:));
assert(numel(sensorNames)==19 && numel(unique(sensorNames))==19);
assert(numel(summaryNames)==24 && numel(unique(summaryNames))==24);
S=info.scenario;
signals=struct(); tables=struct();
for k=1:numel(required)
    if isa(out,'Simulink.SimulationOutput'), value=out.get(required{k});
    elseif isstruct(out)&&isfield(out,required{k}), value=out.(required{k});
    else, error('Phase6:MissingSignal','Missing logged signal %s.',required{k}); end
    signals.(keys{k})=readSignal(value,widths(k),required{k});
end
relayNames=["GEN51";"GSUT51";"GEN51N";"87G";"87T";"87B";"87L"];
dcNames=["Vdc_V" "Battery_current_A" "Charger_current_A" "Load_current_A" ...
    "Battery_SOC_pu" "DC_healthy" "DC_low_voltage" "Battery_low" ...
    "Charger_failure" "Trip_unavailable" "Charger_AC_power_W" "Trip_coil_power_W"];
breakerNames=["GCB" "Q0" "LineLocal" "LineRemote" "GAT"];
labels=struct();
labels.raw=groupLabels(sensorNames,["Va_V" "Vb_V" "Vc_V" "Ia_A" "Ib_A" "Ic_A"]);
labels.rms=groupLabels(sensorNames,["Va_RMS_V" "Vb_RMS_V" "Vc_RMS_V" "Ia_RMS_A" "Ib_RMS_A" "Ic_RMS_A"]);
labels.phasors=groupLabels(sensorNames,["Va_Re_V" "Vb_Re_V" "Vc_Re_V" ...
    "Va_Im_V" "Vb_Im_V" "Vc_Im_V" "Ia_Re_A" "Ib_Re_A" "Ic_Re_A" ...
    "Ia_Im_A" "Ib_Im_A" "Ic_Im_A"]);
labels.relay=[relayNames+"_pickup";relayNames+"_trip";relayNames+"_timer_s"; ...
    relayNames+"_operating_time_s";relayNames(1:3)+"_secondary_A"; ...
    relayNames(4:7)+"_differential_A";relayNames(4:7)+"_restraint_A"; ...
    relayNames(4:7)+"_threshold_A"];
labels.dc=dcNames(:); labels.breakers=[breakerNames(:)+"_closed";"Unit_trip"];
labels.machine=["Rotor_speed_pu";"Machine_delta";"Mechanical_power_pu";"Field_voltage_pu"];
labels.summary=summaryNames;
for k=1:numel(keys)
    key=keys{k}; d=signals.(key);
    tables.([key '_timeseries'])=array2table([d.time d.data], ...
        'VariableNames',cellstr(["Time_s";labels.(key)]));
end
metadata=struct('dataOrigin','actual logged simulation samples', ...
    'measurementWarmup_s',.020,'measurementOutputDelay_s',.001, ...
    'nominalFrequency_Hz',50,'sensorNames',sensorNames, ...
    'summaryNames',summaryNames,'signalLabels',labels,'scenario',S);
if ~isa(out,'Simulink.SimulationOutput')
    metadata.dataOrigin='unit-test fixture (not a production simulation result)';
end
for k=1:numel(keys)
    d=signals.(keys{k});
    metadata.signals.(keys{k})=struct('sampleCount',numel(d.time), ...
        'start_s',d.time(1),'stop_s',d.time(end), ...
        'medianSampleInterval_s',median(diff(d.time)));
end
tables.signal_inventory=struct2table(struct( ...
    'Signal',string(required(:)),'Width',widths(:), ...
    'Samples',cellfun(@(k)numel(signals.(k).time),keys(:)), ...
    'First_time_s',cellfun(@(k)signals.(k).time(1),keys(:)), ...
    'Last_time_s',cellfun(@(k)signals.(k).time(end),keys(:)), ...
    'Median_step_s',cellfun(@(k)median(diff(signals.(k).time)),keys(:))));

[tables.load_point,preWindow]=loadPoint(signals.summary,S,summaryNames);
metadata.preEventWindow_s=preWindow;
tables.relay_times=relayTimes(signals.relay,relayNames,S);
[tables.breaker_times,firstOpen]=breakerTimes(signals,breakerNames,sensorNames,S);
[tables.fault_summary,metadata.faultMeasurement]=faultSummary(signals,sensorNames,S,firstOpen,preWindow);
tables.dc_statistics=dcStatistics(signals.dc,dcNames);
tables.events=eventTable(signals,relayNames,breakerNames,S);
[tables.phase_pickup,metadata.phasePickupSource]=phasePickup(signals.phasors,sensorNames,info,S);
metadata.currentCessationCriterion='Per-phase raw |I| <= max(1 A, 0.001*pre-command peak |I|), continuously for 20 ms after open command. This is measured current cessation, not contact-state measurement.';
metadata.faultWindowDefinition='Initial waveform window starts at scheduled fault time and ends at the earliest of +20 ms, scheduled fault end, first observed breaker open command, or record end; opening sample is excluded. Fundamental metrics require a fully post-fault DFT window and occur no earlier than fault start +21 ms.';
end

function signal=readSignal(value,width,name)
assert(isa(value,'timeseries'),'Phase6:SignalType','%s must be a timeseries.',name);
t=double(value.Time(:)); x=double(value.Data);
if size(x,1)==numel(t), x=reshape(x,numel(t),[]);
elseif size(x,ndims(x))==numel(t), x=reshape(x,[],numel(t)).';
else, error('Phase6:SignalShape','Cannot align samples of %s.',name); end
assert(~isempty(t)&&size(x,2)==width&&isreal(x), ...
    'Phase6:SignalShape','%s must have %d real channels.',name,width);
assert(all(isfinite(t))&&all(diff(t)>0),'Phase6:SignalTime','%s times must be strictly increasing.',name);
finiteChannels=1:width;
if strcmp(name,'phase6_relay')
    finiteChannels=setdiff(finiteChannels,22:28);
    assert(all(~isnan(x(:,22:28))&x(:,22:28)>=0,'all'), ...
        'Phase6:NonfiniteSignal','Relay operating-time channels contain invalid values.');
end
assert(all(isfinite(x(:,finiteChannels)),'all'),'Phase6:NonfiniteSignal', ...
    '%s contains nonfinite measured values; do not present a failed simulation as a completed result.',name);
signal=struct('time',t,'data',x);
end

function labels=groupLabels(sensors,channels)
labels=reshape((sensors+"_"+channels).',[],1);
end

function [T,window]=loadPoint(d,S,names)
stop=d.time(end)+eps(max(1,d.time(end)));
candidates=[];
if field(S,'faultEnabled',false), candidates(end+1)=field(S,'faultStart_s',Inf); end
if any(field(S,'manualOpen',false)), candidates(end+1)=field(S,'manualOpenTime_s',Inf); end
candidates(end+1)=field(S,'generatorTripTime_s',Inf);
candidates(end+1)=field(S,'dcLossTime_s',Inf);
candidates=candidates(isfinite(candidates)&candidates>=.020&candidates<=d.time(end));
if ~isempty(candidates), stop=min(candidates); end
start=max(.020,stop-.100);
mask=d.time>=start & d.time<stop;
window=[start stop]; n=nnz(mask);
if n>0
    values=d.data(mask,:); means=mean(values,1).'; mins=min(values,[],1).';
    maxs=max(values,[],1).'; deviations=std(values,0,1).';
    status=repmat("measured_pre_event_window",numel(names),1);
else
    means=nan(numel(names),1);mins=means;maxs=means;deviations=means;
    status=repmat("no_post_warmup_pre_event_samples",numel(names),1);
end
T=table(names,means,mins,maxs,deviations,repmat(start,numel(names),1), ...
    repmat(stop,numel(names),1),repmat(n,numel(names),1),status, ...
    'VariableNames',{'Quantity','Mean','Minimum','Maximum','Standard_deviation', ...
    'Window_start_s','Window_end_exclusive_s','Samples','Status'});
end

function T=relayTimes(d,names,S)
n=7; pickup=nan(n,1);trip=pickup;timer=pickup;operating=pickup;
pickupStatus=strings(n,1);tripStatus=strings(n,1);enabled=true(n,1);
if isfield(S,'relayMask'),enabled=logical(S.relayMask(:));end
enabled=enabled&logical(field(S,'protectionEnabled',true));
for k=1:n
    [pickup(k),ip,pickupStatus(k)]=firstActive(d.time,d.data(:,k)>.5,.020);
    [trip(k),it,tripStatus(k)]=firstActive(d.time,d.data(:,7+k)>.5,.020);
    if ~isnan(ip),operating(k)=d.data(ip,21+k);end
    if ~isnan(it),timer(k)=d.data(it,14+k);end
    if ~enabled(k) && isnan(pickup(k)),pickupStatus(k)="relay_disabled";end
    if ~enabled(k) && isnan(trip(k)),tripStatus(k)="relay_disabled";end
end
fault=NaN;if field(S,'faultEnabled',false),fault=field(S,'faultStart_s',NaN);end
T=table(names,enabled,pickup,trip,pickup-fault,trip-fault,trip-pickup,timer,operating,pickupStatus,tripStatus, ...
    'VariableNames',{'Relay','Enabled','First_pickup_s','First_trip_request_s', ...
    'Pickup_minus_fault_s','Trip_minus_fault_s','Trip_minus_pickup_s', ...
    'Timer_at_trip_s','Calculated_operating_time_at_pickup_s','Pickup_status','Trip_status'});
end

function [T,firstOpen]=breakerTimes(signals,names,sensors,S)
d=signals.breakers; raw=signals.raw; currentSensors=["genTerminal" "busIn" "lineLocal" "lineRemote" "gatHV"];
rows=cell(15,10);firstOpen=Inf; row=0;
for b=1:5
    before=d.data(1:end-1,b)>.5;after=d.data(2:end,b)<=.5;
    index=find(before&after&d.time(2:end)>=.020,1)+1;
    command=NaN;
    if ~isempty(index)
        command=d.time(index);
        if ~field(S,'faultEnabled',false)||command>=field(S,'faultStart_s',Inf)
            firstOpen=min(firstOpen,command);
        end
    end
    sensor=find(sensors==currentSensors(b),1);
    for p=1:3
        row=row+1;cessation=NaN;threshold=NaN;status="no_open_command_observed";
        if ~isnan(command)
            previous=raw.time>=max(.020,command-.020)&raw.time<command;
            current=raw.data(:,(sensor-1)*6+3+p);
            if any(previous)
                threshold=max(1,.001*max(abs(current(previous))));
                cessation=heldBelow(raw.time,abs(current)<=threshold,command,.020);
                if isnan(cessation),status="no_sustained_current_cessation_in_record";
                else,status="sustained_current_cessation_observed";end
            else,status="no_pre_command_current_window";end
        elseif all(d.data(:,b)<=.5)
            status="initially_open_no_open_transition";
        end
        failed=field(S,'breakerFailed',false(1,5));
        rows(row,:)={names(b),string(char('A'+p-1)),currentSensors(b),command,cessation, ...
            cessation-command,threshold,.020,logical(failed(b)),status};
    end
end
T=cell2table(rows,'VariableNames',{'Breaker','Phase','Current_sensor','Open_command_s', ...
    'Current_cessation_s','Cessation_minus_command_s','Current_threshold_A', ...
    'Required_hold_s','Failure_scenario_enabled','Status'});
end

function time=heldBelow(t,low,start,hold)
time=NaN;first=NaN;
for k=find(t>=start).'
    if low(k)
        if isnan(first),first=k;end
        if t(k)-t(first)>=hold-1e-10,time=t(first);return;end
    else,first=NaN;end
end
end

function [T,meta]=faultSummary(signals,sensors,S,firstOpen,pre)
locations=["GEN" "GSUT_LV" "GSUT_HV" "GIS230" "LINE230" "GRID230" "AUX66"];
branches=["faultGEN" "faultLV" "faultHV" "faultGIS" "faultLINE" "faultGRID" "faultAUX"];
location=upper(string(field(S,'faultLocation','')));idx=find(locations==location,1);
assert(~isempty(idx),'Phase6:FaultLocation','Unknown fault location in result metadata.');
sensor=find(sensors==branches(idx),1);assert(~isempty(sensor));
start=field(S,'faultStart_s',NaN); scheduledEnd=start+field(S,'faultDuration_s',NaN);
enabled=logical(field(S,'faultEnabled',false));
finish=min([start+.020 scheduledEnd firstOpen signals.raw.time(end)+eps(max(1,signals.raw.time(end)))]);
if ~enabled,start=NaN;finish=NaN;scheduledEnd=NaN;end
raw=signals.raw; ph=signals.phasors;
before=raw.time>=pre(1)&raw.time<pre(2);
initial=raw.time>=start-1e-10&raw.time<finish-1e-10&raw.time>=.020;
% At t, each phasor contains the 20 input samples ending at t-1 ms.
fundStart=start+.021;
fundEnd=min([start+.060 scheduledEnd firstOpen ph.time(end)+eps(max(1,ph.time(end)))]);
fund=ph.time>=fundStart-1e-10&ph.time<fundEnd-1e-10;
rows=cell(3,17);
for p=1:3
    column=(sensor-1)*6+3+p;
    previous=NaN;ir=NaN;peak=NaN;vr=NaN;fundamental=NaN;
    if any(before),previous=sqrt(mean(raw.data(before,column).^2));end
    if ~enabled,status="fault_not_enabled";
    elseif start>raw.time(end),status="fault_starts_after_record";
    elseif ~any(initial),status="no_pre_open_fault_samples";
    else
        ir=sqrt(mean(raw.data(initial,column).^2));peak=max(abs(raw.data(initial,column)));
        vr=sqrt(mean(raw.data(initial,(sensor-1)*6+p).^2));
        if finish-start>=.020-1e-9,status="full_initial_cycle_measured";
        else,status="partial_initial_cycle_before_open_or_end";end
    end
    if any(fund)
        base=(sensor-1)*12;
        z=complex(ph.data(fund,base+6+p),ph.data(fund,base+9+p));
        fundamental=mean(abs(z));fundStatus="full_post_fault_DFT_windows_measured";
    else,fundStatus="no_full_post_fault_DFT_window_before_open_or_end";end
    if ~enabled,fundStatus="fault_not_enabled";end
    rows(p,:)={location,branches(idx),string(char('A'+p-1)),enabled,start,finish, ...
        nnz(initial),previous,ir,peak,vr,fundamental,fundStart,fundEnd,nnz(fund),status,fundStatus};
end
T=cell2table(rows,'VariableNames',{'Fault_location','Fault_branch_sensor','Phase','Fault_enabled', ...
    'Initial_window_start_s','Initial_window_end_exclusive_s','Initial_samples', ...
    'Pre_event_current_RMS_A','Initial_current_waveform_RMS_A','Initial_peak_abs_current_A', ...
    'Initial_phase_voltage_waveform_RMS_V','Full_window_fundamental_current_RMS_A', ...
    'Fundamental_window_start_s','Fundamental_window_end_exclusive_s','Fundamental_samples', ...
    'Initial_window_status','Fundamental_window_status'});
meta=struct('location',location,'sensor',branches(idx),'initialWindow_s',[start finish], ...
    'fundamentalWindow_s',[fundStart fundEnd],'scheduledFaultEnd_s',scheduledEnd);
end

function T=dcStatistics(d,names)
mask=d.time>=.020;x=d.data(mask,:);t=d.time(mask);n=numel(names);
minimum=nan(n,1);maximum=minimum;average=minimum;first=minimum;last=minimum;activeDuration=minimum;
status=repmat("no_post_warmup_samples",n,1);
if ~isempty(x)
    minimum=min(x,[],1).';maximum=max(x,[],1).';average=mean(x,1).';first=x(1,:).';last=x(end,:).';
    for k=6:10,activeDuration(k)=sum(diff(t).*double(x(1:end-1,k)>.5));end
    status(:)="measured_post_warmup";
end
units=["V";"A";"A";"A";"pu";"logical";"logical";"logical";"logical";"logical";"W";"W"];
T=table(names(:),units,minimum,maximum,average,first,last,activeDuration,status, ...
    'VariableNames',{'Quantity','Unit','Minimum','Maximum','Mean','First','Last', ...
    'Active_duration_s','Status'});
end

function T=eventTable(signals,relayNames,breakerNames,S)
rows=cell(0,5);
for k=1:7
    edges(signals.relay,k,"relay_pickup",relayNames(k),"pickup","dropout");
    edges(signals.relay,7+k,"relay_trip_request",relayNames(k),"asserted","reset");
end
for k=1:5,edges(signals.breakers,k,"breaker_command",breakerNames(k),"closed","open");end
edges(signals.breakers,6,"unit_trip","Unit","asserted","reset");
names=["DC_healthy" "DC_low_voltage" "Battery_low" "Charger_failure" "Trip_unavailable"];
for k=1:5,edges(signals.dc,k+5,"DC_state",names(k),"asserted","cleared");end
edges(signals.dc,12,"trip_coil_power","Station_DC","energized","deenergized");
if field(S,'faultEnabled',false)
    schedule(field(S,'faultStart_s',NaN),"fault_on");
    schedule(field(S,'faultStart_s',NaN)+field(S,'faultDuration_s',NaN),"fault_off");
end
T=cell2table(rows,'VariableNames',{'Time_s','Event_group','Device','Transition','Source'});
if ~isempty(T),T=sortrows(T,'Time_s');end
    function edges(d,col,group,device,on,off)
        high=d.data(:,col)>.5;
        index=find(diff(high)~=0)+1;
        for j=index(:).'
            if d.time(j)<.020,continue;end
            transition=off;if high(j),transition=on;end
            rows(end+1,:)={d.time(j),group,device,transition,"logged_signal_transition"};
        end
    end
    function schedule(t,name)
        if isfinite(t)&&t>=.020&&t<=signals.raw.time(end)
            rows(end+1,:)={t,"scenario_schedule",string(S.faultLocation),name,"scenario_setting_not_measured_switch_state"};
        end
    end
end

function [T,source]=phasePickup(d,sensors,info,S)
% Re-evaluate each measured operating quantity against the exact run's
% threshold. Phase measurements precede the logged relay output by 1 ms.
% Trip timers remain aggregate relay states; no per-phase trips are invented.
source="unavailable: exact run relay parameters were not supplied"; R=[];
if isfield(info.controls,'relayParameters'),R=info.controls.relayParameters;source="info.controls.relayParameters";
elseif isfield(info,'relayParameters'),R=info.relayParameters;source="info.relayParameters";end
rows=cell(19,11);relays=["GEN51" "GSUT51" "GEN51N" "87G" "87T" "87B" "87L"];
sensorKeys=["genTerminal" "gsutHV" "neutral" "genInner-genTerminal" ...
    "compensated_gsutLV-gsutHV" "busIn-busOut-gatHV" "lineLocal-lineRemote"];
I=cell(19,1);
for k=1:19
    base=(k-1)*12;I{k}=complex(d.data(:,base+(7:9)),d.data(:,base+(10:12)));
end
operating=cell(7,1);thresholds=cell(7,1);
if ~isempty(R)
    keys=["genTerminal" "gsutHV" "neutral"];
    for r=1:3
        operating{r}=abs(I{find(sensors==keys(r),1)});
        thresholds{r}=repmat(R.pickup_A(r),size(operating{r}));
    end
    lv=I{3};lv=R.lvToHv*[lv(:,1)-lv(:,2) lv(:,2)-lv(:,3) lv(:,3)-lv(:,1)]/sqrt(3);
    hv=I{4}-mean(I{4},2);
    differential={I{1}-I{2},lv-hv,I{5}-I{6}-I{7},I{8}-I{9}};
    restraint={abs(I{1})+abs(I{2}),abs(lv)+abs(hv), ...
        abs(I{5})+abs(I{6})+abs(I{7}),abs(I{8})+abs(I{9})};
    for r=4:7
        k=r-3;b=R.restraintFactor*restraint{k};
        operating{r}=abs(differential{k});
        thresholds{r}=max(R.pickup_A(r),R.slope1(k)*min(b,R.knee_A(k)) ...
            +R.slope2(k)*max(b-R.knee_A(k),0));
    end
end
row=0;
for r=1:7
    phaseCount=3;if r==3,phaseCount=1;end
    for p=1:phaseCount
        row=row+1;time=NaN;secondary=NaN;setting=NaN;threshold=NaN;ratio=NaN;
        status="exact_run_relay_parameters_unavailable";
        phase=string(char('A'+p-1));if r==3,phase="neutral";end
        quantity="phase_current";if r==3,quantity="physical_neutral_current";
        elseif r>3,quantity="compensated_differential_current";end
        if ~isempty(R)
            ratio=R.ctRatio(r);setting=R.pickupSecondary_A(r);
            primary=operating{r}(:,p);limit=thresholds{r}(:,p);
            [time,index,status]=firstActive(d.time,primary>limit,.020);
            if ~isnan(index),secondary=primary(index)/ratio;threshold=limit(index)/ratio;end
            mask=field(S,'relayMask',true(1,7));
            if ~logical(field(S,'protectionEnabled',true))||~mask(r)
                if isnan(time),status="threshold_not_crossed_relay_disabled";
                else,status="threshold_crossed_relay_disabled";end
            end
        end
        rows(row,:)={relays(r),phase,sensorKeys(r),quantity,ratio,setting,time,secondary,threshold,status,source};
    end
end
T=cell2table(rows,'VariableNames',{'Relay','Phase','Current_sensor_or_zone','Operating_quantity','CT_ratio', ...
    'Secondary_pickup_setting_A','Measured_threshold_crossing_s', ...
    'Secondary_operating_current_at_crossing_A','Secondary_threshold_at_crossing_A', ...
    'Status','Parameter_source'});
end

function [time,index,status]=firstActive(t,active,start)
index=find(t>=start & active,1);
if isempty(index),index=NaN;time=NaN;status="not_observed";
else,time=t(index);status="observed";
    if index==find(t>=start,1),status="already_active_at_reporting_start";end
end
end

function value=field(s,name,fallback)
if isfield(s,name),value=s.(name);else,value=fallback;end
end
