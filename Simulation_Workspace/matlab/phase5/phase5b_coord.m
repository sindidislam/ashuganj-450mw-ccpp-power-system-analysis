function [M,G,C]=phase5b_coord(devices,Ti,B)
% Preserve the IEC engine; correct physical current bases and scope before use.
if nargin<3, B=phase5b_cached_branches(Ti); end
C=phase5b_physical_currents(Ti,B);
Tc=Ti;
Tc.leg_GEN_kA=C.GEN_phase_A/1000;
Tc.leg_GSUT_HV_kA=C.GSUT_HV_phase_A/1000;
% Compatibility slots to the v1 engine: Q0 is the conditional transformer bay.
Tc.leg_GRID_kA=C.Q0_phase_A/1000;
Tc.leg_LINE_total_kA=C.Q0_phase_A/1000;
Tc.leg_NER_earth_kA=C.GEN_neutral_A/3000;
Tc.Iseq0_kA=C.GEN_neutral_A/3000;
[M,G]=phase5_coord(devices,Tc);
M.scope=repmat({'PRIMARY'},height(M),1);
q=contains(M.downstream,'Q0') | contains(M.upstream,'Q0');
M.scope(q)={'CONDITIONAL'};
cp=q & strcmp(M.verdict,'PASS'); M.verdict(cp)={'CONDITIONAL-PASS'};
no=contains(M.verdict,'NOT DETERMINABLE');
M.verdict(no)={'NO-PAIR'};
for i=1:height(M)
 M.reason{i}=strrep(M.reason{i},'SOURCE-BACKED','DERIVED');
 M.reason{i}=strrep(M.reason{i},'LINE_Q9-proxy-leg_LINE_total_kA','Q0-transformer-bay-GSUT_HV-physical-230kV');
 M.reason{i}=strrep(M.reason{i},'GRID_Q-leg_GRID_kA','Q0-transformer-bay-GSUT_HV-physical-230kV');
 if no(i)
  M.reason{i}='NO-PAIR: no upstream residual-current protection is modeled across the YNd1 delta; downstream neutral detection is reported separately.';
 end
 if strcmp(M.verdict{i},'NO-PAIR') && strcmp(M.downstream{i},'GIS-Q0-51')
  M.reason{i}='NO-PAIR: Q0 is the last modeled overcurrent backup; remote line protection is represented separately by its scheme proxy.';
 end
 M.reason{i}=[M.reason{i} '; physical CT-base conversion; CTI=0.30 s study criterion'];
end
M.provenance=repmat({'DERIVED:locked Phase-4 branch phasors on physical CT voltage base; GEN CT VERIFIED; GSUT CT ENGINEERING_ASSUMPTION; Q0 mapping CONDITIONAL_ASSUMPTION'},height(M),1);
M.pair_evaluable=isfinite(M.margin_s);
G.verdict=M.verdict; G.reason=M.reason; G.provenance=M.provenance; G.scope=M.scope;
G.pair_evaluable=M.pair_evaluable;
end
