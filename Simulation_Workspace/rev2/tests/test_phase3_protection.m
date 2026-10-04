function test_phase3_protection()
%TEST_PHASE3_PROTECTION TDD checks for Phase 3 OC/EF coordination (Rev2).
% Rules (master §21, all C): pickup=1.2xFL; IEC-SI; TMS start 0.2 (OC) /
% 0.15 (EF); grading margin 0.3s; EF pickup 0.2A sec; CT tap next standard
% above 1.25xFL from {400,800,1600}.
fprintf('--- test_phase3_protection ---\n');
% IEC-SI curve unit: t = TMS*0.14/((I/Is)^0.02-1)
t = iec_si(0.2,20);
assertLt(abs(t-0.4535),0.002,'iec_si(0.2,20)~0.454s');
assertTrue(iec_si(0.2,100)<iec_si(0.2,10),'curve falls with current');
fprintf('PASS iec_si\n');

R = run_phase3_protection('Write',false);
assertTrue(numel(R.relays)>=4,'OC relays');
assertTrue(numel(R.ef)>=1,'EF relays');
assertTrue(numel(R.coord)>=3,'coord pairs');
for k=1:numel(R.relays)
  r=R.relays(k);
  assertLt(abs(r.pickup_A-1.2*r.FL_A),1e-6*r.FL_A,'pickup=1.2xFL');
  assertTrue(r.CT>=1.25*r.FL_A,'CT>=1.25xFL');
  assertTrue(ismember(r.CT,[400 800 1600]),'CT standard tap');
  sens=r.minFault_A/r.pickup_A;
  wantPass=sens>=2;
  assertTrue(strcmp(r.sensVerdict,tern(wantPass,'PASS','REVIEW'))==1,'sensitivity verdict consistent');
end
fprintf('PASS relay pickup/CT/sensitivity\n');
for k=1:numel(R.coord)
  c=R.coord(k);
  wantPass=c.margin_s>=0.3-1e-9;
  assertTrue(strcmp(c.verdict,tern(wantPass,'PASS','REVIEW'))==1,'grading verdict consistent');
end
fprintf('PASS coordination verdicts (%d pairs)\n',numel(R.coord));
assertTrue(isfield(R,'diff'),'diff settings present');
fprintf('ALL test_phase3_protection CHECKS PASSED\n');
end

function assertLt(a,b,msg), if ~(a<b), error('FAIL %s: %.4g !< %.4g',msg,a,b); end, end
function assertTrue(c,msg), if ~c, error('FAIL %s',msg); end, end
function s=tern(c,a,b), if c, s=a; else, s=b; end, end
