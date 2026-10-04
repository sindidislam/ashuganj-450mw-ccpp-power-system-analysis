setup_phase6_workspace();
if bdIsLoaded('P6_MACHINE_CIRCUIT'),close_system('P6_MACHINE_CIRCUIT',0);end
srcText=fileread(fullfile(pwd,'job007_machine_snubber.m'));
srcText=strrep(srcText,"lf=power_loadflow(m,'solve');", "set_param([m '/powergui'],'SimulationMode','Discrete','SampleTime','50e-6');set_param(m,'SolverType','Fixed-step','Solver','FixedStepDiscrete','FixedStep','50e-6');lf=power_loadflow(m,'solve');");
srcText=strrep(srcText,"disp(get_param(hgen.Outport,'SignalHierarchy'));", "hh=get_param(hgen.Outport,'SignalHierarchy');disp({hh.Children.SignalName}');");
srcText=strrep(srcText,"'StopTime','0.04'", "'StopTime','0.2'");
eval(srcText);
