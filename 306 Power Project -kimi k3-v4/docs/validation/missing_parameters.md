# Missing Parameters — Ashuganj 450 MW CCPP (South)

Generator section B.1 was reconciled in REV3.1 Phase 1 against the verified workbook. Other sections retain their earlier scope and qualifications; this phase does not re-audit transformer/grid readiness. No missing value has been filled with a typical or textbook value.

---

## PART A — MISSING AND **BLOCKING** the balanced load flow

| ID | Parameter | Why it blocks | What exists |
|---|---|---|---|
| **M‑B1** | External grid **R** or **X/R** at the 230 kV point of connection | The slack source needs a complete impedance. Only X is given. | X_N = 2.66 Ω, marked *estimated*; S_k″ 19 919 MVA and I_k″ 50 kA, both = √3·230·50, i.e. the GIS withstand rating |
| **M‑B2** | Grid **actual** short-circuit level (measured / PGCB-supplied) | The only figure available equals equipment withstand, giving an unrealistically stiff grid | Form answered "Contact PGCB"; Siemens report says *estimated* |
| **M‑B3** | Generator **dispatch** P for the study case | A load flow needs a defined operating point | Rated 389.30 MW; site-de-rated 342.01 MW; prior model used 389.3 MW. None is a measured dispatch |
| **M‑B4** | Generator **terminal/HV voltage setpoint** (or Q setpoint) | PV bus needs |V|; no measured solved voltage exists anywhere | Excel `12_PSAF_BUS_FIELD_GUIDE` explicitly says 1.0 pu / 0° is "initialization only"; `13_VALIDATION_NOTES` confirms no measured bus voltage was supplied |
| **M‑B5** | Generator **Q_max / Q_min** capability limits | Needed to enforce PV Q-limits | Form's "+241 MVAr" is the rated-point Q, not a limit. The 7-point Excel/DBF curve is untraceable (cites a page not in the project) and truncated — see conflict **C4** |
| **M‑B6** | 230 kV outgoing line **R₁, X₁** | Cannot build any 230 kV line | Nothing. The only R₀/X₀/B₁/length figures in the project sit under a **400 kV** heading = North scope (**C13**) |
| **M‑B7** | 230 kV outgoing line **identity, endpoints, length, circuit count** | Cannot know what the line connects to | Both Rev 03 drawings terminate at "To 230 kV GIS". The South 230 kV GIS one-line (INEL‑112070‑00‑ELC‑DE‑0026) is **not in the project** |
| **M‑B8** | GSUT HV **XLPE cable** length and impedance | Short, but it is the only physical link GSUT→GIS | Rev 03 states only "XLPE CABLE 230 kV". No length, no cross-section, no impedance |
| **M‑B9** | GAT HV **SF₆ bus duct** length and impedance | Only physical link GAT→GIS | Rev 03 states only "SF₆ BUS DUCT" |
| **M‑B10** | GAT normal switching state (in service / standby) | Determines whether the 6.6 kV bus has two sources and the network has a loop | No South document states the normal state — see conflict **C9** |
| **M‑B11** | GAT **Z_PT** and **Z_ST** | Required for a three-winding star equivalent | Only Z_PS = 12 % @25 MVA — see conflict **C17** |
| **M‑B12** | Per-bus **load allocation** (6.6 kV vs 400 V vs water intake) | Determines where load current flows and therefore all branch loadings | Only one aggregate figure: 14 MW @ 0.85 pf. No LV split exists — see conflict **C11** |
| **M‑B13** | **Actual operating** motor loading | Rated shaft kW ≠ electrical demand | 12 motor **nameplate** ratings summing to 14 050 kW (Rev 03 MV MOTOR TABLE) |
| **M‑B14** | Motor **power factor and efficiency** | Without them, rated kW cannot be converted to bus MW/MVAr | Not given per motor anywhere |
| **M‑B15** | **Tap positions in service** for the study case | Tap position directly sets bus voltages | Principal taps are known: GSUT pos 9 (230000 V), GAT pos 13 (230000 V), UAT pos 3 (22000 V). Whether the plant runs on principal taps is not stated |
| **M‑B16** | 230 kV GIS **bus coupler** state (closed / open) | Determines whether BUS 1 and BUS 2 are one node or two | Bus coupler module (3150 A) confirmed to exist; its normal state is not documented |
| **M‑B17** | **Busbar selection per bay** (which of BUS 1 / BUS 2 each bay's Q1/Q2 selects in normal service) | Determines the actual GIS connectivity | Bay device layout is known (Q0/Q1/Q2/Q9), the normal selection is not |
| **M‑B18** | **System base MVA** for the study | Needed for consistent per-unit reporting | Prior PSAF used 100 MVA — but that study was also set to 60 Hz (**C18**) |
| **M‑B19** | GSUT **cooling stage** in service for the study case | Fixes the transformer's MVA rating (355 / 460 / 515) used for % loading | All three stages documented; the operating stage is not |

---

## PART B — MISSING but **NOT blocking** a balanced load flow

### B.1 Generator
| Parameter | Note |
|---|---|
| Detailed rotor-circuit damper reactances/resistances and field reactance | Workbook R3/S3/T3/W3/X3 are blank; do not invent a detailed rotor circuit |
| Field resistance unit and field base | Numeric 0.10631 is supplied at V3; interpretation remains QUALIFIED under the mixed resistance heading |
| Ta(1) | AH3 is blank; supplied Ta or Ta(3) is not a substitute |
| Damping and detailed AVR/governor/PSS/SEMIPOL parameters | Remain missing; Static/SEMIPOL identifies type/designation only |
| Full measured saturation curve / open-circuit characteristic | Two coefficients are supplied, not a complete OCC |
| Armature-resistance temperature and detailed test conditions | Raw ohm value exists; these semantics remain unresolved |
| Capability envelope and actual operating boundary/setpoints | Not resolved by the newly supplied machine data |

**Resolved, no longer missing:** quadrature/leakage/sequence reactances, armature resistance, combined turbine-generator inertia, SCR, all nine supplied time constants, both saturation coefficients, excitation type/designation, 360 MW capacity, and separate unqualified/saturated subtransient reactances. See the authoritative [`ashuganj_generators.m`](../../matlab/data/ashuganj_generators.m:51) and [`generator_list.md`](../model/generator_list.md).

The old 166.3 / 28.65 / 22.48 percent set is explicitly **LEGACY / SATURATED SOURCE DATA**, not saturation-unknown. Generator grounding remains high-resistance NER; workbook GSUT grounding must not be imported. The four historical LF dispatches are unchanged in Phase 1.

### B.2 Transformers
| Parameter | Note |
|---|---|
| Impedance voltage on the **rating plates** | Genuinely **blank** on all three released plates (GSUT, UAT, GAT) — stamped after factory test. Status `NOT_APPLICABLE`, not an extraction failure. Authority is the data sheets, which Rev 03 corroborates exactly |
| Zero-sequence impedances beyond those recorded | Balanced load flow does not use Z₀ |
| Magnetising current / excitation branch | Negligible for load flow; no-load losses are known |
| Winding resistances at other temperatures | 75 °C values documented |
| Impedance-vs-tap arrays for GAT and UAT | GSUT has three points (15.5/16.0/16.9 %); the others have main tap only |

### B.3 LV / auxiliary equipment
| Parameter | Note |
|---|---|
| 10BFT10/20/30/40, 00BFT10 detailed impedance & losses | Only SLD values exist, and Rev 00/Rev 03 disagree (**C16**). Non-blocking because there is **no LV load data to flow through them** |
| 10BMV10 (SFC) and excitation transformer detail | Same |
| 10BTL10/20/30/40 control transformers, 10BLA10/20 and 00BLA10 lighting | Same |
| EDG 10BUK01 / 10BUK02 | Rev 03 **Note 4**: *"DISCONNECTOR SWITCH WILL REMAIN OPEN WHILE EDG IS SYNCHRONIZED WITH THE GRID"* → normally out of service. Not a load-flow source |
| NER 10BAB11 | High-resistance grounding; carries no balanced current |
| UPS and 110 V DC systems | Referenced drawings INEL‑…‑DE‑0011 / ‑0012 are not in the project. Not load-flow items |

### B.4 Protection / instrumentation (recorded for later phases)
CT and VT ratios, burdens and accuracy classes are documented where available; relay types partially (7UT6331 for F12/F13). Full relay schedules, CB interrupting duties beyond ratings, and the 230 kV GIS control/protection one-line (INEL‑112070‑00‑ELC‑DE‑0026) are **missing**. These belong to the protection-coordination phase, not to load flow.

### B.5 Physical / thermal
Oil volumes, masses, cooling-fan/pump kW, temperature rises, dimensions, altitude and ambient data are documented where available and are irrelevant to load flow.

---

## PART C — Referenced documents that do not exist in the project

The Rev 03 SLD's own reference list cites these; none are present:

| Document | Content | Impact |
|---|---|---|
| INEL‑112070‑00‑ELC‑DE‑0026 | **230 kV GIS control, protection & measurement one-line** | Would resolve M‑B6/B7/B16/B17 (line identity, busbar selection, coupler state) |
| INEL‑112070‑00‑ELC‑DE‑0009 | MV one-line diagram | Would resolve M‑B12 (6.6 kV load allocation) |
| INEL‑112070‑00‑ELC‑DE‑0010 | LV one-line diagram | Would resolve the 400 V load split |
| INEL‑112070‑00‑ELC‑DE‑0011 / ‑0012 | UPS / DC one-lines | Non-blocking |
| INEL‑112070‑00‑ELC‑DE‑0030 | Symbology | Non-blocking |
| INEL‑112070‑00‑ELC‑DS‑0001 | **Electrical Design Criteria** | Would likely resolve M‑B2, M‑B15, M‑B18, M‑B19 (grid assumptions, tap philosophy, study bases) |
| S001‑112070‑00‑ELC‑CL‑0002 (full 39 pp) | Generator Protection Setting Report — **Attachment 1 p.42** | Would resolve M‑B5 (Q capability curve). Only pp. 6‑7 are in the project, as `Generator Data_South.pdf` |
| BD1015‑B‑&EFA010‑700506 | Turbine package (SCC5‑PAC 4000F/3000 1S) | Would resolve M‑B3 (site output at ambient) |

**If any of these can be obtained, items M‑B2, M‑B5, M‑B6, M‑B7, M‑B12, M‑B15…M‑B19 become verified data instead of decisions.** That is the single highest-value action available before modelling.
