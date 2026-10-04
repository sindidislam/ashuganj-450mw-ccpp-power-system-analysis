addpath(fullfile('..','..','scripts'));
setup_phase6_workspace();
fprintf('MATLAB=%s\n',version);
disp(ver('Simulink')); disp(ver('sps'));
B=sps_blocks();
probe='P6_BLOCK_PROBE';
if bdIsLoaded(probe),close_system(probe,0);end
new_system(probe); load_system('sps_lib');
keys={'syncmachine','breaker','fault','vimeas','pisection','source','tx2','load','powergui'};
for idx=1:numel(keys)
    key=keys{idx}; b=add_block(B.(key),[probe '/' key]);
    fprintf('\nBLOCK %s %s\n',key,get_param(b,'MaskType'));
    d=get_param(b,'DialogParameters');
    names=fieldnames(d);
    for j=1:numel(names)
        val=get_param(b,names{j});
        if ischar(val), fprintf('%s=%s\n',names{j},val); end
    end
    disp(get_param(b,'PortHandles'));
end
close_system(probe,0);
fprintf('\nLOADFLOW FUNCTIONS\n');
which power_loadflow -all
help power_loadflow
