fprintf('DIAG Vrms=%s genP_MW=%g neutralRMS=%g\n',mat2str(vn,12),genP/1e6,nrms);
fprintf('DIAG machine first=%s last=%s rangeW=%s\n',mat2str(machine(1,:),12),mat2str(machine(end,:),12),mat2str([min(machine(:,1)) max(machine(:,1))],12));
fprintf('DIAG Vfirst=%s Vlast=%s IFirst=%s ILast=%s\n',mat2str(out.probe_genTerminal_V.signals.values(1,:),12),mat2str(out.probe_genTerminal_V.signals.values(end,:),12),mat2str(out.probe_genTerminal_I.signals.values(1,:),12),mat2str(out.probe_genTerminal_I.signals.values(end,:),12));
save(fullfile(paths.phase6,'logs','network_normal_diagnostic.mat'),'out','lf','net','vn','genP','nrms','machine');
