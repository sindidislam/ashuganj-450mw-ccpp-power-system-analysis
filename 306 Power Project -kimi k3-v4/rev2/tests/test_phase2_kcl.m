function test_phase2_kcl()
%TEST_PHASE2_KCL Kirchhoff closure at each faulted node (catches
% prefault/topology mismatch, e.g. wrong Vpre reference node).
% Conventions (all into the faulted node, pu on 100MVA):
%  F1 B01: Igen + Igsut(series, B02->B01) - If = ~0 (aux unmodeled, <1%)
%  F5 B02: Igsut(B01->B02) - Iline(2->3) - If = 0 (no shunt at B02)
%  F9 B03: Iline(2->3) + Igrid(E->3) - If = 0 (no shunt at B03)
fprintf('--- test_phase2_kcl ---\n');
R = run_phase2_fault('Write',false);
a = exp(1j*2*pi/3); A=[1 1 1; 1 a^2 a; 1 a a^2];
Ib22=100/(sqrt(3)*22); Ib230=100/(sqrt(3)*230); % kA bases (100MVA)
r = R.res(1); % F1-B01-LLL
Ig=(A\r.Igen_kA_ph)/Ib22; Is=(A\r.IgsutHV_kA_ph)/Ib230; If=(A\r.Iabc_kA)/Ib22;
res1=max(abs(Ig-Is-If)); fprintf('F1-B01-LLL residual %.4f pu\n',res1);
assert(res1<0.20,'KCL FAIL F1'); % aux 12+j5 (0.13pu) unmodeled in 3-node net
r = R.res(5); % F5-B02-LLL
Is=(A\r.IgsutHV_kA_ph)/Ib230; Il=(A\r.Iline_kA_ph)/Ib230; If=(A\r.Iabc_kA)/Ib230;
res5=max(abs(Is-Il-If)); fprintf('F5-B02-LLL residual %.4f pu\n',res5);
assert(res5<0.05,'KCL FAIL F5'); % aux bleed via P1A Vpre; catches 10pu+ blunders
r = R.res(9); % F9-B03-LLL
Il=(A\r.Iline_kA_ph)/Ib230; Ie=(A\r.Igrid_kA_ph)/Ib230; If=(A\r.Iabc_kA)/Ib230;
res9=max(abs(Il+Ie-If)); fprintf('F9-B03-LLL residual %.4f pu\n',res9);
assert(res9<0.05,'KCL FAIL F9'); % same
fprintf('PASS kcl\n');
end

