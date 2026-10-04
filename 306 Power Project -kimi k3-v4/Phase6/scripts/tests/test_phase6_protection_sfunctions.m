function test_phase6_protection_sfunctions()
%TEST_PHASE6_PROTECTION_SFUNCTIONS Compile, simulate, pack/unpack and reset.
addpath(fileparts(fileparts(mfilename('fullpath'))));
assert(exist('phase6_relay_sfun','file')==2 && exist('phase6_dc_sfun','file')==2, ...
    'phase6:missingWrappers','Measured relay/DC Level-2 wrappers must exist.');
R=phase6_relay_parameters(); D=phase6_dc_parameters();
S=struct('protectionEnabled',true,'relayMask',true(1,7), ...
    'batteryAvailable',true,'chargerAvailable',false, ...
    'dcLossTime_s',.002,'dcRestoreTime_s',.004);
mdl='P6_PROTECTION_SFUNCTION_TEST';
if bdIsLoaded(mdl), close_system(mdl,0); end
new_system(mdl); cleanup=onCleanup(@()close_system(mdl,0)); %#ok<NASGU>
set_param(mdl,'Solver','FixedStepDiscrete','FixedStep','.001','StopTime','.006');
w=get_param(mdl,'ModelWorkspace');
assignin(w,'R',R); assignin(w,'D',D); assignin(w,'S',S);
packed=normal_packed_currents(); assignin(w,'packed',packed);
add_block('simulink/Sources/Constant',[mdl '/Sensors'],'Value','packed');
add_block('simulink/Sources/Constant',[mdl '/Valid'],'Value','1');
add_block('simulink/Sources/Constant',[mdl '/AC'],'Value','1');
add_block('simulink/Sources/Constant',[mdl '/TripDemand'],'Value','1');
add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function',[mdl '/Relay'], ...
    'FunctionName','phase6_relay_sfun','Parameters','R,S');
add_block('simulink/User-Defined Functions/Level-2 MATLAB S-Function',[mdl '/DC'], ...
    'FunctionName','phase6_dc_sfun','Parameters','D,S');
add_block('simulink/Sinks/To Workspace',[mdl '/RelayDiag'],'VariableName','relayDiag','SaveFormat','Array');
add_block('simulink/Sinks/To Workspace',[mdl '/RelayRequest'],'VariableName','relayRequest','SaveFormat','Array');
add_block('simulink/Sinks/To Workspace',[mdl '/DCDiag'],'VariableName','dcDiag','SaveFormat','Array');
add_line(mdl,'Sensors/1','Relay/1'); add_line(mdl,'Valid/1','Relay/2');
add_line(mdl,'AC/1','DC/1'); add_line(mdl,'TripDemand/1','DC/2');
add_line(mdl,'Relay/1','RelayDiag/1'); add_line(mdl,'Relay/2','RelayRequest/1');
add_line(mdl,'DC/1','DCDiag/1');
set_param(mdl,'SimulationCommand','update');
out=sim(mdl,'ReturnWorkspaceOutputs','on');
rd=out.get('relayDiag'); rr=out.get('relayRequest'); dc=out.get('dcDiag');
assert(size(rd,2)==43 && size(rr,2)==6 && size(dc,2)==12);
assert(~any(rr(:)) && ~any(rd(end,1:14)),'Packed normal currents must restrain.');
assert(abs(rd(end,29)-.6)<1e-9 && max(rd(end,32:35))<1e-8);
assert(dc(2,1)>105 && dc(2,2)>0 && dc(2,12)==2000,'Battery must energize the trip pulse.');
assert(any(dc(:,1)==0 & dc(:,10)==1),'Timed total DC loss must inhibit trips.');
assert(dc(end,1)>105 && dc(end,6)==1,'DC restoration must recover supply.');

% Physical internal current imbalance operates 87G through the packed bus.
packed(7)=packed(7)+10000; assignin(w,'packed',packed);
S.dcLossTime_s=inf; S.dcRestoreTime_s=inf; assignin(w,'S',S);
set_param(mdl,'StopTime','.050');
out=sim(mdl,'ReturnWorkspaceOutputs','on');
rd=out.get('relayDiag'); rr=out.get('relayRequest');
assert(rd(end,11)==1 && isequal(rr(end,:),[1 1 0 0 0 1]));

% A second simulation must not inherit the first simulation's trip latch.
S.relayMask=false(1,7); assignin(w,'S',S);
out=sim(mdl,'ReturnWorkspaceOutputs','on'); rr=out.get('relayRequest');
assert(~any(rr(:)),'DWork trip state must reset and honor the relay mask.');
fprintf('PHASE6_PROTECTION_SFUNCTIONS_PASS: compile, sensor mapping, trip, DC window, reset.\n');
end

function packed=normal_packed_currents()
phasor=@(v)v*[1 exp(-1i*2*pi/3) exp(1i*2*pi/3)];
I=zeros(19,3); I(1,:)=phasor(9000); I(2,:)=I(1,:); I(3,:)=I(1,:);
I(4,:)=phasor(9000*22/230)*exp(1i*pi/6); I(5,:)=I(4,:);
I(7,:)=phasor(40)*exp(1i*pi/6); I(6,:)=I(5,:)-I(7,:);
I(8,:)=I(6,:); I(9,:)=I(8,:);
packed=zeros(228,1);
for k=1:19
    idx=(k-1)*12;
    packed(idx+(7:9))=real(I(k,:)); packed(idx+(10:12))=imag(I(k,:));
end
end
