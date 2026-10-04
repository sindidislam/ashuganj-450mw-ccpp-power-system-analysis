function test_phase2_fault()
%TEST_PHASE2_FAULT TDD checks for Phase 2 fault engine (Rev2 Sep-10 truth).
% Invoke: cd rev2; addpath data tests; test_phase2_fault()
% Network: 3-node Thevenin (B01,B02,B03); machines/grid as shunts to ground
% (classical shorted-source model). GSUT YNd1 blocks Z0 B01<->B02.
% Checks: Y012 dims/symmetry; LG I1=I2=I0 & Va=0 & Ia=3I0; LL I0=0,Ia=0,Ib=-Ic,
% Vb=Vc=0; LLL balanced & V=0; LLG Vb=Vc=0; IEC kappa unit value.
fprintf('--- test_phase2_fault ---\n');

S = seq_networks('Xdpp','sat','grid_k',1.0,'line_k',1.0,'gridZ0_k',1.0);
assertEq(size(S.Y1),[3 3],'Y1 3x3');
assertEq(size(S.Y2),[3 3],'Y2 3x3');
assertEq(size(S.Y0),[3 3],'Y0 3x3');
assertLt(norm(S.Y1-S.Y1.',inf),1e-9,'Y1 symmetric');
assertLt(norm(S.Y2-S.Y2.',inf),1e-9,'Y2 symmetric');
assertLt(norm(S.Y0-S.Y0.',inf),1e-9,'Y0 symmetric');
assertTrue(all(isfinite(S.Y1(:))),'Y1 finite');
assertTrue(all(isfinite(S.Y0(:))),'Y0 finite');
% GSUT delta blocks zero-seq B01<->B02: Y0(1,2) must be ~0
assertLt(abs(S.Y0(1,2)),1e-12,'YNd1 Z0 block B01-B02');
% gen Z0 shunt at B01, GSUT Z0 shunt at B02
assertTrue(abs(S.Y0(1,1))>1e-6,'gen Z0 at B01');
assertTrue(abs(S.Y0(2,2))>1e-6,'GSUT Z0 shunt at B02');
% Zbus available and finite
assertTrue(all(isfinite(S.Zbus1(:))),'Zbus1 finite');
assertTrue(all(isfinite(S.Zbus0(:))),'Zbus0 finite');
fprintf('PASS seq network topology\n');

% IEC kappa unit check (IEC 60909): k=1.02+0.98*exp(-3/(X/R)))
k14 = iec_kappa(14);
assertLt(abs(k14-1.8106),0.005,'kappa(14)~1.81');
k2 = iec_kappa(2);
assertTrue(k14>k2,'kappa rises with X/R');
fprintf('PASS iec_kappa\n');

R = run_phase2_fault('Write',false);
assertEq(numel(R.res),9,'9 base cases');
for k = 1:numel(R.res)
  r = R.res(k);
  Ibase = 100/(sqrt(3)*r.Vnom_kV); % kA base (100MVA)
  I0=r.I0; I1=r.I1; I2=r.I2; Iabc=r.Iabc_kA; Vf=r.Vabc_fault_pu;
  switch r.type
    case 'LG'
      assertLt(abs(I1-I2)/max(abs(I1),eps),1e-6,tname(r,'LG I1=I2'));
      assertLt(abs(I1-I0)/max(abs(I1),eps),1e-6,tname(r,'LG I1=I0'));
      assertLt(abs(Iabc(1)-3*I0*Ibase)/max(abs(Iabc(1)),eps),1e-6,tname(r,'LG Ia=3I0'));
      assertLt(abs(Vf(1)),1e-6,tname(r,'LG Va=0'));
    case 'LL'
      assertLt(abs(I0)/max([abs(I1),abs(I2),eps]),1e-6,tname(r,'LL I0=0'));
      assertLt(abs(Iabc(2)+Iabc(3))/max(abs(Iabc(2)),eps),1e-6,tname(r,'LL Ib=-Ic'));
      assertLt(abs(Iabc(1))/max(abs(Iabc(2)),eps),1e-6,tname(r,'LL Ia=0'));
      assertLt(abs(Vf(2)-Vf(3)),1e-6,tname(r,'LL Vb=Vc'));
    case 'LLL'
      assertLt(abs(I2)/max(abs(I1),eps),1e-9,tname(r,'LLL I2=0'));
      assertLt(abs(I0)/max(abs(I1),eps),1e-9,tname(r,'LLL I0=0'));
      m=mean(abs(Iabc)); assertLt(max(abs(abs(Iabc)-m))/m,1e-9,tname(r,'LLL balanced'));
      assertLt(max(abs(Vf)),1e-6,tname(r,'LLL V=0'));
    case 'LLG'
      assertLt(abs(Vf(2)-Vf(3)),1e-9,tname(r,'LLG Vb=Vc'));
      assertLt(max(abs(Vf(2:3))),1e-6,tname(r,'LLG Vb=Vc=0 bolted'));
  end
  assertTrue(isfinite(r.Isym_kA) && r.Isym_kA>0,'Isym positive finite');
  assertTrue(r.Ipeak_kA>=sqrt(2)*r.Isym_kA,'Ipeak>=sqrt2*Isym');
  assertTrue(r.FaultMVA>0,'FaultMVA positive');
  assertTrue(isfinite(r.Igen_kA) && isfinite(r.Igrid_kA),'contributions finite');
end
fprintf('PASS %d fault cases symmetries\n',numel(R.res));

% sens dims: 2 bus-types {LLL@B02,LG@B02} x Xdpp{ sat,unsat } x grid_k{0.7,1,1.5} x line_k{0.8,1,1.2} = 36
assertEq(numel(R.sens),36,'sens 36 rows');
fprintf('PASS sens dimensions\n');

% duty table present, margins consistent
assertTrue(numel(R.duty)>=4,'duty rows');
for k=1:numel(R.duty)
  d=R.duty(k);
  assertLt(abs(d.margin_kA-(d.Withstand_kA-d.I_kA)),1e-9,'margin consistent');
end
fprintf('PASS breaker duty table\n');
fprintf('ALL test_phase2_fault CHECKS PASSED\n');
end

function s=tname(r,what), s=sprintf('%s %s@%s',what,r.type,r.bus); end
function assertEq(a,b,msg), if ~isequal(a,b), error('FAIL %s: got %s want %s',msg,mat2str(a),mat2str(b)); end, end
function assertLt(a,b,msg), if ~(a<b), error('FAIL %s: %.3g !< %.3g',msg,a,b); end, end
function assertTrue(c,msg), if ~c, error('FAIL %s',msg); end, end

