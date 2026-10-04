# HARDWARE SELECTION v4 — candidate CT / breaker / relay study assumptions

Scope: Ashuganj South 450 MW CCPP unit (458 MVA / 22 kV generator, 515 MVA YNd1 GSUT,
230 kV GIS outlet, 6.6 kV unit switchgear, 110 Vdc control). The original T3 note
was corrected by the September 25 audit. It selects candidate hardware where source data is missing and
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
i.e. < 10 % of the 30 VA rated burden. A preliminary secondary-emf estimate is
E ≈ ALF × Is × (RCT + RB_rated) = 20 × 1 × (RCT + 30) volts,
while the assumed connected burden is lower. This arithmetic is a preliminary
burden screen; it does not establish the actual knee point or transient saturation margin.
Lead length, cross-section and RCT are assumed; exact CT secondary schedule and
excitation curves are verification-only.

Candidate 5P20 class (DERIVED + ENGINEERING_ASSUMPTION):
The F1 total of approximately 126 kA is the sum of sources at the fault point;
it is not the through-current of every CT. The frozen physical-current study
gives a maximum GEN/52G branch current of 55.048710 kA, or 3.670 times a
15000/1 CT rating. The exact core and fault-zone mapping still matters.
5P20 is retained as a candidate class. A ratio to the rated accuracy-limit
factor cannot establish transient 87G/51 stability without actual burden,
winding resistance, excitation curve, fault X/R, DC offset and remanence data.

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

Saturation assessment — not established by this model:
The F3 fault-point total of approximately 50.5 kA is not the current through the
GSUT HV CT. The frozen GSUT_HV/Q0 branch screen has a maximum 6.897015 kA at
230 kV: 4.311 times 1600 A or 4.598 times 1500 A. CT placement and zone must be
confirmed before applying this branch result. Neither these multiples nor a
hypothetical fault-point total prove CT saturation or transient stability.
Actual 7UT restraint settings, burdens and excitation curves remain unverified.
The dynamic model uses ideal measured phasors and 30%/60% half-sum restraint;
it does not implement CT saturation, harmonic blocking or high-set operation.
The added standalone harmonic examples are not a demonstrated mitigation for
CT saturation. LV side (13515 A nameplate, LV bushings
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
0.105 (uk 10.5 %, UAT p.4) ≈ 19.9 kA ⇒ 9.96× on 2000/1, below the nominal
20× accuracy-limit factor at rated burden. This does not validate transient
performance or motor-start coordination. The candidate 2000/1 gives normal
secondary current 0.72 A vs 0.58 A for 2500/1. UAT HV side keeps source
1000/1 5P20 30 VA (UAT p.8 — VERIFIED). Feeder CT burden 15 VA assumed (relay +
leads < 2 VA, same form as §1); exact aux single-line loads are verification-only.

## 4. Breakers

| Device | Recommended duty | Basis | Status |
|---|---|---|---|
| 52G generator breaker (GCB) | Existing study rating 100 kA; maximum frozen 52G branch initial current 55.048710 kA (55.05%). Candidate 24 kV / 16000 A and opening 35–45 ms / break ≤70 ms remain study assumptions. A 130 kA upgrade and 330 kA making rating cannot be derived from the aggregate F1 fault total. | Phase-5 physical branch duty table; GEN / SLD mapping | Initial-current screen only; installed rating, making/DC/TRV and times require verification |
| Q0 230 kV GIS bay (transformer outlet) | Conditional 2000 A / 50 kA / 125 kA peak / 3 s mapping; maximum frozen Q0 branch 6.897015 kA (13.79% of 50 kA). A same-basis 53 kA demand exceeds 50 kA (106%); it is not covered. A hypothetical 63 kA candidate against 54.4 kA has 8.6 kA headroom, 13.65% of rating (15.81% of demand), not an established worst credible South duty. | Phase-5 branch-current screening and conditional transformer-bay mapping | CONDITIONAL_ASSUMPTION; exact Q0 mapping, contact time, DC/TRV and making duty unverified |
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
| Siemens 7UT6331 (transformer differential) | 87T GSUT study: HV 1600/1 vs LV 15000/1-class, YNd1 compensation, slopes 30%/60%, 0.045 s proxy. Dynamic tap-adaptive matching, CT saturation and harmonic restraint are not implemented; installed algorithm/settings require verification. |
| Siemens 7SS523 (busbar) | 87B 230 kV GIS bus, 320 A / 0.035 s study proxy on 1600 A GIS CT base |
| Siemens 7SD5221 (line differential, main) | 87L South 0.7 km XLPE outlet + distance 21 backup (Zone-1 80 % / Zone-2 120 % / Zone-3 200 % study reaches); remote-end + comms settings verification-only |

All pickup/time values are Phase-5 study proxies (ENGINEERING_STUDY_PROXY); no
commissioned setting file has been seen — verification-only before any trip test.
The 64G and distance-21 ledger values do not imply those functions are implemented
in the dynamic model. Its implemented relay set is stated in `NOT_DETERMINABLE_REGISTER.md`.

## 6. NER / NGT and finite study assumptions

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
  these are candidate values, not an explicitly modelled tower/soil return path.
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
3. CT transient performance is unresolved; fault-point totals are not GSUT CT
   through-currents and dynamic harmonic/CT-saturation models are absent (§2).
4. 6.6 kV feeder 2000/1 5P20 15 VA for ~1441 A load — wholly new pick, no source CT (§3).
5. 52G 100 kA study rating / Q0 conditional 50 kA / 6.6 kV 31.5 kA.
   Branch-current screening does not establish full breaking/making duty (§4).
6. All relay pickups/times are study proxies, not commissioned settings (§5).
7. NER 1750.77 Ω derived from qualified entries, not measured (§6).
8. R0/X0/B0, soil 100 Ω·m, footing 15 Ω, burdens ≤2 VA are finite study
   assumptions. The baseline grid still has R=0; candidate hardware values
   do not automatically change runtime blocks (§6).
9. 400 kV data is regional envelope only; South duty is 230 kV (§4 note).
10. Grid 50 kA is a 2014 Siemens estimate (GEN p.7) — current PGCB sequence
    equivalent + fault-level date verification-only.

What remains verification-only (no further study picks): as-installed CT core/tap
schedule + excitation curves + burdens; commissioned 7UM62/7UT/7SS/7SD setting
files; Q0 bay nameplate mapping + TRV/DC/timing certificates; NGT/resistor
nameplates + measured resistance; current PGCB short-circuit equivalent; South
route/conductor geometry; DC distribution schedule.
