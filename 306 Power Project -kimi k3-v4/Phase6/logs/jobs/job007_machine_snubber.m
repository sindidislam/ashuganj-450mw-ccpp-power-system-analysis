setup_phase6_workspace(); B=sps_blocks(); G=ashuganj_generators(); T=ashuganj_transformers(); t=T(strcmp({T.Name},'GSUT'));
m='P6_MACHINE_CIRCUIT';new_system(m);
add_block(B.powergui,[m '/powergui']);set_param([m '/powergui'],'frequency','50','frequencyindice','50','ErrMax','1e-7');
g=[m '/Machine'];add_block(B.syncmachine,g);
set_param(g,'RotorType','Round','dAxisTimeConstants','Open-circuit','qAxisTimeConstants','Open-circuit','SetSaturation','off','MeasurementBus','on', ...
    'NominalParameters','[458e6 22e3 50]','Reactances1',mat2str([G.Xd G.Xdp G.Xdpp G.Xq G.Xqp G.Xqpp G.Xl],15), ...
    'TimeConstants2',mat2str([G.Td0p_s G.Td0pp_s G.Tq0p_s G.Tq0pp_s],15),'StatorResistance',num2str(G.Ra_pu_machine,15),'Mechanical','[5.287 0 1]','Pref','360e6','BusType','PV');
tx=[m '/Transformer'];add_block(B.tx2,tx);
set_param(tx,'NominalPower','[515e6 50]','Winding1',mat2str([t.V_HV_V t.R1_pu t.L1_pu],15),'Winding2',mat2str([t.V_LV_V t.R2_pu t.L2_pu],15),'Winding1Connection',t.Conn_HV,'Winding2Connection',t.Conn_LV,'Rm',num2str(t.Rm_pu,15),'Lm',num2str(t.Lm_pu,15),'CoreType',t.Model_coretype,'L0',num2str(t.L0_pu,15));
z=[m '/Grid impedance'];add_block(B.series,z);set_param(z,'BranchType','L','Inductance',num2str(2.65581124/(2*pi*50),15));
src=[m '/Grid'];add_block(B.source,src);set_param(src,'NonIdealSource','off','Voltage','230e3','BaseVoltage','230e3','Frequency','50','BusType','swing','InternalConnection','Yg');
hgen=get_param(g,'PortHandles'); htx=get_param(tx,'PortHandles'); hz=get_param(z,'PortHandles'); hs=get_param(src,'PortHandles');
for j=1:3,add_line(m,hgen.RConn(j),htx.RConn(j));add_line(m,htx.LConn(j),hz.LConn(j));add_line(m,hz.RConn(j),hs.RConn(j));end
add_block('simulink/Sources/Constant',[m '/Mechanical power'],'Value','0.79');add_line(m,'Mechanical power/1','Machine/1');
add_block('simulink/Sources/Constant',[m '/Field voltage'],'Value','1.5');add_line(m,'Field voltage/1','Machine/2');
add_block('simulink/Sinks/To Workspace',[m '/Machine measurements'],'VariableName','mData','SaveFormat','Structure With Time');add_line(m,'Machine/1','Machine measurements/1');
set_param(m,'Solver','ode23tb','MaxStep','1e-3','RelTol','1e-5','StopTime','0.04');
sn=[m '/Numerical shunt'];add_block(B.load,sn);set_param(sn,'NominalVoltage','22e3','NominalFrequency','50','ActivePower','10','InductivePower','0','CapacitivePower','0','LoadType','constant Z');hns=get_param(sn,'PortHandles');for j=1:3,add_line(m,hgen.RConn(j),hns.LConn(j));end
lf=power_loadflow(m,'solve');disp(lf);disp(lf.sm);fprintf('IC=%s\nPm=%s Vf=%s\n',get_param(g,'InitialConditions'),get_param([m '/Mechanical power'],'Value'),get_param([m '/Field voltage'],'Value'));
set_param(m,'SimulationCommand','update');
disp(get_param(hgen.Outport,'SignalHierarchy'));
out=sim(m,'ReturnWorkspaceOutputs','on'); disp(out);disp(out.mData);
save(fullfile(fileparts(fileparts(pwd)),'logs','machine_probe.mat'),'lf');
close_system(m,0);
