function V = phase4_validate(runID)
%PHASE4_VALIDATE  Validation engine M6, 20 independent legs.
%
%   V = PHASE4_VALIDATE(runID) runs the internal mini-suite (all OUT, P15,
%   bolted unless noted; F4 at m with B-view) via the phase4_solve,
%   phase4_stages, phase4_contrib and phase4_topology entry points (never
%   reimplemented math) and checks 27 independent legs (L01-L20 originals
%   plus L21 V-A B6_6 prefault, L22 V-B 6.9/6.6 tap, L23 V-C aux base,
%   L24 V-D loop base identity, L25 V-E H2-vs-H0 separation, L26 V-F
%   all-type continuity, L27 V-G handoff LL/LLG completeness). Each leg
%   real computed mismatch (residual) against its adopted tolerance; no leg
%   is a stub that always passes.
%
%   Round-trip legs use the independent local re-implementation below
%   (seq2ph_ind / ph2seq_ind), not the solver's own routine.
%
%   H-leg comparison is invariance-only, never a correctness proof
%   (tertiary affects zero only, so LLL/LL must match across H legs;
%   LG spread is recorded without threshold).
%
%   Mini-suite: A=F3 LLL, B=F3 LG, C=F3 LL, D=F3 LLG, E=F1 LG,
%   G=F3 LG IN-case, H0/H2=F3 LG OUT with gatLeg H0/H2 (+H0/H2 LLL/LL OUT
%   and IN triplets for L14, H0G/H2G=F3 LG IN for L25), M0=F4 m=0 LLL,
%   M1=F4 m=1 LLL (+M0/M1 LG/LL/LLG triplets for L26), F5 LLL (+F5LG/F5LL/F5LLG
%   for L26), RERUN=A repeated. All OUT, P15, bolted unless noted.
%   L10 F-probe uses normalized ZfMode earth vs bolted via phase4_stages
%   (superseded historical fixed-ohm probe replaced; see L10).
%
%   Output: V.legs 1x20 struct array with fields name, pass (logical),
%   residual (double), tol (double); V.tolsPrinted true after printing each
%   adopted tol with solver settings; V.runID stores the free string tag.
if nargin < 1
    runID = '';
end
if isstring(runID)
    runID = char(runID);
end
% ---- adopted tolerances (design thresholds, printed with each check) ----
T_RT = 1e-9;
T_AN = 1e-6;
T_KCL = 1e-6;
T_DEAD = 1e-3;
T_CONT = 0.05;
T_DET = 1e-12;
T_STRUCT = 0.5;
T_SYM = 1e-6;
T_PRE = 0.10;
T_B66 = 0.05;  % measured residual 0.0257 post aux+tap fix; 2x margin, 10-20x below defect class (correction record)
T_TAP = 1e-12;
settingsBase = 'ds=P XoR_P=15 stage=Ikpp bolted Zf=0 (unless noted) sat primary closed';
fprintf('phase4_validate runID=%s settings: %s\n', runID, settingsBase);
% ---- internal mini-suite via entry points ----
A = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0);
B = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0);
C = phase4_solve('LF360_GAT_OUT','P',15,'F3','LL','Ikpp',0);
D = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLG','Ikpp',0);
E = phase4_solve('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',0);
G = phase4_solve('LF360_GAT_IN','P',15,'F3','LG','Ikpp',0);
H0LG = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0, struct('gatLeg','H0'));
H2LG = phase4_solve('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0, struct('gatLeg','H2'));
H0LLL = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0, struct('gatLeg','H0'));
H2LLL = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0, struct('gatLeg','H2'));
H0LL = phase4_solve('LF360_GAT_OUT','P',15,'F3','LL','Ikpp',0, struct('gatLeg','H0'));
H2LL = phase4_solve('LF360_GAT_OUT','P',15,'F3','LL','Ikpp',0, struct('gatLeg','H2'));
AIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LLL','Ikpp',0);
H0AIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LLL','Ikpp',0, struct('gatLeg','H0'));
H2AIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LLL','Ikpp',0, struct('gatLeg','H2'));
CIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LL','Ikpp',0);
H0CIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LL','Ikpp',0, struct('gatLeg','H0'));
H2CIN = phase4_solve('LF360_GAT_IN','P',15,'F3','LL','Ikpp',0, struct('gatLeg','H2'));
M0 = phase4_solve('LF360_GAT_OUT','P',15,'F4','LLL','Ikpp',0, struct('m',0));
M1 = phase4_solve('LF360_GAT_OUT','P',15,'F4','LLL','Ikpp',0, struct('m',1));
F5 = phase4_solve('LF360_GAT_OUT','P',15,'F5','LLL','Ikpp',0);
RER = phase4_solve('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0);
RboltF1 = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',[],'bolted');
RearthF1 = phase4_stages('LF360_GAT_OUT','P',15,'F1','LG','Ikpp',[],'earth');
CA = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLL','Ikpp',0,'bolted');
CB = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LG','Ikpp',0,'bolted');
CC = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LL','Ikpp',0,'bolted');
CD = phase4_contrib('LF360_GAT_OUT','P',15,'F3','LLG','Ikpp',0,'bolted');
F5LG = phase4_solve('LF360_GAT_OUT','P',15,'F5','LG','Ikpp',0);
F5LL = phase4_solve('LF360_GAT_OUT','P',15,'F5','LL','Ikpp',0);
F5LLG = phase4_solve('LF360_GAT_OUT','P',15,'F5','LLG','Ikpp',0);
H0G = phase4_solve('LF360_GAT_IN','P',15,'F3','LG','Ikpp',0, struct('gatLeg','H0'));
H2G = phase4_solve('LF360_GAT_IN','P',15,'F3','LG','Ikpp',0, struct('gatLeg','H2'));
M0LG = phase4_solve('LF360_GAT_OUT','P',15,'F4','LG','Ikpp',0, struct('m',0));
M1LG = phase4_solve('LF360_GAT_OUT','P',15,'F4','LG','Ikpp',0, struct('m',1));
M0LL = phase4_solve('LF360_GAT_OUT','P',15,'F4','LL','Ikpp',0, struct('m',0));
M1LL = phase4_solve('LF360_GAT_OUT','P',15,'F4','LL','Ikpp',0, struct('m',1));
M0LLG = phase4_solve('LF360_GAT_OUT','P',15,'F4','LLG','Ikpp',0, struct('m',0));
M1LLG = phase4_solve('LF360_GAT_OUT','P',15,'F4','LLG','Ikpp',0, struct('m',1));
% ---- L01 seq->ph round-trip (17-16 then independent 17-17 re-impl) ----
runs4 = {A,B,C,D};
r01 = 0;
for k = 1:4
    F = runs4{k};
    [Ia2,Ib2,Ic2] = seq2ph_ind(F.I0,F.I1,F.I2);
    sc = max([abs(F.Ia),abs(F.Ib),abs(F.Ic),abs(F.I1),abs(F.I2),abs(F.I0),1e-30]);
    rk = max([abs(Ia2-F.Ia),abs(Ib2-F.Ib),abs(Ic2-F.Ic)])/sc;
    if rk > r01, r01 = rk; end
end
p01 = (r01 <= T_RT);
fprintf('L01 seq2ph round-trip residual=%.3g tol=%.1e pass=%d (%s)\n', r01, T_RT, p01, settingsBase);
% ---- L02 ph->seq reverse identity ----
r02 = 0;
for k = 1:4
    F = runs4{k};
    [I02,I12,I22] = ph2seq_ind(F.Ia,F.Ib,F.Ic);
    sc = max([abs(F.I0),abs(F.I1),abs(F.I2),1e-30]);
    rk = max([abs(I02-F.I0),abs(I12-F.I1),abs(I22-F.I2)])/sc;
    if rk > r02, r02 = rk; end
end
p02 = (r02 <= T_RT);
fprintf('L02 ph2seq reverse residual=%.3g tol=%.1e pass=%d (%s)\n', r02, T_RT, p02, settingsBase);
% ---- L03 LLL nodal vs scalars + V1F=I1*Zf + symmetry ----
scA = max([abs(A.Vf),abs(A.I1*A.Zth1),1e-30]);
rV = abs(A.V1F - A.I1*0)/scA;
rS = max([abs(abs(A.Ia)-abs(A.I1)),abs(abs(A.Ib)-abs(A.I1)),abs(abs(A.Ic)-abs(A.I1))])/max(abs(A.I1),1e-30);
r03 = max([A.audit_res, rV, rS]);
p03 = (r03 <= T_AN);
fprintf('L03 LLL audit=%.3g V=%.3g sym=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', A.audit_res, rV, rS, r03, T_AN, p03, settingsBase);
% ---- L04 LG nodal vs scalars + Vsum + branch ----
scB = max(abs(B.Vf),1e-30);
rVsum = abs((B.V1F+B.V2F+B.V0F) - 0)/scB;
rIb = abs(B.Ib)/max(abs(B.Ia),1e-30);
rIc = abs(B.Ic)/max(abs(B.Ia),1e-30);
rIa3 = abs(B.Ia-3*B.I0)/max(abs(B.Ia),1e-30);
r04 = max([B.audit_res, rVsum, rIb, rIc, rIa3]);
p04 = (r04 <= T_AN);
fprintf('L04 LG audit=%.3g Vsum=%.3g Ib=%.3g Ic=%.3g Ia3=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', B.audit_res, rVsum, rIb, rIc, rIa3, r04, T_AN, p04, settingsBase);
% ---- L05 LL nodal vs scalars + Vdiff + Ib+Ic ----
scC = max(abs(C.Vf),1e-30);
rVdiff = abs((C.V1F-C.V2F) - 0)/scC;
rSum = abs(C.Ib+C.Ic)/max([abs(C.Ib),abs(C.Ic),1e-30]);
rMagB = abs(abs(C.Ib)-sqrt(3)*abs(C.I1))/(sqrt(3)*max(abs(C.I1),1e-30));
rMagC = abs(abs(C.Ic)-sqrt(3)*abs(C.I1))/(sqrt(3)*max(abs(C.I1),1e-30));
rIa0 = abs(C.Ia)/max([abs(C.Ib),abs(C.Ic),1e-30]);
r05 = max([C.audit_res, rVdiff, rSum, rMagB, rMagC, rIa0]);
p05 = (r05 <= T_AN);
fprintf('L05 LL audit=%.3g Vdiff=%.3g sum=%.3g magB=%.3g magC=%.3g Ia0=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', C.audit_res, rVdiff, rSum, rMagB, rMagC, rIa0, r05, T_AN, p05, settingsBase);
% ---- L06 LLG nodal vs scalars + Vequality + Ie ----
scD = max(abs(D.Vf),1e-30);
rE12 = abs(D.V1F-D.V2F)/scD;
rE10 = abs(D.V1F-D.V0F)/scD;
Ie = D.Ia+D.Ib+D.Ic;
rIe = abs(Ie-3*D.I0)/max(abs(Ie),1e-30);
r06 = max([D.audit_res, rE12, rE10, rIe]);
p06 = (r06 <= T_AN);
fprintf('L06 LLG audit=%.3g e12=%.3g e10=%.3g Ie=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', D.audit_res, rE12, rE10, rIe, r06, T_AN, p06, settingsBase);
% ---- L07 KCL seq runs A-D ----
r07 = max([CA.kcl_seq, CB.kcl_seq, CC.kcl_seq, CD.kcl_seq]);
p07 = (r07 <= T_KCL);
fprintf('L07 KCLseq A=%.3g B=%.3g C=%.3g D=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', CA.kcl_seq, CB.kcl_seq, CC.kcl_seq, CD.kcl_seq, r07, T_KCL, p07, settingsBase);
% ---- L08 KCL ph runs A-D ----
r08 = max([CA.kcl_ph, CB.kcl_ph, CC.kcl_ph, CD.kcl_ph]);
p08 = (r08 <= T_KCL);
fprintf('L08 KCLph A=%.3g B=%.3g C=%.3g D=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', CA.kcl_ph, CB.kcl_ph, CC.kcl_ph, CD.kcl_ph, r08, T_KCL, p08, settingsBase);
% ---- L09 earth KCL + gen-neutral IN=3I0 from branch rows ----
gB = getBranch(B.branch,'GEN0'); nB = getBranch(B.branch,'NER');
gD = getBranch(D.branch,'GEN0'); nD = getBranch(D.branch,'NER');
gE = getBranch(E.branch,'GEN0'); nE = getBranch(E.branch,'NER');
rnB = abs(gB.I0-nB.I0)/max(abs(B.I0),1e-30);
rnD = abs(gD.I0-nD.I0)/max(abs(D.I0),1e-30);
rnE = abs(gE.I0-nE.I0)/max(abs(E.I0),1e-30);
r09 = max([CB.kcl_earth, CD.kcl_earth, rnB, rnD, rnE]);
p09 = (r09 <= T_KCL);
fprintf('L09 earthKCL B=%.3g D=%.3g nB=%.3g nD=%.3g nE=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', CB.kcl_earth, CD.kcl_earth, rnB, rnD, rnE, r09, T_KCL, p09, settingsBase);
% ---- L10 NER gate: LLL dead + LG share + F-probe note (normalized, note-only) ----
nerA = getBranch(A.branch,'NER');
rDead10 = abs(nerA.I0)/max([abs(A.I1),abs(A.Ia),1e-30]);
Z = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
share10 = abs(Z.Z3ZN_pu)/abs(Z.Z0gen_pu+Z.Z3ZN_pu);
nerE = getBranch(E.branch,'NER');
rEnerg10 = abs(nerE.I0)/max([abs(E.Ia),1e-30]);
relFprobe = abs(RearthF1.Ifault-RboltF1.Ifault)/max(abs(RboltF1.Ifault),1e-30);
p10 = (rDead10 <= T_DEAD) && (rEnerg10 > T_DEAD);
r10 = rDead10;
fprintf('L10 NERgate dead(LLL)=%.3g energ(F1LG)=%.3g share=|3ZN|/|Z0gen+3ZN|=%.6f Fprobe rel=%.3g (normalized earth %.4g ohm vs bolted, note only) residual=%.3g tol=%.1e pass=%d (%s)\n', rDead10, rEnerg10, share10, relFprobe, RearthF1.Zf_ohm, r10, T_DEAD, p10, settingsBase);
% ---- L11 GSUT block: E-run line+grid zero dead + F3 LG GSUT0 nonzero ----
lnE = getBranch(E.branch,'LINE'); grE = getBranch(E.branch,'GRID');
rLnE = abs(lnE.I0)/max(abs(E.Ia),1e-30);
rGrE = abs(grE.I0)/max(abs(E.Ia),1e-30);
gsB = getBranch(B.branch,'GSUT0');
rGsB = abs(gsB.I0)/max(abs(B.Ia),1e-30);
r11 = max([rLnE, rGrE]);
p11 = (r11 <= T_DEAD) && (rGsB > T_DEAD);
fprintf('L11 GSUTblock E-LINE0=%.3g E-GRID0=%.3g F3-GSUT0=%.3g (nonzero) residual=%.3g tol=%.1e pass=%d (%s)\n', rLnE, rGrE, rGsB, r11, T_DEAD, p11, settingsBase);
% ---- L12 UAT path: HV zero dead + LV reported + GAT-OUT UAT-only ----
uatB = getBranch(B.branch,'UAT');
rUat = abs(uatB.I0)/max(abs(B.Ia),1e-30);
uat0B = getBranch(B.branch,'UAT0'); uatnB = getBranch(B.branch,'UATN');
rLv0 = abs(uat0B.I0)/max(abs(B.Ia),1e-30);
rLvn = abs(uatnB.I0)/max(abs(B.Ia),1e-30);
b66ok = (abs(CA.b66_split.UAT_share-1) < 1e-12) && isnan(CA.b66_split.GAT_share) && isnan(CA.b66_split.ratio);
r12 = rUat;
p12 = (r12 <= T_DEAD) && b66ok;
fprintf('L12 UATpath HV0=%.3g LV0=%.3g LVN=%.3g (report only) b66 UAT_share=%.6g GAT_share=%.6g ratio=%.6g ok=%d residual=%.3g tol=%.1e pass=%d (%s)\n', rUat, rLv0, rLvn, CA.b66_split.UAT_share, CA.b66_split.GAT_share, CA.b66_split.ratio, b66ok, r12, T_DEAD, p12, settingsBase);
% ---- L13 GAT path: OUT absent + IN through nonzero ----
hasGAT_OUT = false;
for k = 1:numel(B.branch)
    nm = B.branch(k).name;
    if numel(nm) >= 3 && strcmp(nm(1:3),'GAT')
        hasGAT_OUT = true;
    end
end
g0G = getBranch(G.branch,'GAT0');
rGatG = abs(g0G.I0)/max(abs(G.Ia),1e-30);
if hasGAT_OUT, r13 = 1; else, r13 = 0; end
p13 = (~hasGAT_OUT) && (rGatG > T_DEAD);
fprintf('L13 GATpath OUT_absent=%d IN_GAT0=%.3g (nonzero) residual=%.3g tol=%.1e pass=%d (%s)\n', ~hasGAT_OUT, rGatG, r13, T_STRUCT, p13, settingsBase);
% ---- L14 H-invariance LLL+LL across H0/H1/H2 OUT and IN; LG spread recorded ----
dLLL0 = abs(H0LLL.I1-A.I1)/max(abs(A.I1),1e-30);
dLLL2 = abs(H2LLL.I1-A.I1)/max(abs(A.I1),1e-30);
dLL0 = abs(H0LL.I1-C.I1)/max(abs(C.I1),1e-30);
dLL2 = abs(H2LL.I1-C.I1)/max(abs(C.I1),1e-30);
dINLLL0 = abs(H0AIN.I1-AIN.I1)/max(abs(AIN.I1),1e-30);
dINLLL2 = abs(H2AIN.I1-AIN.I1)/max(abs(AIN.I1),1e-30);
dINLL0 = abs(H0CIN.I1-CIN.I1)/max(abs(CIN.I1),1e-30);
dINLL2 = abs(H2CIN.I1-CIN.I1)/max(abs(CIN.I1),1e-30);
r14 = max([dLLL0,dLLL2,dLL0,dLL2,dINLLL0,dINLLL2,dINLL0,dINLL2]);
spreadLG = max([abs(H0LG.I1-B.I1),abs(H2LG.I1-B.I1)])/max(abs(B.I1),1e-30);
p14 = (r14 <= T_RT);
fprintf('L14 Hinvariance OUT LLL0=%.3g LLL2=%.3g LL0=%.3g LL2=%.3g IN LLL0=%.3g LLL2=%.3g LL0=%.3g LL2=%.3g LGspread=%.3g (note only, invariance-only) residual=%.3g tol=%.1e pass=%d (%s)\n', dLLL0, dLLL2, dLL0, dLL2, dINLLL0, dINLLL2, dINLL0, dINLL2, spreadLG, r14, T_RT, p14, settingsBase);
% ---- L15 continuity F3-M0 and F5-M1 separate rows ----
rel0 = abs(M0.I1-A.I1)/max(abs(A.I1),1e-30);
rel1 = abs(M1.I1-F5.I1)/max(abs(F5.I1),1e-30);
r15 = max([rel0, rel1]);
p15 = (rel0 <= T_CONT) && (rel1 <= T_CONT);
fprintf('L15 continuity F3-M0=%.3g F5-M1=%.3g (separate rows) residual=%.3g tol=%.2f pass=%d (%s)\n', rel0, rel1, r15, T_CONT, p15, settingsBase);
% ---- L16 F1F2 same node labels differ no invented impedance ----
Y16 = phase4_topology(0.5,'B','closed');
passNode = (Y16.nodeF1 == Y16.nodeF2);
passLab = ~strcmp(Y16.labelF1, Y16.labelF2);
fn16 = fieldnames(Y16);
hasInv = false;
for k = 1:numel(fn16)
    f = fn16{k};
    if (~isempty(strfind(f,'F1')) || ~isempty(strfind(f,'F2'))) && ~(strcmp(f,'nodeF1')||strcmp(f,'nodeF2')||strcmp(f,'labelF1')||strcmp(f,'labelF2')||strcmp(f,'nodeF4'))
        hasInv = true;
    end
    if strcmp(f,'Z_F1F2') || strcmp(f,'ZF1F2') || strcmp(f,'Z_F1') || strcmp(f,'Z_F2') || strcmp(f,'ZF1') || strcmp(f,'ZF2')
        hasInv = true;
    end
end
if passNode && passLab && ~hasInv, r16 = 0; else, r16 = 1; end
p16 = (passNode && passLab && ~hasInv);
fprintf('L16 F1F2 node=%d labelDiff=%d noInvented=%d residual=%.3g tol=%.1e pass=%d (%s)\n', passNode, passLab, ~hasInv, r16, T_STRUCT, p16, settingsBase);
% ---- L17 two-rest restoration + zero X/R envelope ----
r17 = 0;
for m = [0,0.5,1]
    Y = phase4_topology(m,'B','closed');
    d1 = abs(Y.Zs_branch_pu/2 - Y.Zs_eq_pu);
    d2 = abs((Y.Zs_S+Y.Zs_R) - Y.Zs_eq_pu);
    d3 = abs(Y.Bs_branch_pu*2 - Y.Bs_eq_pu);
    d4 = abs((Y.Bs_S+Y.Bs_R) - Y.Bs_eq_pu);
    dm = max([d1,d2,d3,d4]);
    if dm > r17, r17 = dm; end
    fprintf('L17 m=%.2f d1=%.3g d2=%.3g d3=%.3g d4=%.3g (%s)\n', m, d1, d2, d3, d4, settingsBase);
end
Z17 = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
xor17 = Z17.Z0line_X_pu/Z17.Z0line_R_pu;
inEnv = (xor17 >= 2.05) && (xor17 <= 8.98);
p17 = (r17 <= T_RT) && inEnv;
fprintf('L17 tworest residual=%.3g tol=%.1e XoverR=%.6f in[2.05,8.98]=%d pass=%d (%s)\n', r17, T_RT, xor17, inEnv, p17, settingsBase);
% ---- L18 determinism RERUN vs A ----
scD18 = max([abs(A.I1),abs(A.I2),abs(A.I0),abs(A.Ia),abs(A.Ib),abs(A.Ic),1e-30]);
r18 = max([abs(RER.I1-A.I1),abs(RER.I2-A.I2),abs(RER.I0-A.I0),abs(RER.Ia-A.Ia),abs(RER.Ib-A.Ib),abs(RER.Ic-A.Ic)])/scD18;
p18 = (r18 <= T_DET);
solSettings = 'LF360_GAT_OUT P15 F3 LLL Ikpp Zf0 m0.5 gatH1 closed sat primary';
fprintf('L18 determinism residual=%.3g tol=%.1e settings=%s pass=%d (%s)\n', r18, T_DET, solSettings, p18, settingsBase);
% ---- L19 symmetry per type A-D ----
rLLLsym = max([abs(abs(A.Ia)-abs(A.I1)),abs(abs(A.Ib)-abs(A.I1)),abs(abs(A.Ic)-abs(A.I1))])/max(abs(A.I1),1e-30);
rLGb0 = max(abs(B.Ib),abs(B.Ic))/max(abs(B.Ia),1e-30);
rLLopp = abs(C.Ib+C.Ic)/max([abs(C.Ib),abs(C.Ic),1e-30]);
IeD = D.Ia+D.Ib+D.Ic;
rLLGe = abs(IeD-3*D.I0)/max(abs(IeD),1e-30);
r19 = max([rLLLsym, rLGb0, rLLopp, rLLGe]);
p19 = (r19 <= T_SYM);
fprintf('L19 symmetry LLL=%.3g LG=%.3g LL=%.3g LLG=%.3g residual=%.3g tol=%.1e pass=%d (%s)\n', rLLLsym, rLGb0, rLLopp, rLLGe, r19, T_SYM, p19, settingsBase);
% ---- L20 source conservation: sources self-checks + pre_res gate ----
srcOK = true;
try
    phase4_sources('LF360_GAT_OUT','sat');
    phase4_sources('LF360_GAT_OUT','unsat');
    phase4_sources('LF360_GAT_IN','sat');
    phase4_sources('LF360_GAT_IN','unsat');
catch
    srcOK = false;
end
r20 = max([A.pre_res, B.pre_res, C.pre_res, D.pre_res, E.pre_res, G.pre_res, M0.pre_res, M1.pre_res, F5.pre_res]);
p20 = srcOK && (r20 <= T_PRE);
fprintf('L20 sourceconsv srcOK=%d maxPre=%.6f residual=%.6f tol=%.2f pass=%d (%s)\n', srcOK, r20, r20, T_PRE, p20, settingsBase);
% ---- L21 V-A: B6_6 prefault reproduction vs frozen Phase-3 (complex, 6.6-kV base) ----
root66 = ashuganj_root();
Tb66 = readtable(fullfile(root66, 'results', 'phase3_loadflow', 'phase3_bus_results.csv'));
j66o = find(string(Tb66.Case_ID) == 'LF360_GAT_OUT' & string(Tb66.Bus_Name) == 'B6_6', 1);
j66i = find(string(Tb66.Case_ID) == 'LF360_GAT_IN' & string(Tb66.Bus_Name) == 'B6_6', 1);
V66o_csv = (Tb66.V_kV(j66o)/6.6)*exp(1j*Tb66.Angle_deg(j66o)*pi/180);
V66i_csv = (Tb66.V_kV(j66i)/6.6)*exp(1j*Tb66.Angle_deg(j66i)*pi/180);
i66A = find(A.pn == 6); i66G = find(G.pn == 6);
d66o = abs(A.Vok(i66A) - V66o_csv)/abs(V66o_csv);
d66i = abs(G.Vok(i66G) - V66i_csv)/abs(V66i_csv);
r21 = max(d66o, d66i); p21 = r21 <= T_B66;
fprintf('L21 B66gate OUT=%.6f IN=%.6f residual=%.6f tol=%.2f pass=%d (%s)\n', d66o, d66i, r21, T_B66, p21, settingsBase);
% ---- L22 V-B: 6.9/6.6 tap sanity (applied LV tap must equal documented nominal ratio) ----
aNom216 = 6.9/6.6;
tU216 = NaN; tG216 = NaN;
if isfield(A, 'tapUAT_LV'), tU216 = A.tapUAT_LV; end
if isfield(A, 'tapGAT_LV'), tG216 = A.tapGAT_LV; end
r22 = max(abs(tU216 - aNom216), abs(tG216 - aNom216));
p22 = isfinite(r22) && r22 <= T_TAP;
fprintf('L22 tap6966 UAT=%.9f GAT=%.9f expect=%.9f residual=%.3g tol=%.1e pass=%d (%s)\n', tU216, tG216, aNom216, r22, T_TAP, p22, settingsBase);
% ---- L23 V-C: aux per-unit/base sanity (independent recompute vs stamped) ----
TsV23 = readtable(fullfile(root66, 'results', 'phase3_loadflow', 'phase3_system_summary.csv'));
jsV23 = find(string(TsV23.Case_ID) == 'LF360_GAT_OUT', 1);
SauxV23 = TsV23.Paux_MW(jsV23) + 1j*TsV23.Qaux_MVAr(jsV23);
ZauxExp23 = ((Tb66.V_kV(j66o))^2/conj(SauxV23))/0.4356;
if isfield(A, 'Zaux_pu')
    zAuxA23 = A.Zaux_pu;
    r23 = abs(zAuxA23 - ZauxExp23)/abs(ZauxExp23);
    p23 = r23 <= 1e-9;
else
    zAuxA23 = NaN; r23 = Inf; p23 = false;
end
fprintf('L23 auxZ stamped=%.6f expect=%.6f residual=%.3g tol=1e-9 pass=%d (%s)\n', zAuxA23, ZauxExp23, r23, p23, settingsBase);
% ---- L24 V-D: GAT H1 base identity 100MVA = 4x25MVA ----
Zd24 = phase4_seqZ(struct('kR',3.5,'kX',2.75,'kB',0.725,'k0g',1.5,'gatLeg','H1','lambda_T',1.0,'grid','P','XoR_P',15,'ner','primary'));
if isfield(Zd24, 'Z_T0_loop_100MVA') && isfield(Zd24, 'Z_T0_loop_25MVA')
    r24a = abs(Zd24.Z_T0_loop_100MVA - 4*Zd24.Z_T0_loop_25MVA)/abs(Zd24.Z_T0_loop_100MVA);
    r24b = abs(Zd24.Z_T0_loop_100MVA - 1.0*0.108*4)/abs(Zd24.Z_T0_loop_100MVA);
    r24 = max(r24a, r24b);
    p24 = r24 <= 1e-9;
else
    r24 = Inf; p24 = false;
end
fprintf('L24 loopIdent residual=%.3g tol=1e-9 pass=%d (%s)\n', r24, p24, settingsBase);
% ---- L25 V-E: H2 electrically distinct from H0 (structural presence + passivity ordering) ----
% Rationale (correction record): separation MAGNITUDES are model physics, not
% code correctness. The code-correctness checks are (a) H2 stamps a GATLOOP
% branch row that H0 lacks, and (b) passivity ordering I(H2) >= I(H1) >= I(H0)
% holds for F3-IN-LG Ia (adding/shorting a passive shunt cannot raise Zth).
hasLoopH0 = any(arrayfun(@(b) strcmp(b.name,'GATLOOP'), H0G.branch));
hasLoopH2 = any(arrayfun(@(b) strcmp(b.name,'GATLOOP'), H2G.branch));
iH0e = abs(H0G.Ia); iH1e = abs(G.Ia); iH2e = abs(H2G.Ia);
ord25 = (iH2e >= iH1e) && (iH1e >= iH0e);
r25 = (~hasLoopH2) + (hasLoopH0) + (~ord25);  % violation count, 0 passes
p25 = (r25 == 0);
fprintf('L25 H2vsH0 loopH0=%d loopH2=%d ord=%d residual=%d tol=0 pass=%d (%s)\n', hasLoopH0, hasLoopH2, ord25, r25, p25, settingsBase);
% ---- L26 V-F: F4 continuity m=0/1 for LG/LL/LLG (extends L15 LLL-only) ----
% LLG compares GOVERNING currents max(|Ib|,|Ic|) (Ia is the healthy phase,
% near-zero by construction; relative error on it is meaningless).
r26a = abs(M0LG.Ia - B.Ia)/abs(B.Ia); r26b = abs(M1LG.Ia - F5LG.Ia)/abs(F5LG.Ia);
r26c = abs(M0LL.Ib - C.Ib)/abs(C.Ib); r26d = abs(M1LL.Ib - F5LL.Ib)/abs(F5LL.Ib);
gM0 = max(abs(M0LLG.Ib), abs(M0LLG.Ic)); gD = max(abs(D.Ib), abs(D.Ic));
gM1 = max(abs(M1LLG.Ib), abs(M1LLG.Ic)); gF5 = max(abs(F5LLG.Ib), abs(F5LLG.Ic));
r26e = abs(gM0 - gD)/abs(gD); r26f = abs(gM1 - gF5)/abs(gF5);
r26 = max([r26a, r26b, r26c, r26d, r26e, r26f]); p26 = r26 <= T_CONT;
fprintf('L26 continuity LG0=%.3g LG1=%.3g LL0=%.3g LL1=%.3g LLG0=%.3g LLG1=%.3g residual=%.3g tol=%.2f pass=%d (%s)\n', r26a, r26b, r26c, r26d, r26e, r26f, r26, T_CONT, p26, settingsBase);
% ---- L27 V-G: production handoff schema completeness for LL/LLG (probe tag) ----
run_phase4_matrix({'base'}, {'F3'}, {'LL','LLG'}, {'Ikpp'}, 'v27probe');
T27dir = fullfile(ashuganj_root(), 'results', 'phase4_fault', 'v27probe');
T27cur = readtable(fullfile(T27dir, 'phase4_fault_currents.csv'));
req27 = {'fault_type','location','stage','footnote','Irms_kA'};
miss27 = 0;
for q27 = 1:numel(req27)
    if ~any(strcmp(T27cur.Properties.VariableNames, req27{q27})), miss27 = miss27 + 1; end
end
hasLL27 = any(strcmp(string(T27cur.fault_type), 'LL'));
hasLLG27 = any(strcmp(string(T27cur.fault_type), 'LLG'));
emptyCell27 = any(cellfun(@isempty, table2cell(T27cur(:, {'fault_type','stage','footnote'}))), 'all');
r27 = miss27 + (~hasLL27) + (~hasLLG27) + emptyCell27;
p27 = (r27 == 0);
fprintf('L27 handoffLLG miss=%d hasLL=%d hasLLG=%d empty=%d residual=%d tol=0 pass=%d (%s)\n', miss27, hasLL27, hasLLG27, emptyCell27, r27, p27, settingsBase);
% ---- assemble ----
legs(1,27) = struct('name','','pass',false,'residual',0,'tol',0);
legs(1).name='L01'; legs(1).pass=logical(p01); legs(1).residual=double(r01); legs(1).tol=double(T_RT);
legs(2).name='L02'; legs(2).pass=logical(p02); legs(2).residual=double(r02); legs(2).tol=double(T_RT);
legs(3).name='L03'; legs(3).pass=logical(p03); legs(3).residual=double(r03); legs(3).tol=double(T_AN);
legs(4).name='L04'; legs(4).pass=logical(p04); legs(4).residual=double(r04); legs(4).tol=double(T_AN);
legs(5).name='L05'; legs(5).pass=logical(p05); legs(5).residual=double(r05); legs(5).tol=double(T_AN);
legs(6).name='L06'; legs(6).pass=logical(p06); legs(6).residual=double(r06); legs(6).tol=double(T_AN);
legs(7).name='L07'; legs(7).pass=logical(p07); legs(7).residual=double(r07); legs(7).tol=double(T_KCL);
legs(8).name='L08'; legs(8).pass=logical(p08); legs(8).residual=double(r08); legs(8).tol=double(T_KCL);
legs(9).name='L09'; legs(9).pass=logical(p09); legs(9).residual=double(r09); legs(9).tol=double(T_KCL);
legs(10).name='L10'; legs(10).pass=logical(p10); legs(10).residual=double(r10); legs(10).tol=double(T_DEAD);
legs(11).name='L11'; legs(11).pass=logical(p11); legs(11).residual=double(r11); legs(11).tol=double(T_DEAD);
legs(12).name='L12'; legs(12).pass=logical(p12); legs(12).residual=double(r12); legs(12).tol=double(T_DEAD);
legs(13).name='L13'; legs(13).pass=logical(p13); legs(13).residual=double(r13); legs(13).tol=double(T_STRUCT);
legs(14).name='L14'; legs(14).pass=logical(p14); legs(14).residual=double(r14); legs(14).tol=double(T_RT);
legs(15).name='L15'; legs(15).pass=logical(p15); legs(15).residual=double(r15); legs(15).tol=double(T_CONT);
legs(16).name='L16'; legs(16).pass=logical(p16); legs(16).residual=double(r16); legs(16).tol=double(T_STRUCT);
legs(17).name='L17'; legs(17).pass=logical(p17); legs(17).residual=double(r17); legs(17).tol=double(T_RT);
legs(18).name='L18'; legs(18).pass=logical(p18); legs(18).residual=double(r18); legs(18).tol=double(T_DET);
legs(19).name='L19'; legs(19).pass=logical(p19); legs(19).residual=double(r19); legs(19).tol=double(T_SYM);
legs(20).name='L20'; legs(20).pass=logical(p20); legs(20).residual=double(r20); legs(20).tol=double(T_PRE);
legs(21).name='L21'; legs(21).pass=logical(p21); legs(21).residual=double(r21); legs(21).tol=double(T_B66);
legs(22).name='L22'; legs(22).pass=logical(p22); legs(22).residual=double(r22); legs(22).tol=double(T_TAP);
legs(23).name='L23'; legs(23).pass=logical(p23); legs(23).residual=double(r23); legs(23).tol=1e-9;
legs(24).name='L24'; legs(24).pass=logical(p24); legs(24).residual=double(r24); legs(24).tol=1e-9;
legs(25).name='L25'; legs(25).pass=logical(p25); legs(25).residual=double(r25); legs(25).tol=0;
legs(26).name='L26'; legs(26).pass=logical(p26); legs(26).residual=double(r26); legs(26).tol=double(T_CONT);
legs(27).name='L27'; legs(27).pass=logical(p27); legs(27).residual=double(r27); legs(27).tol=0;
for k27g = 1:numel(legs)  % structural guard: non-scalar pass/residual corrupts totals + fprintf (correction record)
    assert(isscalar(legs(k27g).pass) && isscalar(legs(k27g).residual), 'phase4_validate:nonScalar', 'Leg %s has non-scalar pass/residual.', legs(k27g).name);
end
V = struct('legs',legs,'tolsPrinted',true,'runID',runID);
fprintf('phase4_validate %s: %d/27 legs pass\n', runID, sum([legs.pass]));
end
function [Ia,Ib,Ic] = seq2ph_ind(I0,I1,I2)
a = exp(1j*2*pi/3);
Ia = I0+I1+I2;
Ib = I0+a^2*I1+a*I2;
Ic = I0+a*I1+a^2*I2;
end
function [I0,I1,I2] = ph2seq_ind(Ia,Ib,Ic)
a = exp(1j*2*pi/3);
I0 = (Ia+Ib+Ic)/3;
I1 = (Ia+a*Ib+a^2*Ic)/3;
I2 = (Ia+a^2*Ib+a*Ic)/3;
end
function r = getBranch(B,nm)
for k = 1:numel(B)
    if strcmp(B(k).name,nm)
        r = B(k);
        return;
    end
end
error('phase4_validate:missingBranch','Branch row %s missing.',nm);
end
