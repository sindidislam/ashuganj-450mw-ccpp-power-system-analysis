# HARDWARE SELECTION v4 — CT / Breaker / Relay Best-Fit (T3)

Scope: Ashuganj South 450 MW CCPP unit (458 MVA / 22 kV generator, 515 MVA YNd1 GSUT,
230 kV GIS outlet, 6.6 kV unit switchgear, 110 Vdc control). This file is the ONLY
write product of T3. It selects realistic hardware where source data is missing and
records every non-source value as an ENGINEERING_ASSUMPTION with basis. Nothing here
replaces nameplate/setting-file verification before commissioning.

Status tags used: VERIFIED (source page cited) | DERIVED (arithmetic on verified inputs)
| ENGINEERING_ASSUMPTION (study-grade pick, verification-only remaining)
| CONDITIONAL_ASSUMPTION (pick depends on an unproven mapping).

Source shorthand: GEN=Generator Data_South.pdf (Siemens protection report BD1015),
GSUT=GSUT Data Sheet_South.pdf (CTI S009-112070-00-ELC-HD-0001), SLD=Single Line
Diagram_South.pdf (GHES-112070-00-ELC-DE-0001), LINES=Line data.pdf,
UAT=UAT Data Sheet_South.pdf (STWH-579UAT/GAT-0007). All under
`fwdtechnicaldatasldrequestforbueteeetermproject/`.

---

## 1. Generator terminal + neutral CTs (15000/1) — VERIFIED, with study completion

| Item | Recommended rating | Basis (doc + page) | Status |
|---|---|---|---|
| GEN phase CTs T1 (star-point) + T2 (bus-duct), 3 cores each | 15000/1 A, 1 A secondary; protection cores 5P20, rated burden 30 VA | GEN p.6 (report §2.1.2): six cores listed 15000/1, system-1 / measurement / system-2 | VERIFIED (ratio); protection class/burden ENGINEERING_ASSUMPTION per §6 |
| Neutral-side application | Same 15000/1 cores T1 feed 87G + 51; separate sensitive ground path per Phase-5 51N study (20/1 dial) retained | GEN p.6; PHASE5_ASSUMPTIONS.csv GEN_51N rows | VERIFIED (main CT); 51N CT ENGINEERING_ASSUMPTION |

Burden / lead calculation (ENGINEERING_ASSUMPTION, verification-only):
SIPROTEC 7UM62 current-input burden ≈ 0.05–0.3 VA (≈ 0.05–0.3 Ω at 1 A) per Siemens
7UM62 manual technical data; loop of ~50 m 2.5 mm² Cu
R = 2 × 50 × 0.0175 / 2.5 ≈ 0.70 Ω (≈ 0.7 VA at 1 A). Total connected burden ≈ 1–2 VA,
i.e. < 10 % of the 30 VA rated burden. Knee-point form
Vk ≥ ALF × Is × (RCT + RB_rated) = 20 × 1 × (RCT + 30) ⇒ several hundred volts,
while the actual burden needs only a small fraction — large saturation margin.
Lead length, cross-section and RCT are assumed; exact CT secondary schedule and
excitation curves are verification-only.

Knee-point / why-5P20 reasoning (DERIVED + ENGINEERING_ASSUMPTION):
Worst LV through-fault F LV ≈ generator 53.5 kA (12019 / 0.2248, saturated Xd″)
+ grid infeed via GSUT ≈ 72.7 kA (13515.2 A LV nameplate / (0.0259 + 0.16) pu on
515 MVA base, Xgrid = 2.66 Ω per GEN p.7) ≈ 126 kA total ⇒ 126 / 15 = 8.4× CT
rated current. 5P10 would leave only 10 / 8.4 = 1.19× margin — insufficient once DC
offset, remanence and transient overdimensioning (IEC 61869-2, Ktd factor) are
considered. 5P20 gives 20 / 8.4 = 2.38× margin: adequate for 87G/51 stability on
external faults. Hence 5P20, not 5P10. Actual X/R and DC time constant at the 22 kV
bus are verification-only.

## 2. GSUT HV CT conflict 1600/1 vs 1500/1 — dual-track recommendation

| Item | Recommended rating | Basis | Status |
|---|---|---|---|
| GSUT HV protection cores | Study: 1600/1 5P20 30 VA (matches HV bushings 1600 A, GSUT nameplate CT track, SLD 1600/1-class indication) | GSUT p.3–4 (bushing 1600 A; neutral CT 1600/1 30 VA 5P20); SLD 1600/1-class entries | ENGINEERING_ASSUMPTION (central study) |
| Documentary sensitivity | 1500/1 5P20 30 VA retained as sensitivity case (manufacturer HV protection-core entry) | GSUT p.4 §1.6.1 "1500/1, 30 VA, 5P20" | VERIFIED (documentary conflict) |
| GSUT HV metering core | 1600/1, Cl 0.2S, 5 VA | GSUT p.4 §1.6.1 | VERIFIED |
| GSUT HV neutral CT | 1600/1 5P20 30 VA (2 pcs, 1 option) | GSUT p.4 §1.6.2 | VERIFIED |

Secondary currents at HV rated 1292.8 A (515 MVA / √3 / 230 kV — DERIVED, VERIFIED inputs):
1600/1 → 0.808 A; 1500/1 → 0.862 A. Study 51 pickup 1380 A ⇒ 0.863 A (1600-base)
or 0.920 A (1500-base).

Saturation check — SATURATION FLAG (DERIVED, inputs verified/assumed):
Worst HV through-fault F3 ≈ 50 kA Siemens-estimated grid (GEN p.7) + ~3.1 kA plant
infeed (generator subtransient via GSUT: 32.7 kA at 22 kV ⇒ × 22/230) ≈ 50.5–53 kA.
CT multiples: 50.5/1.6 = 31.6× (1600-base), 50.5/1.5 = 33.7× (1500-base) — both
above the 5P20 accuracy-limit factor of 20×. The HV protection cores WILL saturate
on close-in 230 kV faults. Mitigation relied upon (ENGINEERING_ASSUMPTION):
Siemens 7UT6331 differential with 2nd-harmonic inrush restraint + 5th-harmonic
overflux restraint, high-set unrestrained stage blocked/graded for saturated
through-faults, and bias slopes 30 %/60 % per Phase-5 study proxy. For EXTERNAL HV
faults saturation only risks overfunction of low-impedance schemes — bus/line zones
keep directional/time grading as back-stop. Exact 7UT restraint settings and CT
excitation curves are verification-only. LV side (13515 A nameplate, LV bushings
20000 A per GSUT p.2) uses the generator 15000/1-class / IPB CT path — protection
core schedule verification-only.

## 3. 6.6 kV feeder CT — new selection (source has no feeder CT)

| Item | Recommended rating | Basis | Status |
|---|---|---|---|
| 6.6 kV incomer/feeder protection CTs | 2000/1 A, 5P20, 15 VA (preferred); 2500/1 A acceptable alternate matching SWGR frame | No source feeder CT exists (SLD shows only 2500/1 incomer-class + 1000/1 entries; UAT HV CT 1000/1 per UAT p.8) | ENGINEERING_ASSUMPTION |

Justification (DERIVED on verified UAT/SWGR ratings):
Running aux load adopted ≈ 1441 A (below UAT ONAN 19 MVA ⇒ 1590 A at 6.9 kV;
ONAF 25 MVA ⇒ 2092 A — DERIVED from UAT p.4). 1.2× pickup = 1729 A ⇒ 0.865 A
secondary on 2000/1 (0.692 A on 2500/1) — comfortably in relay metering band.
Continuous margin (2000 − 1441)/1441 = 38.8 %. LV through-fault via UAT ≈ 2092 /
0.105 (uk 10.5 %, UAT p.4) ≈ 19.9 kA ⇒ 9.96× on 2000/1 — inside 5P20. 2000/1 is
preferred over 2500/1 (normal secondary 0.72 A vs 0.58 A: better accuracy at load
while still clearing max load + motor-start duty). UAT HV side keeps source
1000/1 5P20 30 VA (UAT p.8 — VERIFIED). Feeder CT burden 15 VA assumed (relay +
leads < 2 VA, same form as §1); exact aux single-line loads are verification-only.

## 4. Breakers

| Device | Recommended duty | Basis | Status |
|---|---|---|---|
| 52G generator breaker (GCB) | Ur 24 kV; Ir 16000 A (covers Imax 14309 A, GEN p.6); Isc ≥ 130 kA class (covers 126 kA LLL §1), asymmetrical/making 2.55× ⇒ ≈ 330 kA peak, DC time constant ≥ 133 ms per IEEE C37.013 / IEC 62271-100 GCB duty; opening 35–45 ms, break ≤ 70 ms (assumed) | GEN p.6–7 ratings + §1 fault derivation; SLD 52G symbol | Ratings DERIVED; times ENGINEERING_ASSUMPTION |
| Q0 230 kV GIS bay (transformer outlet) | Conditional duty: 2000 A / 50 kA / 125 kA peak / 3 s (transformer-bay class; 125 = 2.5 × 50 per IEC 62271-100 §4.103) — covers F3 ≈ 53 kA with thin margin. Future-proof option: 63 kA GIS (margin (63 − 54.4)/54.4 = 15.8 % over worst credible 54.4 kA = 50 grid + 3.1 gen + 1.3 motor infeed) | Phase-5 Q0 conditional rows; GEN p.7 grid estimate; IEC 62271-100 | CONDITIONAL_ASSUMPTION — exact Q0 physical mapping verification-only |
| 6.6 kV vacuum incomer/feeders | 7.2 kV, 2500 A (incomer frame) / 630–1250 A feeders, 31.5 kA (matches SWGR 6600 V 2500 A 31.5 kA, SLD), making 2.5 × 31.5 ≈ 78.8 kA peak; opening 40–60 ms, break ≤ 75 ms (assumed) | SLD "MV BUSBAR 6600 V, 2500 A, 31.5 kA"; UAT p.4–5 31.5 kA LV withstand | VERIFIED (rating); times ENGINEERING_ASSUMPTION |

Breaker duty note — 230 kV actual vs 400 kV envelope: South connects at 230 kV
(GEN p.7; SLD "To 230 kV GIS"). There is NO 400 kV GIS at South. The 400 kV
Ashuganj(N)–Bhulta 69 km Twin-Finch line (LINES 400 kV table row 5) is a REGIONAL
reference only and must never be inserted as South bay duty. The 230 kV regional
lines that locate South electrically are Ghorasal–Ashuganj 44 km Mallard 795
(230 kV table row 3) and Ashuganj–Comilla(N) 79 km Finch 1113 (row 5);
Ashuganj–Kishoreganj 52 km is a 132 kV-table line (row 25) — not 230 kV.
TRV, out-of-phase, short-line-fault and DC-component capabilities per IEC 62271-100
selection guide (§8.103/§9.103) are verification-only against vendor test certificates.

## 5. Relays — one-line role table

| Relay | Role in South scheme |
|---|---|
| Siemens 7UM62 (generator multifunction) | 87G generator differential (terminal-vs-neutral 15000/1, §1); 51/51V backup overcurrent 17170.8 A / TMS 0.1 study; 51N sensitive stator-ground via dedicated neutral path; 64G 100 % stator-earth (20 Hz injection defaults per Phase-5 64G rows) |
| Siemens 7UT6331 (transformer differential) | 87T GSUT (HV 1600/1 vs LV 15000/1-class, YNd1 vector compensation + tap-adaptive matching in-relay); slopes 30 %/60 %, 0.045 s study proxy; harmonic restraint carries the §2 saturation flag |
| Siemens 7SS523 (busbar) | 87B 230 kV GIS bus, 320 A / 0.035 s study proxy on 1600 A GIS CT base |
| Siemens 7SD5221 (line differential, main) | 87L South 0.7 km XLPE outlet + distance 21 backup (Zone-1 80 % / Zone-2 120 % / Zone-3 200 % study reaches); remote-end + comms settings verification-only |

All pickup/time values are Phase-5 study proxies (ENGINEERING_STUDY_PROXY); no
commissioned setting file has been seen — verification-only before any trip test.

## 6. NER / NGT + missing-data practical values (never 0)

- NER/NGT (DERIVED, qualified inputs GEN p.7 §2.3): 60 Ω HV-winding DC component
+ reflected LV loading 25.4034² × 2.62 = 1690.77 Ω ⇒ effective HV-side
1750.77 Ω. Stated as DERIVED from question-marked entries — not a measured neutral
resistance; as-installed test value verification-only. NGT 135 kVA/20 s,
12.70 kV/500 V — VERIFIED (GEN p.7).
- Missing R0/X0/B0 (South 0.7 km outlet): frozen Phase-5 study values retained
(R1 0.08, X1 0.35, B1 4.2 µS/km; R0 0.25, X0 1.2, B0 2.8 µS/km — all
ENGINEERING_ASSUMPTION, route survey verification-only). Regional 230 kV OHL
screening (Mallard 795, single cct, ~7.5 m spacing, IEC 60909-2 typical geometry):
R1 0.075, X1 0.48, B1 3.4 µS/km; R0 0.28, X0 1.35, B0 2.3 µS/km —
ENGINEERING_ASSUMPTION, tower geometry verification-only.
- Tower/soil (ENGINEERING_ASSUMPTION, Bengal-delta alluvium typicals, IEEE 80-2013
range): soil resistivity 100 Ω·m (50–150 range); tower footing 15 Ω (10–20 range);
neither is 0 — zero-sequence return path stays finite.
- CT burdens where unsourced (§1 form): relay ≤ 0.3 VA + leads ≈ 0.7 VA ⇒ adopt
connected ≤ 2 VA vs rated 15–30 VA — ENGINEERING_ASSUMPTION; excitation curves
verification-only.
- Breaker contact times: §4 table — ENGINEERING_ASSUMPTION; nameplate timing +
50BF wiring verification-only. DC control 110 V per SLD (220 Vdc sections exist
elsewhere) — distribution schedule verification-only.

## 7. Assumption register (top items; full numerics in PHASE5_ASSUMPTIONS.csv)

1. GEN protection cores 5P20 30 VA on verified 15000/1 — class/burden assumed (§1).
2. GSUT HV central study 1600/1 vs documentary 1500/1 — dual track; exact installed
   protection core/tap unverified (§2).
3. Saturation flag: GSUT HV cores 31–34× on F3 > 5P20 20× — 7UT harmonic restraint
   reliance assumed (§2).
4. 6.6 kV feeder 2000/1 5P20 15 VA for ~1441 A load — wholly new pick, no source CT (§3).
5. 52G 130 kA-class / Q0 conditional 50 kA (63 kA future-proof, 15.8 % margin) /
   6.6 kV 31.5 kA — duty derived, mapping + timings assumed (§4).
6. All relay pickups/times are study proxies, not commissioned settings (§5).
7. NER 1750.77 Ω derived from qualified entries, not measured (§6).
8. R0/X0/B0, soil 100 Ω·m, footing 15 Ω, burdens ≤ 2 VA — finite practical
   substitutes, never 0 (§6).
9. 400 kV data is regional envelope only; South duty is 230 kV (§4 note).
10. Grid 50 kA is a 2014 Siemens estimate (GEN p.7) — current PGCB sequence
    equivalent + fault-level date verification-only.

What remains verification-only (no further study picks): as-installed CT core/tap
schedule + excitation curves + burdens; commissioned 7UM62/7UT/7SS/7SD setting
files; Q0 bay nameplate mapping + TRV/DC/timing certificates; NGT/resistor
nameplates + measured resistance; current PGCB short-circuit equivalent; South
route/conductor geometry; DC distribution schedule.
