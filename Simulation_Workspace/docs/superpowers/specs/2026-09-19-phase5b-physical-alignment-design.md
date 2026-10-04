# Phase-5b Physical-Alignment Correction — Spec Addendum

**Date:** 2026-09-19
**Status:** Approved (triple approval: USER_ASSERTED_PENDING_DOC + uniform TMS 0.20 + start C1)
**Parent spec:** `docs/superpowers/specs/2026-09-19-phase5-protection-design.md`
**Parent plan:** `docs/superpowers/plans/2026-09-19-phase5-implementation.md`
**Trigger:** Independent physical review vs protection SLD / Siemens BD1015 report / EEE 305 slides.
**Verdict adopted:** Phase-5 shipped outputs are a disciplined *backup-OC study*, not a faithful
physical-protection model. Correct, don't rebuild. Old production tag frozen untouched; new tag
`production-v2` carries corrected numbers.

## S1. Scope reclassification (binding language)

Primary scope becomes: "Physical protection architecture + qualified backup
overcurrent/earth-fault coordination study." Never claim all plant functions simulated.
Coordination shortfalls are "study-setting coordination shortfalls," never plant failures.
TCCs split into PHYSICAL/SOURCE-BACKED vs GENERIC STUDY classes.

## S2. Source ledger (workspace-verified; transcribed in C1)

Master §§17–21 (Q0/Q1/Q2/Q9/Q51/Q52/Q8; CT 1600/800/400:1 multi-core; 7SD5221×2; 7SS523;
6MD66; OC 51 = 1.20×max-load / IEC SI / TMS 0.20 initial / 51N 0.20 A sec / TMS 0.15 /
grading 0.3 s CTI / transformer diff 0.30 pu-30%-60% / gen diff start 0.20 pu — all Status C
starting assumptions); Siemens pp.6–7 (15000/1 T1+T2 cores; 458 MVA/22 kV/12019 A/Imax 14309 A/
I2max 7.64 %/K 7.41 s/NER 60 Ω+2.62 Ω??/grid 50 kA estimated/VT residual 381.05);
REV3 verified (GSUT HV 1600/1 5P20 cores; GIS bay 1600/1 5P20+0.2; GCB 10BAC10 22 kV/
12.4 kA/100 kA sym breaking; 7UT6331 transformer diff; GIS 8DN9 bays 2000 A / busbars+coup
ler 3150 A; CTI 300 ms APSCL-confirmed; 46-enabling machine data; GAT HV-N 250/1 T6;
UAT HV 1000/1; 64G/64R/59N/87N/50BF/32R/50-27 GIS-drawing functions; 45 ms fast-main
clearing ENGINEER_DERIVED). Absent from workspace: Siemens pp.8–39 (all 7UM622 function
settings), INEL-DE-0026, DS-0001, Q-capability p.42.

## S3. Provenance class added: USER_ASSERTED_PENDING_DOC

Values supplied from the user's external copy of the Siemens settings pages
(7UM622 50/51 I> ON, inverse disabled, I> = 1.14 A secondary ≈ 17,171 A primary,
t = 3.00 s marked ??/coordination-pending; 87G ≈ 0.20 I/In, high-set ≈ 5.0 I/In,
stabilising slopes; 64G 100 % 20-Hz injection; 59N displacement-voltage 90 %;
50BF presence) enter the registry with provenance USER_ASSERTED_PENDING_DOC and
status PENDING-DOC-INGEST, numerically/visually separated from SOURCE-BACKED rows.
Arithmetic cross-check recorded: 1.20 × Imax 14,309 A = 17,170.8 A ≈ 17,171 A;
17,171/15,000 = 1.1447 A ≈ 1.14 A secondary. Promotion to SOURCE-BACKED only on
document ingest. Timing ?? stays NOT DETERMINABLE until coordination info arrives.

## S4. CT correction (replaces 2000/1 blanket)

GSUT-HV-51 and GIS-Q0-51 CTs become **1600/1 SOURCE-BACKED** (GIS drawing + master §18
default bay connection + rating-plate corroboration). Registry gains physical_CT_ratio,
selected_CT_core, protection_function, study_CT_ratio columns; exact function-core
mapping NOT DETERMINABLE where unconfirmed (master §18: connection depends on bay).
GAT/UAT CTs (GAT HV-N 250/1 T6, T1 dual 500,250/1 tap UNKNOWN; UAT HV 1000/1) mapped for
zone completeness. Legacy-16000/1 sensitivity narrowed to generator CT conflict only
(never substituted into non-generator devices).

## S5. Two-layer generator protection

PHYSICAL baseline GEN-51-SIEMENS-BL: definite-time I>, Is = 17,171 A primary
(1.1447 A secondary, USER_ASSERTED_PENDING_DOC + DERIVED cross-check), tdef = 3.00 s
marked ?? → operating time NOT DETERMINABLE pending confirmation; inverse curve
prohibited on this row. STUDY variant GEN-51-SI (existing IEC-SI, TMS per S6) retained
as ENGINEERING STUDY VARIANT with visual/numeric separation in registry, matrix
(separate device rows), TCCs (separate classes), and report. Same split for earth:
GEN-51N-SI-STUDY (5 A sensitive case) vs physical 51N/59N/64G/64R presence rows
(no invented thresholds; 64G never represented as 3I0 pickup).

## S6. Pickup/TMS/CTI re-baseline

OC study pickups use master §21 rule **1.20 × maximum load current** (GEN: max(12019 A
rated, 14309 A Imax)? — rule says maximum LOAD current: GEN-51-SI pickup recomputed
from stated load basis and documented; GIS/GSUT keep 1.2× FL-anchor construction,
now via 1600/1 CTs). TMS: uniform **0.20 initial** per master §21 (Status C),
replacing invented 0.1/0.2/0.3 grading. CTI **0.3 s upgraded to APSCL/master-confirmed**
(not an assumption). All times/margins recomputed; distribution shifts reported honestly.

## S7. Branch-current doctrine hardened (8.414 kA audit + V9 replacement)

C5 traces leg_GEN_kA for F1 LG to its exact Phase-4 column/equation, determines
total-branch vs superimposed semantics via KCL/phasor evidence, renames the field
(e.g. branch-through-current), and pins it with a regression test. C6 replaces V9
totals-based min-detect with per-relay-CT minimum branch current over zone-relevant
faults, separately for phase OC / residual OC / negative-sequence / differential
(where applicable). Totals (43.76 kA-style) never proxy relay current again.

## S8. Physical registry + zones + 52G

Presence rows (no invented settings): 87G, 46 (sourcing from I2max/K capability where
legit), 40, 32R, 21, 78, 59, 81, 24, 59N, 64G, 64R, 50/27, 50BF, 87/87N/63/49/86 (GSUT),
UAT/GAT functions per CT tables, 87B, 7SS523, 7SD5221×2, 6MD66, 52G/GCB-10BAC10
(12.4 kA/100 kA), Q0/52-1. Zones: G (87G/46/64G/59N/backup-51), T (87/87N/63/49/backup-51),
B (87B/50BF), L (7SD5221×2/21-where-supported). Primary mapping: F1→87G, F2→87T,
F3→87B, F4→7SD. Detection-vs-timing split: detection assertable where branch/diff
current demonstrably exceeds sourced pickup (e.g. F1 LLL 55 kA vs 87G 0.20 pu ≈ 2.4 kA);
timing NOT DETERMINABLE without function settings (except 45 ms derived fast-main
clearing where applicable, labelled). Trip matrix (52G vs Q0, 86 lockout, BF paths):
NOT DETERMINABLE.

## S9. Breaker duty corrected

New columns separate equipment_short_circuit_rating (GIS 50 kA short-time withstand,
SOURCE-BACKED master §17 — never called a breaker rating) from
breaker_interrupting_rating (52G/GCB-10BAC10 100 kA sym breaking, SOURCE-BACKED
REV3/SLD; Q0 interrupting NOT DETERMINABLE). 52G duty rows become DETERMINABLE
(GEN_Q branch vs 100 kA). F3 50.53 kA vs 50 kA equipment value = potential-concern
NOTE, never FAIL. System-reference vs equipment-rating fields separated everywhere.

## S10. Outputs, validation, gate, report

New tag `production-v2` (old tag frozen). Writer gains effectiveness table
(fault/primary-function/availability/primary-time/backup-function/backup-time/
CT-source/setting-source/detection/determinable/not-determinable — mandatory per
review §15) + duty column split + I0_source already present. Validation adds the
§17 list (CT mapping, 16k-scope, Siemens-baseline/variant separation, branch-not-total,
52G, zone mapping, F3→87B, F4→7SD, 51N/64G split, rating split, 8.414 kA trace,
no-conflation). Gate extends with physical predicates + report-vs-CSV spots.
Report rewritten: reclassified scope, study-shortfall language, effectiveness
explanation (§16), unchanged missing-data honesty.

## Self-review

No TBD/TODO (USER_ASSERTED_PENDING_DOC is a defined state with promotion rule, not a
placeholder). Consistent: S5 DT baseline vs S6 SI-study TMS coexist via separate rows;
S4 1600/1 vs master-§18 bay-dependence via core-mapping column. Single-plan scope
(protection alignment only; stability/AVR/SFC excluded). Unambiguous: detection vs
timing split defined in S8; totals-vs-branch rule defined in S7.
