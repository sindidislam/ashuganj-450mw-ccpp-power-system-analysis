function [np,nf]=test_phase5b_validate()
% Validation reports measured numerical residuals, not commissioned proof.
T=t_case('test_phase5b_validate'); V=phase5b_validate(); L=V.legs;
expected=[{'R0'},arrayfun(@(k)sprintf('B%02d',k),1:13,'UniformOutput',false)];
T=T.chk(isequal({L.id},expected),'validation preserves R0 and thirteen distinct engineering checks');
T=T.chk(all([L.pass])&&all(isfinite([L.residual]))&&all([L.residual]>=0),'all numerical validation legs pass with finite residuals');
T=T.chk(all(arrayfun(@(x)islogical(x.pass)&&isscalar(x.pass),L))&&all(strlength(string({L.note}))>0),'each leg has an explicit logical outcome and explanation');
Ti=phase5_import(ashuganj_root());
a=strcmp(Ti.caseID,'LF360_GAT_OUT')&strcmp(Ti.fault_location,'F3')&strcmp(Ti.fault_type,'LLL');
b=strcmp(Ti.caseID,'LF360_GAT_OUT')&strcmp(Ti.fault_location,'F1')&strcmp(Ti.fault_type,'LG');
res=max(abs([Ti.I_primary_kA(a)-50.5308851865359,Ti.I_primary_kA(b)-.00727200442799167]));
T=T.chk(res<1e-9&&abs(L(1).residual-res)<1e-12,'R0 measured residual matches both frozen fault anchors');
R=phase5b_registry(); [M,~,C]=phase5b_coord(R.devices,Ti);
T=T.chk(all(abs(C.GSUT_HV_phase_A-C.GSUT_HV_fault_base_A.*C.source_voltage_kV/230)<1e-8),'physical HV relay current converts from each fault-location base');
err=0; used=0;
for i=1:height(M)
 for side={'down','up'}
  s=side{1};if strcmp(s,'down'),id=M.downstream{i};else,id=M.upstream{i};end
  j=find(strcmp({R.devices.device_id},id),1);got=M.(['t_' s '_s'])(i);
  if isempty(j)||~isfinite(got),continue;end
  d=R.devices(j); ratio=M.(['I_' s '_A'])(i)/(d.pickup_A/d.ct_ratio);
  err=max(err,abs(got-.14*d.tms/(ratio^.02-1)));used=used+1;
 end
end
T=T.chk(used>0&&err<1e-10&&abs(L(strcmp({L.id},'B11')).residual-err)<1e-12,'finite coordination times independently match the IEC SI equation');
q=contains(M.downstream,'Q0')|contains(M.upstream,'Q0');
T=T.chk(all(strcmp(M.scope(q),'CONDITIONAL'))&&~any(strcmp(M.verdict(q),'PASS')),'Q0 pairs cannot acquire an unconditional pass');
T=T.chk(phase5b_verify_baseline()>0,'protected upstream files retain their recorded byte identity');
try,phase5b_validate(1);T=T.chk(false,'validator rejects arguments');catch ME,T=T.chk(strcmp(ME.identifier,'phase5b_validate:args'),'validator rejects arguments');end
[np,nf]=T.done();
end
