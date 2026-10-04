function R=run_phase5b_production(tag,varargin)
% Reproducible final Phase-5 workflow. Upstream archives remain read-only.
if nargin<1, tag='final-engineering'; end
ip=inputParser; addParameter(ip,'overwrite',false); parse(ip,varargin{:});
root=ashuganj_root(); out=fullfile(root,'results','phase5_protection_v2');
if isfolder(out)&&~ip.Results.overwrite, error('phase5b_production:exists','Use overwrite=true for the existing Phase-5 output directory.'); end
phase5b_verify_baseline();
[P,A]=phase5b_parameters(); Rg=phase5b_registry();
writetable(A,fullfile(root,'docs','PHASE5_ASSUMPTIONS.csv'));
writetable(A,fullfile(root,'PHASE5_ASSUMPTIONS.csv'));
Ti=phase5_import(root);
B=phase5b_cached_branches(Ti);
[M,G,C]=phase5b_coord(Rg.devices,Ti,B);
D=phase5b_duty(Ti,[],B);
E=phase5b_effectiveness(Ti,Rg.devices,B);
S=phase5b_sensitivity_v2(Ti,Rg.devices,Rg,B);
V=phase5b_validate();
Tv=table({V.legs.id}',double([V.legs.pass]'),[V.legs.residual]',{V.legs.note}', ...
 repmat({'DERIVED:independent engineering validation'},numel(V.legs),1), ...
 repmat({'PRIMARY'},numel(V.legs),1),'VariableNames',{'leg','pass','residual','note','provenance','scope'});
assert(all(Tv.pass==1),'phase5b_production:validation','Engineering implementation validation failed');
Treg=struct2table(Rg.devices); Treg.scope=Treg.assumption_class;
Treg.actual_installed_value_verified=repmat({'NO'},height(Treg),1);
Ts=settings_table(Rg.devices,A);
Tf=Ti; Tf.provenance=repmat({'DERIVED:locked Phase-4 Ikpp backbone; source currents retained without alteration'},height(Ti),1);
Tf.scope=repmat({'PRIMARY'},height(Ti),1);
Tf.scenario=repmat({'LOCKED-PHASE4-BASELINE'},height(Ti),1);
Tf.source_voltage_kV=C.source_voltage_kV;
Tc=currents_table(C,Rg.devices);
if ~ismember('provenance',D.Properties.VariableNames), D.provenance=D.basis; end
T=struct('registry',Treg,'settings',Ts,'faultInputs',Tf,'relayCurrents',Tc, ...
 'coordMatrix',M,'coordMargins',G,'duty',D,'sensitivity',S,'validation',Tv,'effectiveness',E);
if ~isfolder(out), mkdir(out); end
Stcc=phase5b_tcc(fullfile(out,'plots'),root);
[NP, NF] = run_phase5b_tests();
assert(NF==0,'phase5b_production:tests','Phase-5b tests failed: PASS=%d FAIL=%d',NP,NF);
meta=struct('tag',tag,'testCounts',struct('NP',NP,'NF',NF),'tcc',Stcc);
W=phase5b_writer(out,T,meta);
writetable(A,fullfile(out,'phase5_parameter_values.csv'));
writetable(struct2table(phase5b_zones()),fullfile(out,'phase5_trip_logic.csv'));
Q=phase5b_independent_arithmetic(M);
assert(all(strcmp(Q.verdict,'PASS')),'phase5b_production:arithmetic','Independent arithmetic audit failed');
writetable(Q,fullfile(root,'docs','PHASE5_INDEPENDENT_ARITHMETIC.csv'));
phase5b_final_reports(out,T,P,A,meta);
phase5b_verify_baseline();
phase5b_finalize_manifest(out,meta);
H=phase5b_verify_artifacts(out);
fprintf('run_phase5b_tests() PASS = %d FAIL = %d\n',NP,NF);
fprintf('FINAL ARTIFACTS: %d hashes verified; protected upstream files unchanged.\n',H);
R=struct('dir',out,'NP',NP,'NF',NF,'rowCounts',W.rowCounts,'hashCount',H);
end
function S=settings_table(d,A)
% Current-operated functions retain the familiar wide fields. Other numerical
% relay quantities are in the typed long parameter table, linked by parameter.
ix=find(isfinite([d.pickup_A]));
id={d(ix).device_id}'; pk=[d(ix).pickup_A]'; ct=[d(ix).ct_ratio]';
S=table(id,pk,pk./ct,ct,[d(ix).tms]',{d(ix).curve}',[d(ix).trip_delay_s]', ...
 [d(ix).operate_proxy_s]',{d(ix).provenance}',{d(ix).assumption_class}', ...
 'VariableNames',{'device_id','setting_A_primary','setting_A_secondary','ct_ratio','tms','curve','tdef_s','operate_proxy_s','provenance','scope'});
S.unit=repmat({'A-primary'},height(S),1);
S.basis=S.provenance; S.source=repmat({'docs/PHASE5_ASSUMPTIONS.csv'},height(S),1);
S.validation=repmat({'Numerical study setting; actual installed value unverified'},height(S),1);
S.parameter_table_rows=repmat(height(A),height(S),1);
end
function T=currents_table(C,d)
rows=cell(0,14);
ids={'GEN-51','GEN-51N','GSUT-HV-51','GIS-Q0-51'};
columns={'GEN_phase_A','GEN_neutral_A','GSUT_HV_phase_A','Q0_phase_A'};
i0columns={'GEN_I0_A','GEN_I0_A','GSUT_HV_I0_A','Q0_I0_A'};
for i=1:height(C)
 for j=1:4
  x=d(strcmp({d.device_id},ids{j})); I=C.(columns{j})(i);
  rows(end+1,:)={C.fault_location{i},C.fault_type{i},C.caseID{i},ids{j},'physical-CT', ...
   I,I/1000,x.ct_ratio,I/x.ct_ratio,C.(i0columns{j})(i),'DERIVED:abs(complex Ia+Ib+Ic)/3 on physical branch voltage base', ...
   x.provenance,x.assumption_class,x.vnom_kV}; %#ok<AGROW>
 end
end
T=cell2table(rows,'VariableNames',{'fault_location','fault_type','caseID','device_id','side','I_primary_A', ...
 'I_primary_kA','CT_ratio','I_secondary_A','I0_A','I0_source','provenance','scope','physical_voltage_kV'});
end
