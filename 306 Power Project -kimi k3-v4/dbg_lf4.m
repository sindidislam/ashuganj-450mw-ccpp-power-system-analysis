addpath('matlab/analysis'); addpath('matlab/studies'); addpath('matlab/build');
run('matlab/ashuganj_setup.m');
D = ashuganj_master_data();
C = D.operating_profiles(1);
info = build_ashuganj_main(C.ID, 'Quiet', true, 'Backup', false, 'Save', false);
LF = power_loadflow('-v2', info.model, 'solve');
disp('Has line:'); disp(isfield(info.zones.grid, 'line'));
if isfield(info.zones.grid, 'line')
    hZgrid = get_param(info.zones.grid.br, 'Handle');
    zb = [];
    for i=1:numel(LF.bus)
        b = LF.bus(i).blocks;
        if any(abs(b(:) - hZgrid) < 1e-9)
            zb(end+1) = i;
        end
    end
    disp('zb length:'); disp(numel(zb));
    disp('zb values:'); disp(zb);
end
% Also print buses connected to line
hline = get_param(info.zones.grid.line, 'Handle');
zline = [];
for i=1:numel(LF.bus)
    b = LF.bus(i).blocks;
    if any(abs(b(:) - hline) < 1e-9)
        zline(end+1) = i;
    end
end
disp('zline values:'); disp(zline);
bdclose('all');
