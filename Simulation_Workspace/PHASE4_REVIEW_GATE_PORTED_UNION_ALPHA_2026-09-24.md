# PHASE4 REVIEW GATE

Freeze re-check plus Q1-Q23 evidence for the Phase-4 MATLAB fault-analysis build (Ashuganj South).

## Freeze

| file | bytes | mtime (local) | check |
| --- | --- | --- | --- |
| PHASE3_FINAL_REPORT.md | 45504 | 2026-09-18 13:02:04 | size exact; mtime EXACT |
| PHASE3_CHANGELOG.md | 25257 | 2026-09-18 13:02:00 | size exact; mtime EXACT |
| matlab\data\ashuganj_lines.m | 13448 | 2026-09-18 12:42:16 | size exact; mtime EXACT |
| matlab\data\ashuganj_grid.m | 10655 | 2026-09-18 12:40:20 | size exact; mtime EXACT |
| rev2/data/iec_kappa.m | 267 | 2026-09-10 22:10:23 | SIZE-ONLY + exists (timestamp informational) |
| rev2/run_phase2_fault.m | 9388 | 2026-09-11 01:57:33 | SIZE-ONLY + exists (timestamp informational) |

Timestamp compare: dir() datenum exact equality against the freeze record (local time, same machine). Sizes exact.

## Q1-Q23

| id | confirmed | evidence |
| --- | --- | --- |
| Q1 | true | phase4_sources.m:61 per-case prefault; Epp_OUT=1.003595-0.229897j Epp_IN=1.001364-0.230623j diff=0.00235>0 |
| Q2 | true | phase4_registry.m:43-44 Xdpp_sat=0.2248 primary vs Xdpp=0.2608 sensitivity, differ; sources sat/unsat Xdpp_used=0.2248/0.2608, never averaged |
| Q3 | true | phase4_grounding.m:85-88 primary R_NER_HV=1750.7733 (~1750.77) Z3ZN=3x zero-only; solid rejected (phase4_grounding:variant) |
| Q4 | true | phase4_seqPN.m:58-59 Z2gen_X=0.04895197 from X2=0.2242; Z2=Z1 static equalities hold (GSUT/UAT/GAT/line/grid) |
| Q5 | true | phase4_validate runID=gate_review legs L10/L11/L13 pass=1/1/1 res=0/0/0 |
| Q6 | true | phase4_registry.m:64-66 GSUT Z=16.0 R=0.21 Z0=15.8 pct on 515MVA tap9 |
| Q7 | true | phase4_registry.m:67-70 UAT Z=10.5 R=0.4 Z0=9.3 pct + 5-A limit; grounding ZN_UAT=796.7434 ohm (~796.74) |
| Q8 | true | phase4_registry.m:72-74 GAT PS Z=12.0 R=0.5 Z0=10.8 pct; ZN_GAT_LV=796.7434 ohm (never solid); seqZ H1 loop100=0.432 closed (=4x25MVA) |
| Q9 | true | phase4_registry.m:87-90 bands kR[2,5] kX[2,3.5] kB[0.60,0.85]; line R0/X0/B0 NaN MISSING point values |
| Q10 | true | phase4_seqPN.m:112-132 P |Z|=0.00502044 vs S |Z|=0.00557702 differ; ds fields P/S separate, XoR 15 vs 10.99 |
| Q11 | true | phase4_prefault LF360 pair Qgen OUT=27.832638 IN=23.668784 MVAr differ; GAT_in 0/1; Pgen 360 both |
| Q12 | true | phase4_topology.m:56-59 nodeF1=nodeF2=1 labels F1_B22 vs F2_GSUT_LV; nodeB66=6 auxiliary |
| Q13 | true | phase4_topology.m:74-95 branch-split identities at m=0.5 B-view (Zs_branch/2, S+R, shunt pair); nodeF4=7 |
| Q14 | true | phase4_topology.m:98-104 GIS tags Q0 breaker, Q1/Q2 bus-disconnector, Q9 line-disconnector, labels only |
| Q15 | true | phase4_stages.m:68-76 ZfMode table: F3 earth=5.2900 phase=1.0580 ohm, F1 earth=0.04840 ohm, bolted 0 |
| Q16 | true | phase4_stages.m:101-106 Ib footnote constant-E t_break=0.06; labels Ikpp/ip/Ib/Isteady echo; upper-bound scan 0 hits in stages+solve |
| Q17 | true | phase4_contrib.m:105-108 per-leg ip rejected as designed (phase4_contrib:ipNoTable); F3 LG legs GEN/GSUT_HV/LINE_total/NER_earth KCL seq=5.52e-15 |
| Q18 | true | phase4_validate runID=gate_review 27/27 legs pass (teeth: full 27/27 required) |
| Q19 | true | phase4_sensitivity base_LF360_OUT_P15 legs C-LOW/H0/GAT-Z0-9.99 execute distinct; KCL worst=8.03e-15<1e-6 |
| Q20 | true | rev2/data/iec_kappa.m exists (267 B freeze); phase4_kappa.m:10-11 disclaimer NOT IEC 60909, design-defined curve |
| Q21 | true | phase4_registry.m:75-76,84-85 Z_PT/Z_ST/R0/X0 NaN MISSING; solid-grounding scan 0 hits in matlab/phase4 (gate self excluded) |
| Q22 | true | results/phase4_fault/smoke_run (reused) 25 schema headers exact order + 4 CSVs present |
| Q23 | true | boundary scan: matlab/phase4 code 0 relay-logic hits (31 CSVs headers 0 forbidden hits; scanner/detection lines exempt) |

## Remaining data D1-D8

| id | title | status |
| --- | --- | --- |
| D1 | South R0/X0/B0 + tower/soil/mutuals | MISSING |
| D2 | Grid Thevenin unmeasured | ESTIMATED/LEGACY/ASSUMPTION |
| D3 | Generator X2/X0 | QUALIFIED |
| D4 | NER reconciliation conditional + NGT | NGT MISSING |
| D5 | GAT pairwise | INCOMPLETE |
| D6 | UAT/GAT LV neutral devices | MISSING |
| D7 | Full Siemens report + INEL-0026 + JICA file | MISSING |
| D8 | Aux/downstream-LV uncertainty | UNCERTAIN |

## STOP

Phase-4 implementation complete. No protection work started. No relay settings, breaker duties, or coordination artifacts exist in matlab/phase4/ or results/phase4_fault/ (verified by Q23 scan). Awaiting explicit Phase-5 approval.

Run timestamp: 2026-09-24 13:59:55
