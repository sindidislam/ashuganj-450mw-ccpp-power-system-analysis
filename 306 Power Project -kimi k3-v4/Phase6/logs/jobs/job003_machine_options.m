B=sps_blocks(); probe='P6_MACHINE_OPTIONS';new_system(probe);
b=add_block(B.syncmachine,[probe '/Machine']);
set_param(b,'RotorType','Round','dAxisTimeConstants','Open-circuit','qAxisTimeConstants','Open-circuit','SetSaturation','off','MeasurementBus','on');
names=get_param(b,'MaskNames'); values=get_param(b,'MaskValues'); vis=get_param(b,'MaskVisibilities'); prompts=get_param(b,'MaskPrompts');
for k=1:numel(names),fprintf('%s | visible=%s | %s | %s\n',names{k},vis{k},prompts{k},values{k});end
set_param(probe,'SimulationCommand','update');
close_system(probe,0);
