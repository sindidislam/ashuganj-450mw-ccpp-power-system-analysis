% Recompute Simulink-vs-engine verdicts from saved Sim values + fresh engine CSV (no re-sim).
root='G:/Other computers/My Computer (2)/Level 3 Term 1/306 Power Project - opencode';
T2=readtable(fullfile(root,'rev2','results','phase2_fault_currents.csv'),'FileType','text');
C=readtable(fullfile(root,'rev2','results','phase2_simulink_check.csv'),'FileType','text');
fid=fopen(fullfile(root,'rev2','results','phase2_simulink_check.csv'),'w');
fprintf(fid,'CaseID,Bus,FaultType,Sim_Igrid_kA,Eng_Igrid_kA,ErrG_pct,Sim_Vmin_pu,Eng_Vmin_pu,ErrV_pu,Sim_IgridPk_kA,Eng_IgridPk_kA,ErrP_pct,Verdict\n');
for k=1:height(C)
  bus=C.Bus{k}; typ=C.FaultType{k};
  if strcmp(C.Verdict{k},'STALLED-engine-only')
    fprintf(fid,'%s,%s,%s,STALLED,STALLED,,STALLED,STALLED,,STALLED,STALLED,,STALLED-engine-only\n',C.CaseID{k},bus,typ);
    fprintf('%s-%s: STALLED (solver wall) -> engine-only\n',bus,typ);
    continue;
  end
  er=find(strcmp(T2.Bus,bus)&strcmp(T2.FaultType,typ)&startsWith(T2.CaseID,'F'),1);
  engG=T2.Igrid_kA_230kV(er); engV=T2.Vfault_min_pu(er); engP=T2.Ipeak_kA(er)*(engG/T2.Isym_kA(er));
  simG=C.Sim_Igrid_kA(k); vmin=C.Sim_Vmin_pu(k); pk=C.Sim_IgridPk_kA(k);
  eG=100*(simG-engG)/max(engG,0.5); eV=vmin-engV; eP=100*(pk-engP)/max(engP,1);
  v='PASS'; if abs(eG)>7||abs(eV)>0.05||abs(eP)>15, v='REVIEW'; end
  fprintf(fid,'%s,%s,%s,%.2f,%.2f,%+.2f,%.3f,%.3f,%+.3f,%.1f,%.1f,%+.2f,%s\n',C.CaseID{k},bus,typ,simG,engG,eG,vmin,engV,eV,pk,engP,eP,v);
  fprintf('%s-%s: Igrid %.2f vs %.2f (%+.1f%%) Vmin %+.3f pk %.1f vs %.1f (%+.1f%%) %s\n',bus,typ,simG,engG,eG,eV,pk,engP,eP,v);
end
fclose(fid);
fprintf('verdicts recomputed\n');
