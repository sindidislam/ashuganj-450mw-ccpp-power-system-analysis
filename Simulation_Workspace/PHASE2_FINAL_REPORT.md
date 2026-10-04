# REV3.1 PHASE 2 FINAL AUDIT, CORRECTION & VALIDATION REPORT
## ASHUGANJ SOUTH 450 MW CCPP (EEE 306 POWER PROJECT)

**Project:** Ashuganj 450 MW Combined Cycle Power Plant (South)  
**Academic Level / Course:** Level 3 Term 1 / EEE 306 Power System Analysis  
**Project Phase:** REV3.1 — Phase 2 Final Audit, Claim-Precision Cleanup & Closure  
**Date:** September 2026  
**Status:** Phase 2 implementation complete; final documentation/source-claim cleanup completed. **READY FOR SEPARATE PHASE 3 AUTHORIZATION** (Full regression suite reported by the implementation: 1331 passed, 0 failed)  

> [!IMPORTANT]
> **Phase 3 fault-analysis implementation has NOT been performed.**  
> Zero Phase 3 modifications (fault analysis, short-circuit current calculations, sequence networks, protection coordination, relay settings, or dynamic transient-stability swing studies) are included in this deliverable. Rev2 files remain 100% byte-identical.

---

## TABLE OF CONTENTS
- [Section 1: Scope & Boundaries](#section-1-scope--boundaries)
- [Section 2: Files Changed](#section-2-files-changed)
- [Section 3: Files Protected / Unchanged](#section-3-files-protected--unchanged)
- [Section 4: Authoritative Generator Data](#section-4-authoritative-generator-data)
- [Section 5: Xd'' vs Xd''sat Distinction](#section-5-xd-vs-xdsat-distinction)
- [Section 6: Ra Base Conversion](#section-6-ra-base-conversion)
- [Section 7: Q Capability Curve](#section-7-q-capability-curve)
- [Section 8: 360 MW Capability Interpolation](#section-8-360-mw-capability-interpolation)
- [Section 9: Operating-Case Classification & Capacity Guard](#section-9-operating-case-classification--capacity-guard)
- [Section 10: Excitation System & SEMIPOL Distinction](#section-10-excitation-system--semipol-distinction)
- [Section 11: Static Frequency Converter (SFC)](#section-11-static-frequency-converter-sfc)
- [Section 12: Station DC Auxiliary System, Battery & Charger](#section-12-station-dc-auxiliary-system-battery--charger)
- [Section 13: Governor / Turbine Model](#section-13-governor--turbine-model)
- [Section 14: Generator-Terminal Voltage Reporting Correction](#section-14-generator-terminal-voltage-reporting-correction)
- [Section 15: Regression Evidence & Benchmark Reproducibility](#section-15-regression-evidence--benchmark-reproducibility)
- [Section 16: Source-vs-Assumption Traceability](#section-16-source-vs-assumption-traceability)
- [Section 17: Remaining Genuine Data Gaps](#section-17-remaining-genuine-data-gaps)
- [Section 18: Phase 3 Readiness Confirmation](#section-18-phase-3-readiness-confirmation)
- [Section 19: Final Limitations](#section-19-final-limitations)

---

## SECTION 1: SCOPE & BOUNDARIES

Phase 2 of the REV3.1 engineering remediation program for the Ashuganj South 450 MW Combined Cycle Power Plant (CCPP) addresses load-flow operating-case migration, OEM generator capability curve integration, practical non-ideal engineering assumptions, isolated subsystem dynamic models, and comprehensive data consistency.

### Strict Phase 2 Boundary Definition:
- **IN SCOPE (Phase 2 Deliverable)**:
  1. Operating case migration to primary $360.00\text{ MW}$ active-power capacity.
  2. Authoritative 6-point generator P-Q capability curve and non-clipping margin evaluation.
  3. Enforcement of runtime capacity guard rejecting active dispatch above $360.00\text{ MW}$ unless an explicit historical exception is provided.
  4. Non-ideal, finite engineering assumptions for unmeasured parameters (Excitation, SFC, Station DC/Battery/Charger, Governor, PSS).
  5. Isolated discrete-time component models with finite response lags, non-zero internal resistance, and physical limiters.
  6. Generator dynamic model data packaging for 6th-order synchronous machine readiness.
  7. Independent active and reactive power balance reconstruction and KCL verification.
  8. Root-cause technical diagnosis and reporting correction for generator terminal voltage.
  9. Rigorous claim-precision cleanup reconciling documentation with verified runtime implementations.
- **OUT OF SCOPE (Strictly Deferred to Phase 3 & Beyond — NOT IMPLEMENTED)**:
  1. Fault analysis, short-circuit current calculations (LLL, LG, LL, LLG).
  2. Sequence network impedance matrices ($Z_{012}$, $Y_{\text{bus},012}$).
  3. IEC 60909 fault calculations ($\kappa$-factor, $I_k''$, $i_p$, $I_b$).
  4. Protection coordination, relay settings, trip curves, and grading margins.
  5. Breaker duty evaluation, interrupting ratings, CT saturation checks.
  6. Multi-machine transient stability swing simulations.
  7. Modification of frozen solver physics, network topology, or historical baseline datasets.

---

## SECTION 2: FILES CHANGED

The following files were modified during the Phase 2 implementation, repair, and final claim-precision cleanup:

1. [`matlab/build/build_ashuganj_main.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/build/build_ashuganj_main.m#L160-L162)
   - **Reason**: Task 4 Capacity-Guard enforcement.
   - **Exact Change**: Added `validate_operating_profile(C)` directly to the authoritative runtime build path to programmatically reject unapproved cases exceeding $360.00\text{ MW}$.
2. [`matlab/data/ashuganj_operating_profiles.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/data/ashuganj_operating_profiles.m#L49-L65)
   - **Reason**: Task 4 Profile resolution guard.
   - **Exact Change**: Enforced profile validation during struct retrieval.
3. [`matlab/tests/test_operating_profiles.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/tests/test_operating_profiles.m#L125-L155)
   - **Reason**: Task 4B real entry-path verification.
   - **Exact Change**: Added automated test cases proving $360.00\text{ MW}$ is accepted, $360.01\text{ MW}$ is rejected with `CapacityExceeded`, and $389.30\text{ MW}$ requires `approved_exception = true`.
4. [`matlab/analysis/phase2_dc_step.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/analysis/phase2_dc_step.m#L117-L137)
   - **Reason**: Task 8 Option A closed-loop charger regulation.
   - **Exact Change**: Implemented finite closed-loop voltage regulation toward $V_{\text{float}} = 123.75\text{ V}$ with finite lag $\tau = 0.1\text{ s}$, current limit $180\text{ A}$, and power limit $20\text{ kW}$.
5. [`matlab/tests/test_phase2_component_models.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/tests/test_phase2_component_models.m#L234-L245)
   - **Reason**: Task 8 verification of float regulation.
   - **Exact Change**: Added test 3.9 asserting convergence of DC bus voltage to $123.75\text{ V} \pm 0.01\text{ V}$ in float equilibrium.
6. [`matlab/analysis/validate_phase2_load_flow.m`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/matlab/analysis/validate_phase2_load_flow.m#L51-L65)
   - **Reason**: Task 10 generator voltage reporting repair.
   - **Exact Change**: Applied `abs()` and `angle()` to extract physical magnitude and angle from complex bus phasors, eliminating the real-part Cartesian coordinate truncation artifact.
7. [`PHASE2_FINAL_REPORT.md`](file:///g:/Other%20computers/My%20Computer%20%282%29/Level%203%20Term%201/306%20Power%20Project%20-gemini%20flash/PHASE2_FINAL_REPORT.md)
   - **Reason**: Task-by-task documentation audit, claim-precision alignment, and report finalization.
   - **Exact Change**: Purged IEEE 485 compliance claims; corrected 360 MW provenance to supplied workbook Row 3 (Cell B3); audited Q curve physical limiting labels as engineering interpretations; refined generator terminal voltage wording; aligned test evidence descriptions; structured into 19 numbered sections.

---

## SECTION 3: FILES PROTECTED / UNCHANGED

The following repositories, directories, and data structures were strictly protected and remain untouched:
- **`rev2/` Directory**: Confirmed **100% byte-identical** against the baseline hash catalog (`docs/validation/rev31_phase2/baseline_hashes.csv`). All 46 Rev2 files are untouched.
- **Fault Analysis Scripts**: Zero fault calculation files or sequence network scripts were created, modified, or executed.
- **Protection & Relays**: Zero protection coordination, breaker sizing, or relay setting files were altered.
- **Solver Physics & Equations**: Core load-flow equations, Newton-Raphson Jacobian formulations, and branch admittance matrices in `solve_load_flow.m` are untouched.
- **Historical Benchmark Datasets**: The historical load-flow regression dataset in `docs/validation/rev31_phase2/baseline_lf.mat` is preserved without alteration.
- **Source Workbooks and PDFs**: Original project documents (`Ahsuganj South (2).xlsx`, `Generator Data_South.pdf`,广州 Siemens datasheets) remain read-only references.

---

## SECTION 4: AUTHORITATIVE GENERATOR DATA

The authoritative primary generator dataset is maintained in `matlab/data/ashuganj_generators.m` based on the official project workbook `Ahsuganj South (2).xlsx` (Row 3):

| Parameter | Symbol | Value | Unit | Base / Condition | Status |
|---|:---:|:---:|:---:|:---:|:---:|
| Rated Apparent Power | $S_{\text{nom}}$ | 458.00 | MVA | Machine Nameplate | `PRIMARY_VERIFIED` |
| Primary Active Capacity | $P_{\text{cap}}$ | 360.00 | MW | Workbook Row 3 (Cell B3: 'Capacity (MW)') | `PRIMARY_VERIFIED` |
| Rated Terminal Voltage | $V_{\text{nom}}$ | 22.00 | kV | Line-to-Line RMS | `PRIMARY_VERIFIED` |
| Rated Frequency | $f$ | 50.0 | Hz | Grid Nominal | `PRIMARY_VERIFIED` |
| Reference Power Factor | $\text{PF}_{\text{ref}}$ | 0.85 | — | Lagging | `PRIMARY_VERIFIED` |
| Combined Train Inertia | $H$ | 5.287 | s | 458 MVA Base | `PRIMARY_VERIFIED` |
| Short Circuit Ratio | $\text{SCR}$ | 0.601 | — | Air Gap / Saturated | `PRIMARY_VERIFIED` |
| D-axis Synchronous Reactance | $X_d$ | 1.7830 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| D-axis Transient Reactance | $X_d'$ | 0.3256 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| D-axis Subtransient Reactance | $X_d''$ | 0.2608 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| Saturated Subtransient Reactance | $X_d''\text{sat}$ | 0.2248 | pu | 458 MVA, 22 kV (sat) | `PRIMARY_VERIFIED` |
| Q-axis Synchronous Reactance | $X_q$ | 1.7510 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| Q-axis Transient Reactance | $X_q'$ | 0.5087 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| Q-axis Subtransient Reactance | $X_q''$ | 0.2593 | pu | 458 MVA, 22 kV (unsat) | `PRIMARY_VERIFIED` |
| Stator Leakage Reactance | $X_l$ | 0.2027 | pu | 458 MVA, 22 kV | `PRIMARY_VERIFIED` |
| Negative Sequence Reactance | $X_2$ | 0.2242 | pu | 458 MVA, 22 kV | `PRIMARY_VERIFIED` |
| Zero Sequence Reactance | $X_0$ | 0.1280 | pu | 458 MVA, 22 kV | `PRIMARY_VERIFIED` |
| Armature DC Resistance | $R_a$ | 0.00089 | $\Omega$ | Raw Physical Value | `PRIMARY_VERIFIED` |
| Field Winding Resistance | $R_f$ | 0.10631 | unresolved | Unit/base unresolved | `PRIMARY_SOURCE_QUALIFIED` |
| Open-Circuit Time Constant | $T_{d0}'$ | 7.547 | s | Direct-axis transient | `PRIMARY_VERIFIED` |
| Open-Circuit Time Constant | $T_{d0}''$ | 0.045 | s | Direct-axis subtransient | `PRIMARY_VERIFIED` |
| Open-Circuit Time Constant | $T_{q0}'$ | 0.839 | s | Q-axis transient | `PRIMARY_VERIFIED` |
| Open-Circuit Time Constant | $T_{q0}''$ | 0.070 | s | Q-axis subtransient | `PRIMARY_VERIFIED` |
| Short-Circuit Time Constant | $T_d'$ | 1.213 | s | Direct-axis transient | `PRIMARY_VERIFIED` |
| Short-Circuit Time Constant | $T_d''$ | 0.035 | s | Direct-axis subtransient | `PRIMARY_VERIFIED` |
| Short-Circuit Time Constant | $T_q'$ | 0.214 | s | Q-axis transient | `PRIMARY_VERIFIED` |
| Short-Circuit Time Constant | $T_q''$ | 0.035 | s | Q-axis subtransient | `PRIMARY_VERIFIED` |
| Armature Short-Circuit Time | $T_a$ | 0.704 | s | Direct 3-phase short | `PRIMARY_VERIFIED` |
| Saturation Factor 1.0 pu | $S(1.0)$ | 0.0865 | — | Open-circuit curve | `PRIMARY_VERIFIED` |
| Saturation Factor 1.2 pu | $S(1.2)$ | 0.4080 | — | Open-circuit curve | `PRIMARY_VERIFIED` |

---

## SECTION 5: XD'' VS XD''SAT DISTINCTION

A critical requirement of the Phase 2 audit is preserving the distinct physical meanings of saturated and unsaturated subtransient reactances:
- **Standard Dynamic Machine Subtransient Reactance**:
  $$X_d'' = \mathbf{0.2608\text{ pu}} \quad (458\text{ MVA}, 22\text{ kV})$$
  This represents the unsaturated direct-axis subtransient reactance governing electromagnetic transient rotor flux dynamics in 6th-order machine representations.
- **Saturated Short-Circuit Subtransient Reactance**:
  $$X_d''\text{sat} = \mathbf{0.2248\text{ pu}} \quad (458\text{ MVA}, 22\text{ kV})$$
  This represents the subtransient reactance under heavy iron core saturation during close-in short-circuit conditions, as specified in Siemens Protection Setting Report §2.1.1 and Workbook Cell K3.

These two parameters must never be collapsed, averaged, or used interchangeably.

---

## SECTION 6: RA BASE CONVERSION

The primary raw armature resistance extracted from Workbook Cell U3 is:
$$R_a = 0.00089\,\Omega$$

### Machine Impedance Base Conversion ($458\text{ MVA}, 22\text{ kV}$):
$$Z_{\text{base,458}} = \frac{V_{\text{nom}}^2}{S_{\text{nom}}} = \frac{22^2}{458} = \mathbf{1.056768558951965\,\Omega}$$
$$R_{a,\text{pu(gen)}} = \frac{0.00089}{1.056768558951965} = \mathbf{0.000842190082644628\text{ pu}}$$

### System Impedance Base Conversion ($100\text{ MVA}, 22\text{ kV}$):
$$Z_{\text{base,100}} = \frac{V_{\text{nom}}^2}{S_{\text{base,sys}}} = \frac{22^2}{100} = \mathbf{4.840000000000000\,\Omega}$$
$$R_{a,\text{pu(sys)}} = \frac{0.00089}{4.84} = \mathbf{0.000183884297520661\text{ pu}}$$

### Field Resistance ($R_f$):
$$R_f = 0.10631 \quad (\text{Workbook Cell V3})$$
The unit and field base remain unresolved in source documentation (`PRIMARY_SOURCE_QUALIFIED`). Stator base conversions are not applied to field parameters without verified field circuit excitation data.

---

## SECTION 7: Q CAPABILITY CURVE

The authoritative six-point generator P-Q capability curve is extracted from the Siemens Generator Protection Setting Report (`BD1015-10CHA-&EFQ030-760522`, Attachment 1):

| Point | Active Power $P$ [MW] | Maximum Overexcitation $Q_{\max}$ [MVAr] | Minimum Underexcitation $Q_{\min}$ [MVAr] | Physical Limiting Regime<br>*(Engineering interpretation — not directly extracted from the six numerical source points)* |
|:---:|:---:|:---:|:---:|---|
| **1** | 0.0 | +335.0 | -231.0 | Rotor field winding thermal heating / Stator core end-iron heating |
| **2** | 100.0 | +329.0 | -231.0 | Rotor field winding thermal heating / Stator core end-iron heating |
| **3** | 200.0 | +311.0 | -220.0 | Rotor field winding thermal heating / Stator core end-iron heating |
| **4** | 300.0 | +280.0 | -205.0 | Rotor field winding thermal heating / Practical steady-state stability margin |
| **5** | 389.3 | +241.0 | -182.0 | Continuous nameplate rating point ($458\text{ MVA}, 0.85\text{ PF}$) |
| **6** | 458.0 | 0.0 | 0.0 | Stator MVA thermal boundary intercept ($\sqrt{S^2 - P^2} = 0$) |

- **Classification**: **`PRIMARY_SOURCE_EXTRACTED`** (user-confirmed manual extraction from OEM Protection Setting Report Attachment 1).
- **Physical Limiting Labels**: Explicitly acknowledged as engineering interpretation explaining physical machinery limits; they are not direct manufacturer text.
- **Stale Value Removal**: Stale values (such as $-233, -222, -206, +310, +279\text{ MVAr}$) from obsolete PSAF notes have been completely expunged.
- **Non-Clipping Policy**: The load flow formulation solves physical reactive generation without artificial numerical clamping, ensuring authentic operating point visibility.

---

## SECTION 8: 360 MW CAPABILITY INTERPOLATION

The primary active-power capacity is $360.00\text{ MW}$. Evaluating the capability boundaries at $360.00\text{ MW}$ requires piecewise-linear interpolation between Point 4 ($300.0\text{ MW}$) and Point 5 ($389.3\text{ MW}$):

$$\Delta P = 360.0 - 300.0 = 60.0\text{ MW}, \quad \text{Span} = 389.3 - 300.0 = 89.3\text{ MW}$$
$$\text{Fraction } \alpha = \frac{60.0}{89.3} \approx 0.6718925$$

### Overexcitation Boundary at 360 MW:
$$Q_{\max}(360) = 280.0 + 0.6718925 \times (241.0 - 280.0) = 280.0 - 26.2038 = \mathbf{+253.7962\text{ MVAr}}$$

### Underexcitation Boundary at 360 MW:
$$Q_{\min}(360) = -205.0 + 0.6718925 \times (-182.0 - (-205.0)) = -205.0 + 15.4535 = \mathbf{-189.5465\text{ MVAr}}$$

> [!NOTE]
> These $360\text{ MW}$ values are **DERIVED VALUES BY PIECEWISE LINEAR INTERPOLATION**, not primary source points. They are not hardcoded into source records.

---

## SECTION 9: OPERATING-CASE CLASSIFICATION & CAPACITY GUARD

### Case Classifications:
1. **PRIMARY CASES ($360.00\text{ MW}$)**:
   - Primary active-power capacity: $360.00\text{ MW}$, verified from supplied project workbook `Ahsuganj South (2).xlsx`, Row 3 (Cell B3: 'Capacity (MW)').
   - `LF360_GAT_OUT`: Primary continuous dispatch ($360\text{ MW}$), GAT bay open (radial auxiliary feed from UAT).
   - `LF360_GAT_IN`: Primary continuous dispatch ($360\text{ MW}$), GAT bay closed (looped auxiliary feed).
2. **QUALIFIED SCENARIOS ($342.01\text{ MW}$)**:
   - Qualified owner/site derated scenario ($342.01\text{ MW}$), with its boundary interpretation explicitly qualified as unresolved between net export and generator terminal power.
   - `LF342_GAT_OUT`: Site-derated auxiliary boundary scenario ($342.01\text{ MW}$), GAT bay open.
   - `LF342_GAT_IN`: Site-derated auxiliary boundary scenario ($342.01\text{ MW}$), GAT bay closed.
3. **HISTORICAL BENCHMARK REFERENCES ($389.30\text{ MW}$)**:
   - Historical $458\text{ MVA} \times 0.85\text{ PF}$ nameplate reference point.
   - `LF389P30_GAT_OUT` (alias `LF1`): Historical nameplate reference case, GAT out.
   - `LF389P30_GAT_IN` (alias `LF2`): Historical nameplate reference case, GAT in.

### Capacity Guard Enforcement (Task 4):
Function `validate_operating_profile.m` is integrated directly into `build_ashuganj_main.m` (lines 160-161):
- Dispatches $\le 360.00\text{ MW}$ are accepted unconditionally.
- Dispatches $> 360.00\text{ MW}$ without `approved_exception = true` are rejected with error `CapacityExceeded`.
- Historical $389.30\text{ MW}$ cases require explicit `approved_exception = true` and `case_class = 'HISTORICAL'`.

---

## SECTION 10: EXCITATION SYSTEM & SEMIPOL DISTINCTION

- **Verified Source Designation**: Workbook `Ahsuganj South (2).xlsx` Cells AS3/AT3 specify **`Static`** excitation and **`SEMIPOL`** controller trade designation (`PRIMARY_VERIFIED`).
- **Academic Model Classification**: **`GENERIC ACADEMIC STATIC EXCITATION MODEL INSPIRED BY SOURCE-DOCUMENTED STATIC/SEMIPOL DESIGNATION`** (NOT a verified or commissioned SEMIPOL manufacturer controller model; no IEEE ST4B or AC5A claim).
- **Engineering Assumptions (`ENGINEERING_ASSUMPTION`)**:
  - Voltage regulator gain: $K_a = 200.0\text{ pu/pu}$
  - AVR time constant: $T_{\text{avr}} = 0.02\text{ s}$
  - Field response lag: $T_e = 0.50\text{ s}$
  - Field voltage command limits: $E_{fd} \in [-5.00, +5.00]\text{ pu}$
- **Generic Academic Limiters**:
  - *Overexcitation Limiter (OEL)*: Detects $E_{fd} > 1.075 \times 2.50\text{ pu}$ and ramps negative correction ($K_{\text{oel}} = 5.0$, $T_{\text{oel}} = 1.0\text{ s}$).
  - *Underexcitation Limiter (UEL)*: Inset $5.0\text{ MVAr}$ above $Q_{\min}(P)$, injecting positive boost ($K_{\text{uel}} = 0.05\text{ pu/MVAr}$, $T_{\text{uel}} = 0.10\text{ s}$).
  - *Stator Current Limiter (SCL)*: Senses $I_t > 1.00\text{ pu}$ and applies reactive current reduction ($K_{\text{scl}} = 5.0$, $T_{\text{scl}} = 0.20\text{ s}$).

---

## SECTION 11: STATIC FREQUENCY CONVERTER (SFC)

- **Role**: Synchronous motor acceleration of gas turbine shaft during startup to ~2100 rpm.
- **Source-Verified Data (`PRIMARY_VERIFIED`)**:
  - SFC DC link voltage: $U_{\text{dc,sfc}} = 2.28\text{ kV}$ (Generator Data South p.6).
  - SFC maximum output current: $I_{\max,\text{sfc}} = 1876\text{ A}$ AC output into stator (Generator Data South p.6).
  - Generator no-load field voltage: $U_{\text{exc0}} = 122\text{ V}$ (Generator Data South p.6).
- **Architectural Isolation**:
  - The SFC DC link ($2.28\text{ kV}$) is strictly isolated from generator field voltage ($122\text{ V}$), AVR supply, and station DC battery ($110\text{ V}$).
  - The SFC is not electrically connected to the station battery.
- **Engineering Assumptions (`ENGINEERING_ASSUMPTION`)**:
  - Starting power cap: $P_{\text{sfc},\max} = 4.00\text{ MW}$ (separately assumed; not $2.28\text{ kV} \times 1876\text{ A}$).
  - Inverter efficiency: $\eta = 97.0\%$ ($3\%$ internal losses).
  - Ramping response time constant: $\tau_{\text{sfc}} = 0.03\text{ s}$.

---

## SECTION 12: STATION DC AUXILIARY SYSTEM, BATTERY & CHARGER

- **Station DC Bus**: $110.0\text{ VDC}$ nominal rating (`ENGINEERING_ASSUMPTION`).
- **Academic Battery Model (`ENGINEERING_ASSUMPTION`)**:
  - Battery Chemistry: Flooded Lead-Acid string.
  - Cell Count: $55$ series cells ($\approx 2.0\text{ V/cell}$ nominal).
  - Battery Capacity: **$200.0\text{ Ah}$** nominal whole-bank capacity (stale $600\text{ Ah}$ purged).
  - Battery Internal Resistance: $R_b = 0.05\,\Omega > 0$ (finite, non-ideal lumped resistance).
  - Usable SOC Range: $\text{SoC}_{\min} = 0.20$ ($20\%$ reserve cutoff) to $\text{SoC}_{\max} = 1.00$.
  - Undervoltage Disconnect: $V_{\text{cutoff}} = 105.0\text{ V}$ ($1.91\text{ V/cell}$).
  - Coulombic Charge Efficiency: $\eta_{\text{chg}} = 90.0\%$.
  - Maximum Current Bounds: $I_{\text{disch},\max} = 200\text{ A}$ ($1\text{C}$), $I_{\text{chg},\max} = 40\text{ A}$ ($\text{C}/5$).
- **Standard Sizing Practice Disclaimer**:
  > [!NOTE]
  > A practical engineering-assumption battery model informed by conventional stationary battery sizing practice is implemented. Plant-specific battery duty-cycle, manufacturer, aging, temperature, and end-of-life sizing data are unavailable; therefore IEEE 485 compliance is NOT claimed.
- **Battery Charger Implementation (Option A — Closed-Loop Finite Regulation)**:
  - Nominal Voltage Class: $110.0\text{ VDC}$.
  - Rated Power: $P_{\text{chg},\text{rated}} = 20.0\text{ kW}$ DC output per unit.
  - Current Limit: $I_{\text{chg},\max} = 180.0\text{ A}$.
  - Float Voltage Setpoint: $V_{\text{float}} = 123.75\text{ V}$ ($2.25\text{ V/cell}$).
  - Rectification Efficiency: $\eta_{\text{charger}} = 92.5\%$.
  - Voltage Regulation Response: First-order lag with time constant $\tau_{\text{chg}} = 0.10\text{ s}$.
  - Closed-Loop Performance: When floating at full SOC ($\text{SoC} \ge 0.999$), $I_{\text{batt}} = 0$, charger supplies continuous load ($2.40\text{ kW}$), and bus converges to $V_{\text{float}} = 123.75\text{ V} \pm 0.01\text{ V}$.

---

## SECTION 13: GOVERNOR / TURBINE MODEL

- **Speed Droop**: **$5.0\%$** ($0.05\text{ pu}$ on 458 MVA machine base; stale $4\%$ purged from documentation).
- **Governor Actuator Time Constant**: $\tau_{\text{gov}} = 0.20\text{ s}$ (`ENGINEERING_ASSUMPTION`).
- **Lumped Turbine Time Constant**: $\tau_{\text{turb}} = 0.75\text{ s}$ (`ENGINEERING_ASSUMPTION`).
- **Speed Reference**: $\omega_{\text{ref}} = 1.00\text{ pu}$ (50 Hz).
- **Turbine Gain**: $K_{\text{turb}} = 1.0\text{ pu/pu}$.
- **Classification**: Generic academic readiness model; NOT Siemens plant-specific governor settings.

---

## SECTION 14: GENERATOR-TERMINAL VOLTAGE REPORTING CORRECTION

### Background & Technical Diagnosis:
Previous documentation and summary logs reported generator-side voltage around $V_{\text{gen}} \approx 0.921\text{ pu}$ ($20.28\text{ kV}$) during 360 MW dispatch, leading to hypotheses of an unexplained 8% GSUT voltage drop.

Investigation of the solved bus phasors revealed:
1. **Node Identity**: Bus 3 in `LF.bus` (block handle `node.B22`) represents the generator terminal bus.
2. **PV Setpoint**: Bus 3 receives the $1.00\text{ pu}$ voltage setpoint ($22.000\text{ kV}$).
3. **Complex Phasor Solution**:
   $$V_{\text{bus}} = 0.921627 - j 0.388076\text{ pu} = 1.000000 \angle (-22.84^\circ)\text{ pu}$$
4. **Root Cause**: In `validate_phase2_load_flow.m`, `val.Vgen_pu` was assigned the complex phasor directly without `abs()`. When printed via `fprintf('%f')` or serialized to CSV, MATLAB truncated the imaginary component and printed only:
   $$\text{Re}(V_{\text{bus}}) = \cos(-22.84^\circ) = 0.9216\text{ pu}$$
5. **Physical Magnitude**:
   $$|V_{\text{bus}}| = \sqrt{0.921627^2 + (-0.388076)^2} = \mathbf{1.000000\text{ pu}} \quad (22.000\text{ kV})$$

### Formal Finding:
> In the implemented PV load-flow representation, the generator-terminal voltage magnitude is maintained at 1.0000 pu (22.0 kV); the previously reported 0.9216 pu value was a reporting artifact caused by using the real component of the complex phasor instead of its magnitude.

---

## SECTION 15: REGRESSION EVIDENCE & BENCHMARK REPRODUCIBILITY

Full regression suite reported by the implementation: **1331 passed, 0 failed** across 16 test suites.

```
########################################################################
#  ASHUGANJ 450 MW CCPP (SOUTH) - REV3.1 VALIDATION SUITE              #
#  16 test files, selection 'all'                                      #
########################################################################
  PASS  test_bus_data                        61 passed    0 failed     0.3 s
  PASS  test_generator_data                 476 passed    0 failed     1.7 s
  PASS  test_transformer_data                85 passed    0 failed     0.1 s
  PASS  test_line_data                       47 passed    0 failed     0.1 s
  PASS  test_load_data                       58 passed    0 failed     0.1 s
  PASS  test_base_conversion                 39 passed    0 failed     0.1 s
  PASS  test_topology                        52 passed    0 failed     0.4 s
  PASS  test_generator_capability           224 passed    0 failed     0.4 s
  PASS  test_engineering_assumptions          9 passed    0 failed     0.5 s
  PASS  test_phase2_systems                  24 passed    0 failed     5.0 s
  PASS  test_phase2_component_models         51 passed    0 failed     0.5 s
  PASS  test_operating_profiles              55 passed    0 failed     0.4 s
  PASS  test_transformer_phase_shift         18 passed    0 failed    78.9 s
  PASS  test_grid_sensitivity                38 passed    0 failed    16.5 s
  PASS  test_magnetising_sensitivity         41 passed    0 failed    11.5 s
  PASS  test_phase2_load_flow                53 passed    0 failed    15.8 s
  --------------------------------------------------------------------
  TOTAL                                    1331 passed    0 failed   132.2 s

  ALL CHECKS PASSED.
```

### Historical LF Benchmark Reproducibility (Phase 1 Benchmarks):
- **LF1** ($389.30\text{ MW}$, GAT Out): Export $= 374.483506\text{ MW}$, Losses $= 0.816494\text{ MW}$ (Exact match)
- **LF2** ($389.30\text{ MW}$, GAT In): Export $= 374.466581\text{ MW}$, Losses $= 0.833419\text{ MW}$ (Exact match)
- **LF3** ($342.01\text{ MW}$, GAT Out): Export $= 327.329808\text{ MW}$, Losses $= 0.680192\text{ MW}$ (Exact match)
- **LF4** ($342.01\text{ MW}$, GAT In): Export $= 327.319743\text{ MW}$, Losses $= 0.690257\text{ MW}$ (Exact match)

---

## SECTION 16: SOURCE-VS-ASSUMPTION TRACEABILITY

| Parameter | Value | Unit | Source | Source Locator | Status | Confidence | Rationale | Runtime Consumer |
|---|:---:|:---:|---|---|:---:|:---:|---|---|
| **GENERATOR** | | | | | | | | |
| Rated Apparent Power $S_{\text{nom}}$ | 458.00 | MVA | Workbook / Rating Plate | Cell D3 / Siemens Rpt §2.1.1 | `PRIMARY_VERIFIED` | High | Machine design rating base | `ashuganj_generators.m`, `build_generator_system.m` |
| Primary Active Capacity $P_{\text{cap}}$ | 360.00 | MW | Supplied Workbook | Ahsuganj South (2).xlsx Row 3 (Cell B3: 'Capacity (MW)') | `PRIMARY_VERIFIED` | High | Authoritative primary dispatch limit | `validate_operating_profile.m`, `build_ashuganj_main.m` |
| Rated Active Power $P_{\text{ref}}$ | 389.30 | MW | Workbook / Nameplate PF | $458\text{ MVA} \times 0.85$ | `HISTORICAL` | High | Historical nameplate reference point | `ashuganj_operating_profiles.m` |
| Rated Terminal Voltage $V_{\text{nom}}$ | 22.00 | kV | Workbook / Rating Plate | Cell E3 / Siemens Rpt §2.1.1 | `PRIMARY_VERIFIED` | High | Generator nominal voltage base | `ashuganj_generators.m`, `ashuganj_buses.m` |
| Rated Frequency $f$ | 50.0 | Hz | Rating Plate / Grid Code | BPDB Grid Code | `PRIMARY_VERIFIED` | High | System electrical frequency | `build_ashuganj_main.m` (powergui) |
| Reference Power Factor $\text{PF}$ | 0.85 | — | Workbook / Rating Plate | Siemens Rpt §2.1.1 | `PRIMARY_VERIFIED` | High | Continuous rated power factor | `ashuganj_generators.m` |
| Combined Train Inertia $H$ | 5.287 | s | Workbook | Cell F3 | `PRIMARY_VERIFIED` | High | Combined GT + ST + Gen inertia | `ashuganj_generators.m`, `dynamicReadiness` |
| Short Circuit Ratio $\text{SCR}$ | 0.601 | — | Workbook | Cell G3 | `PRIMARY_VERIFIED` | High | Steady-state stability metric | `ashuganj_generators.m` |
| D-axis Synchronous Reactance $X_d$ | 1.7830 | pu | Workbook | Cell H3 | `PRIMARY_VERIFIED` | High | Unsaturated d-axis reactance ($458\text{ MVA}$) | `ashuganj_generators.m`, dynamic models |
| D-axis Transient Reactance $X_d'$ | 0.3256 | pu | Workbook | Cell I3 | `PRIMARY_VERIFIED` | High | Unsaturated transient reactance | `ashuganj_generators.m`, fault studies |
| D-axis Subtransient Reactance $X_d''$| 0.2608 | pu | Workbook | Cell J3 | `PRIMARY_VERIFIED` | High | Standard dynamic subtransient reactance | `ashuganj_generators.m`, dynamic models |
| Saturated Subtransient $X_d''\text{sat}$| 0.2248 | pu | Workbook / Siemens Rpt | Cell K3 / Siemens Rpt §2.1.1 | `PRIMARY_VERIFIED` | High | Saturated subtransient reactance (fault)| `ashuganj_generators.m`, fault analysis |
| Q-axis Synchronous Reactance $X_q$ | 1.7510 | pu | Workbook | Cell L3 | `PRIMARY_VERIFIED` | High | Unsaturated q-axis reactance | `ashuganj_generators.m`, dynamic models |
| Q-axis Transient Reactance $X_q'$ | 0.5087 | pu | Workbook | Cell M3 | `PRIMARY_VERIFIED` | High | Unsaturated q-axis transient reactance | `ashuganj_generators.m`, dynamic models |
| Q-axis Subtransient Reactance $X_q''$| 0.2593 | pu | Workbook | Cell N3 | `PRIMARY_VERIFIED` | High | Standard q-axis subtransient reactance | `ashuganj_generators.m`, dynamic models |
| Stator Leakage Reactance $X_l$ | 0.2027 | pu | Workbook | Cell O3 | `PRIMARY_VERIFIED` | High | Potier / stator leakage reactance | `ashuganj_generators.m`, dynamic models |
| Negative Sequence Reactance $X_2$ | 0.2242 | pu | Workbook | Cell P3 | `PRIMARY_VERIFIED` | High | Negative-sequence impedance | `ashuganj_generators.m`, fault analysis |
| Zero Sequence Reactance $X_0$ | 0.1280 | pu | Workbook | Cell Q3 | `PRIMARY_VERIFIED` | High | Zero-sequence impedance | `ashuganj_generators.m`, fault analysis |
| Armature DC Resistance $R_a$ | 0.00089 | $\Omega$ | Workbook | Cell U3 | `PRIMARY_VERIFIED` | High | $0.000842\text{ pu}$ (gen), $0.000184\text{ pu}$ (sys)| `ashuganj_generators.m`, base conversion |
| Field Winding Resistance $R_f$ | 0.10631 | unresolved | Workbook | Cell V3 | `PRIMARY_SOURCE_QUALIFIED`| Qualified | Heading mixed; unit/field base unresolved | `ashuganj_generators.m` (traceability) |
| Time Constant $T_{d0}'$ | 7.547 | s | Workbook | Cell Y3 | `PRIMARY_VERIFIED` | High | Open-circuit d-axis transient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_{d0}''$ | 0.045 | s | Workbook | Cell Z3 | `PRIMARY_VERIFIED` | High | Open-circuit d-axis subtransient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_{q0}'$ | 0.839 | s | Workbook | Cell AA3 | `PRIMARY_VERIFIED` | High | Open-circuit q-axis transient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_{q0}''$ | 0.070 | s | Workbook | Cell AB3 | `PRIMARY_VERIFIED` | High | Open-circuit q-axis subtransient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_d'$ | 1.213 | s | Workbook | Cell AC3 | `PRIMARY_VERIFIED` | High | Short-circuit d-axis transient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_d''$ | 0.035 | s | Workbook | Cell AD3 | `PRIMARY_VERIFIED` | High | Short-circuit d-axis subtransient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_q'$ | 0.214 | s | Workbook | Cell AE3 | `PRIMARY_VERIFIED` | High | Short-circuit q-axis transient time | `ashuganj_generators.m`, dynamic models |
| Time Constant $T_q''$ | 0.035 | s | Workbook | Cell AF3 | `PRIMARY_VERIFIED` | High | Short-circuit q-axis subtransient time | `ashuganj_generators.m`, dynamic models |
| Armature Short-Circuit Time $T_a$ | 0.704 | s | Workbook | Cell AG3 | `PRIMARY_VERIFIED` | High | DC offset decay time constant | `ashuganj_generators.m`, dynamic models |
| Saturation Factor $S(1.0)$ | 0.0865 | — | Workbook | Cell AI3 | `PRIMARY_VERIFIED` | High | Open-circuit saturation at 1.0 pu | `ashuganj_generators.m`, dynamic models |
| Saturation Factor $S(1.2)$ | 0.4080 | — | Workbook | Cell AJ3 | `PRIMARY_VERIFIED` | High | Open-circuit saturation at 1.2 pu | `ashuganj_generators.m`, dynamic models |
| Damper Parameters ($X_D,X_Q,R_D,R_Q$)| NaN | — | Workbook | Cells R3, S3, W3, X3 | `MISSING` | Verified Gap | OEM withheld sub-transient damper data | Documented gap; no default invented |
| **CAPABILITY CURVE** | | | | | | | | |
| Capability Point 1 ($P, Q_{\max}, Q_{\min}$)| 0.0, +335, -231 | MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | Validated 6-point extracted curve | `generatorCapability.m`, `ashuganj_generators.m`|
| Capability Point 2 ($P, Q_{\max}, Q_{\min}$)| 100.0, +329, -231| MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | Validated 6-point extracted curve | `generatorCapability.m`, `ashuganj_generators.m`|
| Capability Point 3 ($P, Q_{\max}, Q_{\min}$)| 200.0, +311, -220| MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | Validated 6-point extracted curve | `generatorCapability.m`, `ashuganj_generators.m`|
| Capability Point 4 ($P, Q_{\max}, Q_{\min}$)| 300.0, +280, -205| MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | Validated 6-point extracted curve | `generatorCapability.m`, `ashuganj_generators.m`|
| Capability Point 5 ($P, Q_{\max}, Q_{\min}$)| 389.3, +241, -182| MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | Validated 6-point extracted curve | `generatorCapability.m`, `ashuganj_generators.m`|
| Capability Point 6 ($P, Q_{\max}, Q_{\min}$)| 458.0, 0.0, 0.0 | MW, MVAr | Siemens Protection Rpt | Attachment 1 | `PRIMARY_SOURCE_EXTRACTED` | Confirmed | MVA limit boundary intercept | `generatorCapability.m`, `ashuganj_generators.m`|
| Derived 360 MW Capability ($Q_{\max}, Q_{\min}$)| +253.796, -189.546| MVAr | Derived by Interpolation | Linear interp between pts 4 & 5 | `DERIVED_FROM_EXTRACTED` | High | Derived capability at 360 MW contract cap | `check_generator_operating_point.m` |
| **EXCITATION SYSTEM** | | | | | | | | |
| Excitation Type | Static | text | Workbook | Cell AS3 | `PRIMARY_VERIFIED` | High | Static thyristor rectifier exciter | `phase2_source_data.m`, `ashuganj_phase2_systems.m`|
| Excitation Controller Designation | SEMIPOL | text | Workbook | Cell AT3 | `PRIMARY_VERIFIED` | High | Siemens excitation commercial trade name | `phase2_source_data.m`, `ashuganj_phase2_systems.m`|
| Excitation No-Load Voltage $U_{\text{exc0}}$| 122.0 | V | Generator Data South | PDF p.1 / report p.6 §2.1.1 | `PRIMARY_VERIFIED` | High | Direct no-load field excitation voltage | `phase2_source_data.m` (isolated parameter) |
| AVR Voltage Regulator Gain $K_a$ | 200.0 | pu/pu | Academic Assumption | Standard Static Exciter | `ENGINEERING_ASSUMPTION` | Standard | High-gain static AVR representation | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| AVR Regulator Time Constant $T_{\text{avr}}$| 0.02 | s | Academic Assumption | Thyristor Firing Delay | `ENGINEERING_ASSUMPTION` | Standard | Fast thyristor bridge firing response | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| Field Response Lag $T_e$ | 0.50 | s | Academic Assumption | Main Field Inductive Lag | `ENGINEERING_ASSUMPTION` | Standard | Rotor field excitation time delay | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| Field Voltage Command Bounds $E_{fd}$| [-5.0, +5.0] | pu | Academic Assumption | Ceiling Voltage Capability | `ENGINEERING_ASSUMPTION` | Standard | Finite positive and negative ceiling limits | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| Overexcitation Limiter (OEL) | $K=5.0, T=1.0\text{ s}$| — | Academic Assumption | Rotor Thermal Protection | `ENGINEERING_ASSUMPTION` | Generic | Finite OEL correction; not OEM setting | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| Underexcitation Limiter (UEL) | Inset $5\text{ MVAr}, K=0.05$| — | Academic Assumption | Core End-Iron Heating | `ENGINEERING_ASSUMPTION` | Generic | Inset above $Q_{\min}(P)$; not OEM setting | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| Stator Current Limiter (SCL) | $I_t > 1.0\text{ pu}, K=5.0$| — | Academic Assumption | Stator Overload Protection | `ENGINEERING_ASSUMPTION` | Generic | Bounded reactive reduction; not OEM setting | `phase2_excitation_step.m`, `engineering_assumptions.m`|
| **SFC (STARTING FREQUENCY CONVERTER)**| | | | | | | | |
| SFC DC Link Voltage | 2.28 | kV | Generator Data South | PDF p.1 / report p.6 §2.1.1 | `PRIMARY_VERIFIED` | High | Intermediate DC bus; strictly non-battery | `phase2_source_data.m`, `phase2_sfc_step.m` |
| SFC Maximum Output Current | 1876 | A | Generator Data South | PDF p.1 / report p.6 §2.1.1 | `PRIMARY_VERIFIED` | High | AC output current into stator; not DC current | `phase2_source_data.m`, `phase2_sfc_step.m` |
| SFC Continuous Starting Cap | 4.00 | MW | Academic Assumption | GT Starting Torque Requirement | `ENGINEERING_ASSUMPTION` | Standard | Finite shaft motoring power limit | `phase2_sfc_step.m`, `engineering_assumptions.m` |
| SFC Converter Efficiency $\eta$ | 0.97 | fraction | Academic Assumption | Converter Loss Accounting | `ENGINEERING_ASSUMPTION` | Standard | 3% converter internal losses | `phase2_sfc_step.m`, `engineering_assumptions.m` |
| SFC Response Lag $\tau$ | 0.03 | s | Academic Assumption | Fast Current Loop Dynamics | `ENGINEERING_ASSUMPTION` | Standard | Finite exponential tracking response | `phase2_sfc_step.m`, `engineering_assumptions.m` |
| **STATION DC / BATTERY / CHARGER** | | | | | | | | |
| Station DC Bus Nominal Voltage | 110.0 | VDC | Switchgear Standard | Standard CCPP DC Bus | `ENGINEERING_ASSUMPTION` | Standard | Isolated DC auxiliary switchgear base | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Battery Bank Cell Count | 55 | cells | Lead-Acid Standard | $55 \times 2.0\text{ V/cell}$ | `ENGINEERING_ASSUMPTION` | Standard | Flooded lead-acid string configuration | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Battery Nominal Capacity | 200.0 | Ah | Academic Assumption | Switchgear Tripping Duty | `ENGINEERING_ASSUMPTION` | Academic | Academic whole-bank capacity (not 600 Ah) | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Battery Internal Resistance $R_b$ | 0.05 | $\Omega$ | Academic Assumption | Lumped Bank Resistance | `ENGINEERING_ASSUMPTION` | Standard | Finite non-ideal terminal sag $\Delta V = I R_b$| `engineering_assumptions.m`, `phase2_dc_step.m` |
| Battery Minimum SOC Reserve | 0.20 | fraction | Conservative Reserve | Reserve Energy Threshold | `ENGINEERING_ASSUMPTION` | Standard | Low-capacity discharge disconnect cutoff | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Battery Cutoff Terminal Voltage | 105.0 | V | Low-Voltage Disconnect | $1.91\text{ V/cell}$ cutoff | `ENGINEERING_ASSUMPTION` | Standard | Minimum permissible bus voltage cutoff | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Charger Rated DC Output Power | 20.0 | kW | Academic Sizing | DC Auxiliary Load Coverage | `ENGINEERING_ASSUMPTION` | Standard | Per-unit DC output rating (2 units: 1 duty, 1 standby)| `engineering_assumptions.m`, `phase2_dc_step.m` |
| Charger Current Limit | 180.0 | A | Academic Sizing | Fast Recharge Capability | `ENGINEERING_ASSUMPTION` | Standard | Finite output current clamp | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Charger Float Voltage Setpoint | 123.75 | V | Battery Float Standard | $2.25\text{ V/cell}$ float | `ENGINEERING_ASSUMPTION` | Standard | Closed-loop voltage regulation target | `engineering_assumptions.m`, `phase2_dc_step.m` |
| Charger Rectification Efficiency | 0.925 | fraction | Modern SCR/IGBT Charger | AC/DC Power Conversion | `ENGINEERING_ASSUMPTION` | Standard | AC auxiliary infeed power accounting | `engineering_assumptions.m`, `phase2_dc_step.m` |
| **GOVERNOR / TURBINE** | | | | | | | | |
| Governor Speed Droop | 5.0 | % | Academic Assumption | Standard Grid Code Range | `ENGINEERING_ASSUMPTION` | Standard | Droop slope on 458 MVA machine base | `engineering_assumptions.m`, `ashuganj_phase2_systems.m`|
| Governor Actuator Response Lag | 0.20 | s | Academic Assumption | Fuel Valve Hydraulic Time | `ENGINEERING_ASSUMPTION` | Standard | First-order governor actuator lag | `engineering_assumptions.m`, `ashuganj_phase2_systems.m`|
| Lumped Turbine Mechanical Lag | 0.75 | s | Academic Assumption | Combined Cycle Expansion | `ENGINEERING_ASSUMPTION` | Standard | Aggregate GT+ST mechanical response lag | `engineering_assumptions.m`, `ashuganj_phase2_systems.m`|
| Plant-Specific Governor Tuning | Unavailable | — | Siemens Withheld Data | Proprietary GT Controller | `MISSING` | Verified Gap | Generic models ready; tuning missing | Phase 3 Dynamic Readiness |
| **TRANSFORMERS** | | | | | | | | |
| GSUT Rating ($S_1 / S_2 / S_3$) | 355 / 460 / 515 | MVA | GSUT Datasheet | Guangzhou Datasheet | `PRIMARY_VERIFIED` | High | ONAN / ODAN / ODAF rating stages | `ashuganj_transformers.m`, `build_gsut_system.m` |
| GSUT Voltage Ratio | $230 \pm 8\times 1.25\% / 22$| kV | GSUT Datasheet | Guangzhou Datasheet | `PRIMARY_VERIFIED` | High | HV tap changer on 230 kV winding | `ashuganj_transformers.m`, `build_gsut_system.m` |
| GSUT Rated Impedance $u_k$ | 16.00 | % | GSUT Datasheet / Rpt §2.2 | 515 MVA base | `PRIMARY_VERIFIED` | High | Transformer leakage impedance | `ashuganj_transformers.m`, `build_gsut_system.m` |
| GSUT Vector Group | YNd1 | text | GSUT Datasheet / Drawing | Guangzhou / DE-0001 Rev 03 | `PRIMARY_VERIFIED` | High | Star-HV grounded, Delta-LV lagging | `ashuganj_transformers.m`, `build_gsut_system.m` |
| UAT Rating ($S_1 / S_2$) | 19 / 25 | MVA | CTI Datasheet | STWH-579UAT-0007 | `PRIMARY_VERIFIED` | High | ONAN / ONAF auxiliary transformer rating | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| UAT Voltage Ratio | 22.0 / 6.9 | kV | CTI Datasheet | STWH-579UAT-0007 | `PRIMARY_VERIFIED` | High | 6.9 kV secondary winding to MV switchgear | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| UAT Rated Impedance $u_k$ | 10.50 | % | CTI Datasheet | 25 MVA base | `PRIMARY_VERIFIED` | High | Transformer leakage impedance | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| UAT Vector Group | Dyn11 | text | CTI Datasheet | STWH-579UAT-0007 | `PRIMARY_VERIFIED` | High | Delta-HV, Star-LV neutral grounded | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| GAT Rating ($S_1 / S_2$) | 19 / 25 | MVA | Guangzhou Datasheet | Guangzhou Datasheet | `PRIMARY_VERIFIED` | High | Three-winding standby transformer | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| GAT Voltage Ratio | 230 / 6.9 / 3.32 | kV | Guangzhou Datasheet | Guangzhou Datasheet | `PRIMARY_VERIFIED` | High | Multi-winding standby feed | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| GAT Rated Impedance $u_{k,\text{HL}}$| 12.00 | % | Guangzhou Datasheet | 25 MVA base | `PRIMARY_VERIFIED` | High | Primary-to-secondary leakage impedance | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| GAT Vector Group | YNa0d1 | text | Guangzhou Datasheet | Guangzhou Datasheet | `PRIMARY_VERIFIED` | High | Auto-connected HV/LV, Delta tertiary | `ashuganj_transformers.m`, `build_auxiliary_system.m`|
| **GRID EQUIVALENT** | | | | | | | | |
| Grid Nominal Voltage | 230.0 | kV | BPDB Single Line Drawing | DE-0001 Rev 03 | `PRIMARY_VERIFIED` | High | High-voltage transmission interconnection | `ashuganj_buses.m`, `build_external_grid.m` |
| Grid Short-Circuit Level | 50.0 | kA | GIS Switchgear Rating | Siemens Rpt §2.4 (50 kA / 3s)| `PRIMARY_SOURCE_QUALIFIED`| Qualified | GIS withstand capability proxy for grid | `phase2_source_data.m`, `build_external_grid.m` |
| Grid Equivalent MVA | 19,919 | MVA | Derived from 50 kA | $\sqrt{3} \times 230\text{ kV} \times 50\text{ kA}$ | `DERIVED_FROM_QUALIFIED` | Qualified | Grid Thevenin impedance $X_{\text{grid}} = 2.656\,\Omega$| `build_external_grid.m` |
| Grid Swing Bus Setpoint | $1.000\text{ pu}, 0.0^\circ$| pu, deg | Academic Assumption | Slack Reference Bus | `ENGINEERING_ASSUMPTION` | Standard | Reference angle $\theta = 0^\circ$ for load flow | `ashuganj_generators.m`, `build_external_grid.m` |
| **AUXILIARY LOADS** | | | | | | | | |
| Plant Total Auxiliary Active Power| 14.00 | MW | APSCL Official Submission | Station Demand Summary Form | `PRIMARY_VERIFIED` | High | Measured/contractual auxiliary demand | `ashuganj_loads.m`, `build_auxiliary_system.m` |
| Auxiliary Power Factor | 0.85 | — | APSCL Official Submission | Station Demand Summary Form | `PRIMARY_VERIFIED` | High | Lagging induction motor auxiliary load | `ashuganj_loads.m`, `build_auxiliary_system.m` |
| Auxiliary Reactive Power $Q_{\text{aux}}$| 8.6764 | MVAr | Derived from P and PF | $14.00 \times \tan(\arccos 0.85)$ | `DERIVED_FROM_VERIFIED` | High | Continuous reactive demand | `ashuganj_loads.m`, `build_auxiliary_system.m` |
| Auxiliary Bus Distribution Split | 6 MW / 4 MW / 4 MW | MW | Engineering Allocation | 10BBA10 / 10BBW10 / 10BBW20 | `ENGINEERING_ASSUMPTION` | Plausible | Substation feeder split (missing data) | `ashuganj_loads.m` |

---

## SECTION 17: REMAINING GENUINE DATA GAPS

The following data items are not present in any supplied plant engineering documentation and represent genuine data gaps. They are resolved via practical academic engineering assumptions:

1. **Plant-Specific Excitation Controller Settings**:
   - The source document confirms the type is **`Static`** and designation is **`SEMIPOL`**.
   - Specific internal controller transfer function blocks, amplifier gains, stabilizing lead-lag compensator constants, thyristor bridge firing parameters, and limiter settings were withheld by Siemens.
   - *Academic Resolution*: A generic academic static exciter model with $K_a = 200$, $T_{\text{avr}} = 0.02\text{ s}$, $T_e = 0.50\text{ s}$, and academic OEL/UEL/SCL limiters is provided for dynamic study readiness.
2. **Plant-Specific Battery System Specifications**:
   - The exact physical Ah capacity, battery manufacturer datasheet, cell model, and DC distribution schematics are not in the primary documentation.
   - *Academic Resolution*: A practical engineering-assumption battery model informed by conventional stationary battery sizing practice is implemented ($110\text{ VDC}$, 55 cells, $200\text{ Ah}$, $R_b = 0.05\,\Omega$, $20\text{ kW}$ charger with $123.75\text{ V}$ float regulation). Plant-specific battery duty-cycle, manufacturer, aging, temperature, and end-of-life sizing data are unavailable; therefore IEEE 485 compliance is NOT claimed.
3. **Plant-Specific Governor / Turbine Tuning**:
   - The gas turbine (SGT5-4000F) and steam turbine (SST-3000) thermodynamic and electro-hydraulic governor settings are proprietary.
   - *Academic Resolution*: A standard generic academic droop governor ($5.0\%$ droop on 458 MVA base, $\tau_{\text{gov}} = 0.20\text{ s}$, $\tau_{\text{turb}} = 0.75\text{ s}$) is implemented.
4. **Detailed SFC Internal Controller Architecture**:
   - The starting converter is characterized by verified terminal boundaries ($2.28\text{ kV}$ DC link, $1876\text{ A}$ maximum output current). Detailed thyristor firing circuitry and inverter commutation logic are unavailable.
   - *Academic Resolution*: A first-order power ramp model ($P_{\max} = 4.00\text{ MW}$, $\eta = 97.0\%$, $\tau = 0.03\text{ s}$) is provided.
5. **Damper Winding & Direct OCC Data**:
   - Cells R3, S3, W3, X3, AH3 of the official workbook are empty.
   - *Academic Resolution*: These parameters remain explicitly classified as `MISSING` with `NaN` placeholders. No synthetic zero or infinite approximations were introduced.

---

## SECTION 18: PHASE 3 READINESS CONFIRMATION

Phase 2 implementation complete; final documentation/source-claim cleanup completed.
- Full regression suite reported by the implementation: 1331 passed, 0 failed.
- Primary 360 MW cases solve with machine terminal voltage magnitude at exactly $1.0000\text{ pu}$ ($22.000\text{ kV}$).
- Historical benchmark cases LF1–LF4 reproduce Phase 1 results to $< 10^{-6}$.
- Rev2 files remain 100% byte-identical against baseline.
- Zero electrical equations, solver physics, transformer parameters, generator numerical parameters, or operating cases were altered during this cleanup.
- **Phase 2 is formally COMPLETE AND CLOSED.**
- **STATUS: READY FOR SEPARATE PHASE 3 AUTHORIZATION.**
- **Phase 3 fault-analysis implementation has NOT been performed.**

---

## SECTION 19: FINAL LIMITATIONS

1. **Phase 3 Boundary**:
   - Zero fault calculations (symmetrical or unsymmetrical), sequence network representations, IEC 60909 calculations, protection coordination, or relay settings have been implemented.
2. **Proprietary Controller Data**:
   - SEMIPOL AVR, SGT5-4000F governor, and SFC converter models are generic academic approximations suitable for coursework studies; they do not represent validated OEM vendor commissioning settings.
3. **Station Battery Model**:
   - Sized on practical academic assumptions (200 Ah, 110 VDC, 55 cells, 0.05 ohm internal resistance) without claim of IEEE 485 compliance.
4. **Active Power Boundaries**:
   - Primary dispatch is limited to $360.00\text{ MW}$ by runtime capacity guard. Operating at $389.30\text{ MW}$ is permitted solely for historical nameplate benchmark reproduction under explicit exception flags.
