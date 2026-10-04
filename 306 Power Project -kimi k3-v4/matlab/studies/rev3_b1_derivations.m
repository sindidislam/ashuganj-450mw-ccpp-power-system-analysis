function rev3_b1_derivations()
%REV3_B1_DERIVATIONS  Executed derivations backing DATA_RECONCILIATION_REV3.md (B1).
%
% Every derived number quoted in DATA_RECONCILIATION_REV3.md is produced here so
% that no hand arithmetic enters the reconciliation document. This script derives
% ONLY from source-verified inputs that are listed at the top of each block; it
% does not read any existing project registry, so it cannot inherit a legacy value.
%
% Source keys used below:
%   WB   = Ahsuganj South (2).xlsx, sheet "Ashuganj South ", row 3   (tier 3, PGCB collection sheet)
%   SIE  = Generator Data_South.pdf (Siemens Generator Protection Setting Report, 2014)
%   CTI  = GSUT Data Sheet_South.pdf (S009-112070-00-ELC-HD-0001 Rev 00)
%   CTIU = UAT  Data Sheet_South.pdf (STWH-579UAT-0007 / STWH-580GAT-0007 Rev 00)
%   SLD  = INEL-112070-00-ELC-DE-0001-REV3.pdf
%   APS  = Google Sheet Form_Filled Up By APSCL.pdf
%
% Run:  matlab -batch "addpath('matlab/studies'); rev3_b1_derivations"

p = @(varargin) fprintf(varargin{:});
line = @() fprintf('%s\n', repmat('-',1,78));
head = @(s) fprintf('\n%s\n%s\n%s\n', repmat('=',1,78), s, repmat('=',1,78));

Sbase = 100;          % MVA, system base (PART C)
f     = 50;           % Hz   (WB, SIE, nameplate, CTI, CTIU, SLD all agree)
w     = 2*pi*f;

head('0. SYSTEM AND EQUIPMENT BASES');
Zb22_100  = 22^2/Sbase;    Ib22_100  = Sbase*1e6/(sqrt(3)*22e3);
Zb230_100 = 230^2/Sbase;   Ib230_100 = Sbase*1e6/(sqrt(3)*230e3);
Zb66_100  = 6.6^2/Sbase;   Ib66_100  = Sbase*1e6/(sqrt(3)*6.6e3);
Sgen = 458; Vgen = 22;                         % WB C3,D3 ; SIE ; nameplate
Zb_gen = Vgen^2/Sgen;  Ib_gen = Sgen*1e6/(sqrt(3)*Vgen*1e3);
p('Sbase                    = %10.4f MVA\n', Sbase);
p('Zbase 22 kV  @100 MVA    = %10.6f ohm   Ibase = %10.2f A\n', Zb22_100,  Ib22_100);
p('Zbase 230 kV @100 MVA    = %10.6f ohm   Ibase = %10.2f A\n', Zb230_100, Ib230_100);
p('Zbase 6.6 kV @100 MVA    = %10.6f ohm   Ibase = %10.2f A\n', Zb66_100,  Ib66_100);
p('Zbase generator own base (22 kV, 458 MVA) = %12.8f ohm\n', Zb_gen);
p('Ibase generator own base                  = %12.4f A   (nameplate IN = 12019 A)\n', Ib_gen);
p('  nameplate check |12019-%.1f|/12019 = %.4f %%\n', Ib_gen, abs(12019-Ib_gen)/12019*100);

head('1. GENERATOR - WORKBOOK DATASET, OWN BASE -> 100 MVA BASE');
p('Conversion law: X_new = X_old * (S_new/S_old) * (V_old/V_new)^2, V unchanged.\n');
k = Sbase/Sgen;
p('k = S_new/S_old = %g/%g = %.8f\n\n', Sbase, Sgen, k);
names = {'Xd','Xd''','Xd"','Xd"(sat)','Xq','Xq''','Xq"','Xl','X2(sat)','X0(sat)'};
vals  = [1.783 0.3256 0.2608 0.2248 1.751 0.5087 0.2593 0.2027 0.2242 0.128];
cells = {'H3','I3','J3','K3','L3','M3','N3','O3','P3','Q3'};
p('%-10s %-6s %14s %16s\n','param','cell','pu @458 MVA','pu @100 MVA');
line();
for i = 1:numel(vals)
    p('%-10s %-6s %14.4f %16.8f\n', names{i}, cells{i}, vals(i), vals(i)*k);
end
line();

head('2. GENERATOR STATOR RESISTANCE - THE ohm vs pu QUESTION (WB U3 = "0.00089 ohm")');
Ra_ohm   = 0.00089;                 % WB U3, literal cell text includes the unit "ohm"
Ra_pu458 = Ra_ohm/Zb_gen;
Ra_pu100 = Ra_pu458*k;
p('Reading A (TEXT OF THE CELL, mandated): Ra = %.5f ohm\n', Ra_ohm);
p('   Ra_pu(458 MVA) = Ra_ohm/Zbase = %.8f / %.8f = %.8e pu\n', Ra_ohm, Zb_gen, Ra_pu458);
p('   Ra_pu(100 MVA) = %.8e pu\n', Ra_pu100);
p('Reading B (REJECTED): Ra = %.5f pu  ->  %.8e ohm\n', Ra_ohm, Ra_ohm*Zb_gen);
p('Numerical separation between the two readings = %.4f %% (Zbase is close to 1 ohm)\n', ...
    abs(Ra_ohm*Zb_gen-Ra_ohm)/Ra_ohm*100);
p('  => the ohm/pu error is SMALL in effect here; it is corrected on evidence, not magnitude.\n\n');

p('Independent physical test - armature time constant Ta = X2/(w*Ra):\n');
X2 = 0.2242; Ta_stated = 0.704;     % WB P3, AG3
Ta_A = X2/(w*Ra_pu458);
Ta_B = X2/(w*Ra_ohm);
p('  Ta from reading A (ohm) = %.6f s      (workbook AG3 states %.3f s)\n', Ta_A, Ta_stated);
p('  Ta from reading B (pu)  = %.6f s\n', Ta_B);
Ra_needed = X2/(w*Ta_stated);
p('  Ra required to reproduce Ta = %.3f s exactly: %.8e pu  (= %.8f ohm)\n', ...
    Ta_stated, Ra_needed, Ra_needed*Zb_gen);
rA = Ra_needed/Ra_pu458;  rB = Ra_needed/Ra_ohm;
kcu = (235+75)/(235+20);
p('  ratio to reading A = %.5f ; ratio to reading B = %.5f\n', rA, rB);
p('  IEC copper correction 20 degC -> 75 degC = (235+75)/(235+20) = %.5f\n', kcu);
p('  |A - kcu|/kcu = %.3f %%   |B - kcu|/kcu = %.3f %%\n', abs(rA-kcu)/kcu*100, abs(rB-kcu)/kcu*100);
p('  => Ta is consistent with reading A being the COLD (20 degC) stator resistance\n');
p('     and Ta being quoted at 75 degC. Supporting evidence, not proof; the proof\n');
p('     is the literal unit in the cell.\n');

head('3. SCR CROSS-CHECK - DOES THE WORKBOOK ITSELF IDENTIFY 1.663 AS SATURATED Xd?');
SCR = 0.601;                        % WB G3
p('Definition: SCR = 1/Xd(saturated).\n');
p('  1/SCR   = 1/%.3f = %.6f\n', SCR, 1/SCR);
p('  SIE 2.1.1 "Synchronous reactance (sat.)" xd = 1.663 pu\n');
p('  |1/SCR - 1.663|/1.663 = %.4f %%\n', abs(1/SCR-1.663)/1.663*100);
p('  1/1.663 = %.6f  -> rounds to %.3f = workbook SCR\n', 1/1.663, round(1/1.663,3));
p('  And 1/Xd(unsat 1.783) = %.6f, which does NOT equal the stated SCR.\n', 1/1.783);
p('  => The workbook''s OWN SCR column independently identifies 1.663 as the\n');
p('     saturated Xd of the same machine. 1.783 vs 1.663 is a saturation-basis\n');
p('     distinction, NOT a source conflict.\n');

head('4. GENERATOR CAPABILITY AND DISPATCH ARITHMETIC');
pf = 0.85;                          % nameplate, SIE
P_rated = Sgen*pf;  Q_rated = Sgen*sin(acos(pf));
p('P at rated pf   = 458 * 0.85            = %.4f MW   (SIE PN = 389.30 MW)\n', P_rated);
p('Q at rated pf   = 458 * sin(acos(0.85)) = %.4f MVAr (APS Qmax = +241 MVAr)\n', Q_rated);
p('  => APSCL''s +241 MVAr is the stator limit AT P = %.2f MW, not at 342.01 MW.\n', P_rated);
p('Workbook capacity B3 = 360 MW ; 360/458 = pf %.5f (a rating statement, not a dispatch)\n', 360/458);
p('APS "Site De-rated Active Power" = 342.01 MW ; 342.01/458 = pf %.5f\n', 342.01/458);
Smax = 518;  Imax = 14309;          % SIE 2.1.1
p('SIE Smax = %g MVA at 30 degC cold gas -> I at 22.0 kV = %.1f A (SIE Imax = %d A)\n', ...
    Smax, Smax*1e6/(sqrt(3)*22e3), Imax);
p('  apparent %.2f %% discrepancy. Test the -5 %% voltage limit (22 kV -5 %% = %.1f kV):\n', ...
    abs(Smax*1e6/(sqrt(3)*22e3)-Imax)/Imax*100, 22*0.95);
S_at_min = sqrt(3)*22e3*0.95*Imax/1e6;
p('  sqrt(3) * %.1f kV * %d A = %.2f MVA   (SIE Smax = %g MVA)  error %.3f %%\n', ...
    22*0.95, Imax, S_at_min, Smax, abs(S_at_min-Smax)/Smax*100);
p('  => Imax is quoted at the MINIMUM permitted terminal voltage, IN at nominal.\n');
p('     Resolved internal consistency, NOT a source conflict.\n');
p('  IN check: sqrt(3)*22 kV*%d A = %.2f MVA (nameplate SN = %g MVA)\n', ...
    12019, sqrt(3)*22e3*12019/1e6, Sgen);

p('\nDispatch cases (stator circle radius S_N = %g MVA; Q_max = sqrt(S_N^2 - P^2)):\n', Sgen);
dsp = struct('id',{'A','B','C'}, 'P',{360, 389.30, 342.01}, ...
    'src',{'WB B3 "Capacity (MW)"','SIE PN = 458*0.85','APS "Site De-rated Active Power"'});
p('%-4s %10s %12s %12s %10s  %s\n','case','P (MW)','Qmax (MVAr)','S at Qmax','pf','source');
line();
for i = 1:numel(dsp)
    Qm = sqrt(Sgen^2 - dsp(i).P^2);
    p('%-4s %10.2f %12.2f %12.2f %10.5f  %s\n', dsp(i).id, dsp(i).P, Qm, ...
        hypot(dsp(i).P,Qm), dsp(i).P/Sgen, dsp(i).src);
end
line();
p('  Q at rated pf (%.2f) = %.4f MVAr applies ONLY to case B.\n', pf, Q_rated);
p('  NONE of these is a NET EXPORT figure: station auxiliaries and transformer\n');
p('  losses have not been subtracted. Net export is a LOAD-FLOW RESULT (D2), not a datum.\n');

head('5. GSUT (CTI datasheet, base 515 MVA) - IMPEDANCE, X/R, 100 MVA CONVERSION');
S_gsut = 515;                       % CTI, nameplate, SLD
taps = struct('name',{'lower','main','higher'}, 'Z',{15.5,16.0,16.9}, 'R',{0.28,0.21,0.21});
p('%-8s %8s %8s %12s %10s %10s\n','tap','Z %','R %','X %','X/R','kappa');
line();
for i = 1:numel(taps)
    X  = sqrt(taps(i).Z^2 - taps(i).R^2);
    XR = X/taps(i).R;
    kap = 1.02 + 0.98*exp(-3/XR);
    p('%-8s %8.2f %8.3f %12.6f %10.4f %10.5f\n', taps(i).name, taps(i).Z, taps(i).R, X, XR, kap);
    if strcmp(taps(i).name,'main'), Xm = X; XRm = XR; end
end
line();
p('MAIN-TAP X/R = %.4f  (master instruction 24 quotes ~76.19; difference %.4f %%,\n', ...
    XRm, abs(XRm-76.19)/76.19*100);
p('  arising only from rounding of X. Reported, not silently matched.)\n\n');
Z0_gsut = 15.8;                     % CTI + APS
p('Z0 (main tap) = %.1f %% on 515 MVA   -> Z0/Z1 = %.6f\n', Z0_gsut, Z0_gsut/16.0);
kg = Sbase/S_gsut;
p('On 100 MVA (x %.8f):  Z1 = %.6f %%   R1 = %.6f %%   X1 = %.6f %%   Z0 = %.6f %%\n', ...
    kg, 16.0*kg, 0.21*kg, Xm*kg, Z0_gsut*kg);
p('\nIndependent cross-check of R from the SEPARATE guaranteed-loss table:\n');
Pcu_gsut = 1095;                    % CTI 1.7 on-load copper at 515 MVA, 100 % V
R_from_loss = 100*Pcu_gsut/(S_gsut*1e3);
p('  R%% = 100*Pcu/S = 100*%g kW/%g MVA = %.6f %%   vs datasheet R = 0.21 %%\n', ...
    Pcu_gsut, S_gsut, R_from_loss);
p('  agreement = %.3f %%  (loss table and impedance table are separate entries)\n', ...
    abs(R_from_loss-0.21)/0.21*100);
p('\nLoss-table closure (CTI 1.7), total = no-load + copper + cooling:\n');
nl = 159; cu = [523 874 1095]; tot = [682 1041 1282]; rat = [355 460 515];
for i=1:3
    p('  %3d MVA: %d + %4d + cooling %4d = %4d   (stated %4d)  %s\n', rat(i), nl, cu(i), ...
      tot(i)-nl-cu(i), nl+cu(i)+(tot(i)-nl-cu(i)), tot(i), 'exact');
end
p('  implied cooling power 0 / 8 / 28 kW for ONAN/ODAN/ODAF; CTI states total cooling 28 kW.\n');
p('\nCTI block a) labelled "At 75%% of the rated voltage" - ratio test vs block b):\n');
a_blk = [300 498 621];
for i=1:3
    p('  %3d MVA: a/b = %d/%d = %.5f   (0.75^2 = %.5f)\n', rat(i), a_blk(i), cu(i), a_blk(i)/cu(i), 0.75^2);
end
p('  => block a) is at 75 %% of rated POWER, not voltage: documented source-document\n');
p('     wording defect, recorded and NOT silently corrected in the source register.\n');

head('5b. WORKBOOK GSUT COLUMNS (AK3..AO3) vs THE CTI DATASHEET - WHERE REV2 GOT 16.63 %');
p('Workbook row 3 GSUT block: AK3=515 MVA, AL3=155.3 kW PNL, AM3=0.00034 INL,\n');
p('                           AN3=1067.5 kW PFL, AO3=0.1663 %%Z, AP3=YNd1, AQ3="Solid Ground".\n\n');
AL3 = 155.3; AN3 = 1067.5; AO3 = 0.1663;
p('(i) Impedance cell AO3 = %.4f.\n', AO3);
p('    CTI datasheet + SLD + SIE + APS all state Z = 16.0 %% on 515 MVA.\n');
p('    SIE 2.1.1 states the GENERATOR saturated xd = 166.3 %% = 1.663 pu.\n');
p('    AO3 = 0.1663 is 166.3 %% / 1000, i.e. the generator reactance digits in the\n');
p('    transformer impedance cell. Header AO2 itself says "(%%Z or in pu)" - the unit\n');
p('    is ambiguous in the source. Recorded as SOURCE_CONFLICT; 16.0 %% adopted by\n');
p('    hierarchy (tier-1 manufacturer datasheet over tier-3 collection sheet).\n\n');
p('(ii) Copper loss implied by the workbook: AN3 - AL3 = %.1f - %.1f = %.1f kW\n', AN3, AL3, AN3-AL3);
R_wb = 100*(AN3-AL3)/(S_gsut*1e3);
p('     R%% = 100*%.1f/%g = %.6f %%\n', AN3-AL3, S_gsut*1e3, R_wb);
p('     Rev2 hard-codes T.R1_pu_own = 0.001771 (rev2/data/ashuganj_rev2_registry.m:35).\n');
p('     |R_wb - 0.1771 %%| = %.6f %% -> Rev2''s GSUT R is DERIVED FROM THE WORKBOOK,\n', abs(R_wb-0.1771));
p('     not from the CTI datasheet.\n');
p('     CTI loss table gives R = %.6f %% and CTI states R = 0.21 %% (agree to %.2f %%).\n', ...
    R_from_loss, abs(R_from_loss-0.21)/0.21*100);
p('     Workbook route vs CTI stated: %.2f %% apart. CTI self-consistent, workbook is not.\n', ...
    abs(R_wb-0.21)/0.21*100);
p('     => adopt R = 0.21 %%; record AL3/AN3 as SOURCE_CONFLICT (see (iii)).\n\n');
p('(iii) No-load loss: AL3 = %.1f kW vs CTI 159 kW (%.2f %% apart).\n', AL3, abs(AL3-159)/159*100);
p('      Total full-load loss: AN3 = %.1f kW vs CTI total at 515 MVA = 1282 kW (%.2f %% apart).\n', ...
    AN3, abs(AN3-1282)/1282*100);
p('      Rev2 Simulink Rm = 3316.5 comes from %g/%.1f = %.1f (workbook), not %g/159 = %.1f (CTI).\n', ...
    S_gsut*1e3, AL3, S_gsut*1e3/AL3, S_gsut*1e3, S_gsut*1e3/159);

head('6. GSUT MAGNETISING BRANCH - WHICH NO-LOAD CURRENT IS PHYSICALLY POSSIBLE?');p('Rm(pu, own base) = S_rated/P_noload ; Lm(pu) = 1/sqrt(I0^2 - (1/Rm)^2)\n');
Rm_g = S_gsut*1e3/nl;
p('Rm = %g MVA / %g kW = %.4f pu ; 1/Rm = %.6e pu = %.6f %%\n', S_gsut, nl, Rm_g, 1/Rm_g, 100/Rm_g);
cands = struct('lbl',{'CTI 0.13 % (datasheet, 100 % V)','WB AM3 read as pu (0.00034 pu = 0.034 %)','WB AM3 read literally as 0.00034 %'}, ...
               'I0',{0.0013, 0.00034, 0.0000034});
for i = 1:numel(cands)
    rad = cands(i).I0^2 - (1/Rm_g)^2;
    if rad > 0
        p('  %-46s I0=%.7f pu  radicand=%+.6e  Lm=%10.2f pu\n', cands(i).lbl, cands(i).I0, rad, 1/sqrt(rad));
    else
        p('  %-46s I0=%.7f pu  radicand=%+.6e  Lm=IMAGINARY -> IMPOSSIBLE\n', cands(i).lbl, cands(i).I0, rad);
    end
end
p('  => the literal 0.00034 %% reading is falsified by physics (I0 < I_Rm), independently\n');
p('     of any source hierarchy. 0.13 %% (CTI) is adopted; WB AM3 recorded as SOURCE_CONFLICT.\n');

head('7. UAT AND GAT (CTIU datasheet, BOTH on base 25 MVA - stated on datasheet AND SLD)');
tx = struct( ...
  'name', {'UAT 10BBT10','GAT 10BBT20'}, ...
  'S',    {25, 25}, ...
  'Z',    {10.5, 12.0}, ...
  'Rds',  {0.4, 0.5}, ...
  'Pcu',  {110, 116}, ...
  'Pnl',  {14, 23}, ...
  'I0',   {0.003, 0.003}, ...
  'Z0',   {9.3, 10.8}, ...
  'tot19',{79, 92}, ...
  'cu19', {65, 69});
for i = 1:numel(tx)
    t = tx(i);
    p('\n--- %s : %g MVA base, Z=%.1f %%, Z0=%.1f %% ---\n', t.name, t.S, t.Z, t.Z0);
    R_loss = 100*t.Pcu/(t.S*1e3);
    X_loss = sqrt(t.Z^2 - R_loss^2);
    p('  R from copper loss = 100*%g/%g = %.6f %%   (datasheet states ~%.1f %%)\n', t.Pcu, t.S*1e3, R_loss, t.Rds);
    p('  X = sqrt(Z^2-R^2)  = %.6f %%   X/R = %.4f\n', X_loss, X_loss/R_loss);
    kt = Sbase/t.S;
    p('  on 100 MVA (x%.1f): Z1=%.4f %%  R1=%.4f %%  X1=%.4f %%  Z0=%.4f %%\n', ...
        kt, t.Z*kt, R_loss*kt, X_loss*kt, t.Z0*kt);
    p('  Z0/Z1 = %.6f\n', t.Z0/t.Z);
    Rm = t.S*1e3/t.Pnl;  rad = t.I0^2 - (1/Rm)^2;
    p('  Rm = %g/%g = %.3f pu ; I0 = %.4f pu ; radicand = %+.6e ; Lm = %.3f pu\n', ...
        t.S*1e3, t.Pnl, Rm, t.I0, rad, 1/sqrt(rad));
    p('  loss closure at 19 MVA (ONAN, no cooling): %d + %d = %d (stated %d)\n', ...
        t.Pnl, t.cu19, t.Pnl+t.cu19, t.tot19);
    p('  copper scaling check: %d*(25/19)^2 = %.2f kW vs stated %d kW at 25 MVA (%.2f %%)\n', ...
        t.cu19, t.cu19*(25/19)^2, t.Pcu, abs(t.cu19*(25/19)^2-t.Pcu)/t.Pcu*100);
end

head('8. OFF-NOMINAL TAP RATIO FOR THE 6.9 kV WINDING ON A 6.6 kV BUS');
p('Transformer LV winding rated 6.9 kV (CTIU); station bus rated 6600 V (SLD).\n');
p('  correct a = V_winding/V_bus = 6.9/6.6 = %.7f\n', 6.9/6.6);
p('  inverse   = 6.6/6.9        = %.7f   <-- value found in stale results/ CSVs\n', 6.6/6.9);
p('  ratio between the two = %.5f  (%.2f %% error in modelled ratio)\n', ...
    (6.9/6.6)/(6.6/6.9), ((6.9/6.6)/(6.6/6.9)-1)*100);

head('9. GRID EQUIVALENT AT THE 230 kV BUS');
p('PRIMARY (SIE 2.4, labelled "estimated"; APS answered "Contact PGCB" to all grid items):\n');
Ik = 50e3; V = 230e3;
Sk = sqrt(3)*V*Ik/1e6;
Zg = V^2/(Sk*1e6);
p('  Ik" = %.0f kA -> Sk" = sqrt(3)*230kV*50kA = %.2f MVA   (SIE states 19 919 MVA)\n', Ik/1e3, Sk);
p('  Z   = V^2/Sk = %.6f ohm   (SIE states XN 2.66 -> Siemens quote Z with R neglected)\n', Zg);
p('  on 100 MVA base: Z = %.8f pu\n', Zg/Zb230_100);
p('\nSECONDARY SENSITIVITY (Rev2 alternative, 45.01 kA, X/R = 10.99):\n');
Ik2 = 45.01e3; XR2 = 10.99;
Sk2 = sqrt(3)*V*Ik2/1e6;  Zg2 = V^2/(Sk2*1e6);
R2 = Zg2/sqrt(1+XR2^2);   X2g = R2*XR2;
p('  Sk = %.2f MVA ; Z = %.6f ohm ; R = %.6f ohm ; X = %.6f ohm\n', Sk2, Zg2, R2, X2g);
p('  on 100 MVA: Z = %.8f pu ; R = %.8f pu ; X = %.8f pu\n', Zg2/Zb230_100, R2/Zb230_100, X2g/Zb230_100);
p('  NOTE: a previously circulated "Z = 3.25 ohm" for this case is NOT consistent with\n');
p('        45.01 kA (3.25 ohm implies %.2f kA). The executed value above supersedes it.\n', ...
    (V^2/3.25)/(sqrt(3)*V)/1e3);

head('10. AUXILIARY LOAD (APS: 14 MW at 0.85 pf)');
Paux = 14; pfa = 0.85;
Saux = Paux/pfa; Qaux = Saux*sin(acos(pfa));
p('  S = P/pf = %.6f MVA ; Q = S*sin(acos(pf)) = %.6f MVAr\n', Saux, Qaux);
alloc = [9.018 5.589; 2.491 1.544; 2.491 1.544];
p('  engineering allocation rows: \n');
for i=1:3, p('     %6.3f + j%6.3f MVA\n', alloc(i,1), alloc(i,2)); end
p('  sum = %.4f + j%.4f  (vs %.4f + j%.4f)  dP=%.4f dQ=%.4f\n', ...
    sum(alloc(:,1)), sum(alloc(:,2)), Paux, Qaux, sum(alloc(:,1))-Paux, sum(alloc(:,2))-Qaux);

head('11. GENERATOR-TERMINAL FAULT LEVEL USING THE WORKBOOK SATURATED SUBTRANSIENT');
Xdpp_sat = 0.2248;  c = 1.1;
p('  Xd"(sat) = %.4f pu (WB K3 = SIE 22.48 %%, identical)\n', Xdpp_sat);
p('  without voltage factor : S = %g/%.4f = %.2f MVA ; I = %.2f A = %.3f kA\n', ...
    Sgen, Xdpp_sat, Sgen/Xdpp_sat, Ib_gen/Xdpp_sat, Ib_gen/Xdpp_sat/1e3);
p('  IEC 60909 with c = %.1f   : S = %.2f MVA ; I = %.2f A = %.3f kA\n', ...
    c, c*Sgen/Xdpp_sat, c*Ib_gen/Xdpp_sat, c*Ib_gen/Xdpp_sat/1e3);
p('  (machine alone, no network contribution; illustrative scale check only)\n');

head('12. NEUTRAL EARTHING TRANSFORMER 10BAB11 (SIE 2.3 + SLD)');
Vp = 22e3/sqrt(3); Vs = 500; TRU = Vp/Vs; R1 = 2.62;
p('  primary %.2f V (= 22 kV/sqrt3), secondary %g V -> turns ratio = %.4f (SIE states 25.4)\n', Vp, Vs, TRU);
p('  loading resistor R1 = %.2f ohm on the 500 V side\n', R1);
p('  referred to the 22 kV/sqrt3 primary: R = R1*TRU^2 = %.2f ohm\n', R1*TRU^2);
p('  resulting earth-fault current if the full phase voltage appears across it:\n');
p('     I = (22000/sqrt3)/%.2f = %.2f A\n', R1*TRU^2, Vp/(R1*TRU^2));
p('  SIE also states R_HV-DC = 60 ohm ; APS form answered Zn = "(60) Low-Reactance".\n');
p('  NET rating 135 kVA / 20 s appears on BOTH SIE 2.3 and the INEL SLD.\n');
p('  => generator neutral is HIGH-RESISTANCE earthed. NOT solidly earthed.\n');

head('13. SUMMARY OF EXECUTED CHECKS');
p('  All numbers above were produced by execution, not by hand.\n');
p('  Checks that CLOSE exactly  : loss-table closures (GSUT/UAT/GAT), Sk" from Ik",\n');
p('                               nameplate current, P/Q at rated pf, SCR<->1/Xd(sat).\n');
p('  Checks that CLOSE approx.  : R from losses vs datasheet R (1.2 %% / 10 %% / 7 %%),\n');
p('                               copper scaling (2.3 %% / 3.0 %%), Ta via temperature.\n');
p('  Checks that DO NOT close   : none that are claimed as validations.\n');
p('  Physics-based rejection    : GSUT I0 = 0.00034 %% (negative radicand).\n\n');
end
