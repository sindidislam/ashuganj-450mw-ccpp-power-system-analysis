function build_dashboard(varargin)
%BUILD_DASHBOARD Generate self-contained animated HTML dashboard (Rev2).
% Panels: (1) power-flow animation P1A..P1G, (2) fault+trip timeline F1..F9,
% (3) voltage-recovery envelope labelled ILLUSTRATIVE (no machine model in
% scope; H=5.287 shown for context), (4) DC battery discharge vs autonomy.
% Data baked from rev2/results/*.csv. No external files needed to view.
% Usage: build_dashboard() writes rev2/plots/dashboard.html
p=inputParser; addParameter(p,'Write',true); parse(p,varargin{:});
here=fileparts(mfilename('fullpath'));
root=fileparts(here);
T1=readtable(fullfile(root,'results','phase1_system_summary.csv'),'FileType','text');
T2=readtable(fullfile(root,'results','phase2_fault_currents.csv'),'FileType','text');
T3=readtable(fullfile(root,'results','phase2_breaker_duty.csv'),'FileType','text');

% ---- bake JSON ----
lfRows={};
base=~startsWith(T2.CaseID,'S');
for k=1:height(T1)
  lfRows{end+1}=sprintf('{"id":"%s","Pgen":%.1f,"Pexp":%.2f,"V2":%.4f,"V11":%.4f,"Ploss":%.2f}', ...
    T1.CaseID{k},T1.Pgen_MW(k),T1.Pexport_MW(k),T1.V_B02_pu(k),T1.V_B11_pu(k),T1.Ploss_MW(k)); %#ok<AGROW>
end
fRows={};
Fb=T2(base,:);
for k=1:height(Fb)
  fRows{end+1}=sprintf(['{"id":"%s","bus":"%s","type":"%s","Isym":%.2f,"Ipeak":%.1f,"XR":%.1f,' ...
    '"MVA":%.0f,"Igen":%.2f,"Igrid":%.2f,"Vmin":%.4f}'],Fb.CaseID{k},Fb.Bus{k}, ...
    Fb.FaultType{k},Fb.Isym_kA(k),Fb.Ipeak_kA(k),Fb.XR_pos(k),Fb.FaultMVA(k), ...
    Fb.Igen_kA_22kV(k),Fb.Igrid_kA_230kV(k),Fb.Vfault_min_pu(k)); %#ok<AGROW>
end
dRows={};
for k=1:height(T3)
  dRows{end+1}=sprintf('{"brk":"%s","I":%.2f,"W":%.0f,"margin":%.2f,"v":"%s"}', ...
    T3.Breaker{k},T3.I_kA(k),T3.Withstand_kA_B(k),T3.Margin_kA(k),T3.Verdict{k}); %#ok<AGROW>
end
jsonLF=['[' strjoin(lfRows,',') ']'];
jsonF=['[' strjoin(fRows,',') ']'];
jsonD=['[' strjoin(dRows,',') ']'];

H=fileread(fullfile(here,'dashboard_template.html'));
H=strrep(H,'%DATA_LF%',jsonLF);
H=strrep(H,'%DATA_F%',jsonF);
H=strrep(H,'%DATA_D%',jsonD);
assert(isempty(strfind(H,'%DATA_')),'unfilled placeholder');
out=fullfile(root,'plots','dashboard.html');
fid=fopen(out,'w'); fprintf(fid,'%s',H); fclose(fid);
fprintf('Wrote %s (%d bytes)\n',out,numel(H));
end
