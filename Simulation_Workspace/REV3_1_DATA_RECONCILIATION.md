# REV3.1 Master Data Reconciliation and Audit

**Project:** Ashuganj South, EEE 306, current Claude workspace  
**Audit date:** 2026-09-14  
**Stage:** DATA RECONCILIATION ONLY — implementation is not authorized by this document.  
**Deliverables:** this report and [REV3_1_ACTION_PLAN.md](REV3_1_ACTION_PLAN.md). Existing sources, registries, models, tests, documentation and measured results are retained.

## 1. Current Claude generator data and architecture

The executable LF entry point is [ashuganj_master_data.m](matlab/data/ashuganj_master_data.m:1), which assembles the existing equipment providers. The source-audited [Ashuganj_Master_Data.csv](data/master/Ashuganj_Master_Data.csv) is a parallel provenance ledger, not currently the numeric input read by this constructor.

The current [ashuganj_generators.m](matlab/data/ashuganj_generators.m:5) contains 458 MVA, 22 kV, PF 0.85, 50 Hz, 518 MVA under a different cooling condition, and high-resistance generator earthing. It stores 166.3%, 28.65%, 22.48% as the three d-axis reactances without preserving their saturated qualifier. Quadrature/sequence reactances, armature resistance, inertia and an open-circuit time constant are marked missing; several other newly supplied quantities have no field at all. Dispatch records are 389.30 and 342.01 MW; there is no separate 360 MW capacity constraint.

[ashuganj_rev2_registry.m](rev2/data/ashuganj_rev2_registry.m:14) already contains much of the new machine data, including separate saturated and unqualified subtransient values and an ohm-to-pu resistance calculation. It is NOT a safe replacement for the Claude master: it also introduces solid generator grounding, 12 MW + j5 MVAr auxiliaries, different GSUT impedance/losses and a secondary grid/assumed line model. Fault and protection consumers still use that registry or its result tables.

Preserve the existing LF engine, four-case comparison structure, fresh build before every solve, independent branch reconstruction/KCL, nominal winding/bus distinction, source records, magnetising derivation and test framework. No physical-model rewrite is required merely to register the new machine data.

## 2. New workbook: direct verification and source identity

**Primary REV3 machine dataset:** [Ahsuganj South (2).xlsx](fwdtechnicaldatasldrequestforbueteeetermproject/Ahsuganj%20South%20%282%29.xlsx).

- SHA-256: **6D4286B9D0B771CEE80FB305F3C0AE7B9D34CC1EA8A3B8F2F022BA0D07240A60**.
- Sheet name is **“Ashuganj South ”**, including the trailing space. The other sheet is “Auto Transformer”.
- Generator data are in **row 3**: A3 = “Ashuganj 450 MW CCPP(South)”; E3 = “SIEMENS AG”. Row 1 contains group labels; row 2 contains parameter labels.
- Verified by opening the workbook read-only as a ZIP container, resolving workbook relationships, shared strings, cell types and worksheet values. No reliance on the previous reconciliation transcription. Binary floating-point serialization such as 5.2869999999999999 is the stored representation of the intended 5.287, not a different engineering value.
- Merged groups: H1:T1 reactances in pu; U1:X1 resistance “in pu or ohm”; Y1:AH1 time constants in seconds; AI1:AJ1 saturation; AK1:AR1 **GSUT**; AS1:AT1 excitation. F1 identifies combined generator/turbine inertia; it is not a merged F:G banner.
- Raw AS3 and AT3 have trailing spaces: “Static ” and “SEMIPOL ”. Preserve raw text and normalize only the display values.
- Machine impedance base is selected as the row's 458 MVA / 22 kV rating. The heading explicitly says pu, but does not independently spell out an impedance-base declaration. Store the base interpretation rather than claiming an additional literal workbook statement.

**Verification qualification:** all requested numerical values are present. U3 explicitly includes “ohm”. V3 contains 0.10631 but no individual unit beneath the mixed “pu or ohm” heading. The requested Rf = 0.10631 pu may be retained as the designated interpretation, but its unit/field-base convention is not independently proved by that cell. This is a qualification, not a missing numeric value.

## 3. Parameter-by-parameter comparison

All new values below were directly checked in the workbook. Unless noted, reactances use the selected 458 MVA, 22 kV machine base. “Absent” means no field in the current Claude generator provider; it does not mean missing from the newly supplied source.

| Quantity / proposed canonical name | Current Claude | Workbook cell and verified value | REV3.1 disposition |
|---|---|---|---|
| Rated apparent power, Snom_MVA | 458 MVA | C3: 458 MVA | Primary; unchanged |
| Active-power capacity, P_capacity_MW | No independent field | B3: 360 MW | Primary capacity; Pmax alias may reference this, not duplicate it |
| Nominal voltage, Vnom_kV | 22 kV | D3: 22 kV | Primary; retain existing volt-based interface by conversion |
| Rated PF, PF_rated | 0.85 | Not a workbook column | Preserve Siemens source; not operating PF control |
| PF-derived power reference, P_pf_reference_MW | 389.30 MW rated dispatch | Not a workbook column | Preserve 458 × 0.85 and Siemens stated 389.30 MW; legacy sensitivity |
| Combined inertia, H_s | Missing | F3: 5.287 kW·s/kVA = 5.287 s | Resolved; combined turbine/generator inertia |
| SCR | Absent | G3: 0.601 | Resolved; dimensionless |
| Xd | 1.663 pu, stored as 166.3% | H3: 1.783 pu | New primary; old source saturated value retained |
| Xdp | 0.2865 pu, stored as 28.65% | I3: 0.3256 pu | New primary; old saturated value retained |
| Xdpp | 0.2248 pu, stored as 22.48% | J3: 0.2608 pu | New primary, separate from next row |
| Xdpp_sat | No separate field | K3: 0.2248 pu | Separate primary saturated datum |
| Xq | Missing | L3: 1.751 pu | Resolved |
| Xqp | Absent | M3: 0.5087 pu | Resolved |
| Xqpp | Missing | N3: 0.2593 pu | Resolved |
| Xl | Absent | O3: 0.2027 pu | Resolved |
| X2 | Missing | P3: 0.2242 pu; heading **X2 (sat)** | Resolved; preserve saturated qualifier |
| X0 | Missing | Q3: 0.128 pu; heading **X0 (sat)** | Resolved; preserve saturated qualifier |
| Ra_ohm | Missing | U3: literal **0.00089 ohm** | Resolved, not 0.00089 pu |
| Ra_pu_machine | Missing | Derived from U3/C3/D3 | 0.000842190082644628 pu |
| Rf_pu | Absent | V3: 0.10631 | Numeric resolved; pu designation and field-base convention qualified |
| Td0p_s, T′d0 | Missing | Y3: 7.547 s | Resolved |
| Td0pp_s, T″d0 | Absent | Z3: 0.045 s | Resolved |
| Tq0p_s, T′q0 | Absent | AA3: 0.839 s | Resolved |
| Tq0pp_s, T″q0 | Absent | AB3: 0.070 s | Resolved |
| Tdp_s, T′d | Absent | AC3: 1.213 s | Resolved |
| Tdpp_s, T″d | Absent | AD3: 0.035 s | Resolved |
| Tqp_s, T′q | Absent | AE3: 0.214 s | Resolved |
| Tqpp_s, T″q | Absent | AF3: 0.035 s | Resolved |
| Ta_s | Absent | AG3: 0.704 s, header **Ta or Ta(3)** | Resolved; preserve header qualifier |
| Saturation S10 | Absent | AI3: 0.0865 | Resolved coefficient at 1.0 pu |
| Saturation S12 | Absent | AJ3: 0.408 | Resolved coefficient at 1.2 pu |
| Excitation_type | Absent | AS3: Static | Resolved type, not controller settings |
| Excitation_controller | Absent | AT3: SEMIPOL | Resolved designation, not a validated controller model |

## 4. Primary selections and study-specific reactance methodology

**Mandatory independent registry fields:** Xdpp = **0.2608** and Xdpp_sat = **0.2248**. Neither is a mutable alias for the other. Dataset selection and study-method selection are separate decisions.

| Use | Selected design | Limitation / guard |
|---|---|---|
| Balanced LF | Ideal PV equivalent; P and voltage prescribed, Q solved | Neither subtransient reactance is inserted into the existing LF source |
| Sixth-order electromechanical dynamic study | Use workbook Xd, Xdp, **Xdpp 0.2608**, Xq, Xqp, Xqpp, Xl, H and open-circuit time constants; apply one documented saturation formulation | Unqualified workbook values are treated as the unsaturated model parameter set by explicit methodology; do not substitute Xdpp_sat and then apply saturation again |
| Uncorrected/unsaturated initial fault sensitivity | Positive-sequence source impedance uses Ra plus j **Xdpp 0.2608** on machine base before one conversion | Label it unsaturated comparison; not automatically an IEC maximum-duty result |
| Saturated initial symmetrical fault study | Positive-sequence source impedance uses Ra plus j **Xdpp_sat 0.2248** | Retain Xdpp unchanged; report saturated choice and matched X2/X0 qualifiers |
| IEC 60909 duty study | Separate method profile with voltage factor, machine/transformer correction factors, source treatment and peak/DC rules | Existing superposition plus an IEC peak factor is not sufficient evidence of full IEC compliance; avoid duplicate voltage or saturation corrections |

For the immediate future fault design, preserve the classical prefault-superposition method as a clearly labelled engineering calculation with both saturated and unsaturated cases. A standards-compliant maximum/minimum-duty implementation needs its own reviewed methodology before execution.

## 5. Legacy values retained for traceability and sensitivity

**Reconciliation ID GEN-R31-01**  
**Status: SOURCE/DATASET RECONCILIATION**  
**Primary REV3 machine dataset: NEW WORKBOOK**  
**Legacy dataset: retained for traceability/sensitivity only.**

| Source | Xd | Xd′ | Xd″ | Explicit separate Xd″sat |
|---|---:|---:|---:|---:|
| Old Claude source record | 1.663 | 0.2865 | 0.2248 | Not distinguished in old executable fields |
| New workbook | 1.783 | 0.3256 | 0.2608 | 0.2248 |

The original [Generator Data_South.pdf](fwdtechnicaldatasldrequestforbueteeetermproject/Generator%20Data_South.pdf), PDF p.1 / report p.6, §2.1.1, explicitly prints **“(sat.)” on all three old reactance labels**. Therefore, the earlier CSV/missing-data statement that saturation was unspecified is wrong. The matching saturated subtransient value is corroboration, not permission to overwrite the unqualified workbook field.

The difference is consistent with a saturation-basis distinction. However, SCR agreement or numeric ratios do not prove that every old/new value shares identical test conditions. Preserve the formal reconciliation rather than declaring the datasets universally interchangeable. Do not manufacture Xd_sat/Xdp_sat by fitting the new saturation coefficients; the old source already supplies its own saturated values.

Preserve 518 MVA with its 30°C cold-gas condition, the 458 MVA / 50°C condition, documented nameplate/negative-sequence capability/CT/VT data, and the 342.01 MW owner reference. None grants permission to exceed the workbook capacity in a primary operating case.

## 6. Source conflicts and semantic errors

| ID | Finding | Decision |
|---|---|---|
| GEN-R31-01 | Legacy saturated reactances versus new primary machine set | Retain both; primary and methodology rules in §§4–5 |
| GEN-R31-02 | 360 MW capacity versus 389.30 MW PF-derived/OEM rated point | Separate capacity, nameplate/PF reference and dispatch; no primary dispatch above 360 MW without a documented override |
| GEN-R31-03 | Rf numeric is present but mixed resistance unit heading is ambiguous | Store 0.10631 and raw heading; mark pu/field-base interpretation qualified; do not use it to infer rotor circuits |
| GEN-R31-04 | Ra temperature and Ta test conditions not provided | Keep values verbatim. Approximate X2/(2πfRa_pu) = 0.847375 s, not 0.704 s; do not infer a 20°C/75°C correction as source fact |
| GEN-R31-05 | Owner form calls 342.01 MW “Site De-rated Active Power” with symbol P_net | Retain raw label; exact measurement boundary remains unresolved. Existing generator-terminal use is a scenario interpretation, not measured dispatch |
| GRID-R31-01 | Current code attributes 50 kA only to GIS withstand | Correct provenance to Siemens report §2.4 estimated external-grid dataset; retain equipment rating separately |
| GRID-R31-02 | Secondary 45.01 kA / 10.99 / 3.25 Ω and legacy 0.268+j2.94 Ω do not form one exact c=1 tuple | Keep coherent sensitivity profiles, not a mixed primary equivalent (§10) |
| TX-R31-01 | Workbook GSUT values differ from higher-tier datasheets | Preserve current 16% / 0.21%, no-load loss/current and ratings; do not import the whole workbook row into every component |
| EARTH-R31-01 | Rev2 assigns workbook “Solid Ground” to generator | Wrong component. AQ3 is within GSUT group AK1:AR1. Retain generator NER and scope-specific grounding |
| DOC-R31-01 | Prior REV3 narrative contains unsupported conclusions | Append targeted corrections later; never delete history or promote its interpretations to source facts |

Workbook GSUT cells are AK3 = 515 MVA, AL3 = 155.3 kW, AM3 = 0.00034 under “No Load Current INL (%)”, AN3 = 1067.5 under “Total full load losses PFL (kW) or pu”, AO3 = 0.1663 under a mixed percent/pu heading, AP3 = YNd1, AQ3 = Solid Ground, AR3 blank. They are not generator loss, stator-neutral or machine-impedance data. AM3 requires a unit conflict record; do not silently interpret it as 0.034%. The current datasheet-derived branch remains primary.

[DATA_RECONCILIATION_REV3.md](DATA_RECONCILIATION_REV3.md) currently ends after the workbook transcription while referring to later sections. Its claim that every pu base is explicit and its Rf “header default” interpretation are too strong. [REV3_PROGRESS.md](REV3_PROGRESS.md:143) incorrectly calls workbook X2/X0/H invented; those values are now directly verified. Its claimed identity of [GENERATION AND TRANSFORMERS SYSTEM.pdf](fwdtechnicaldatasldrequestforbueteeetermproject/GENERATION%20AND%20TRANSFORMERS%20SYSTEM.pdf) as drawing DE-0026 is also incorrect: the supplied drawing identifies itself as **DE-0023** and references DE-0026. Presence of that reference does not establish that the GIS drawing was supplied.

## 7. Unit/base conversions

Use three-phase apparent power and line-to-line RMS voltage:

**Zbase = VLL² / Sbase.** With kV and MVA, the result is ohms.

| Calculation | Result |
|---|---:|
| Machine Zbase = 22² / 458 | **1.056768558951965 Ω** |
| Ra_ohm | **0.00089 Ω** |
| Ra_pu_machine = 0.00089 / Zbase | **0.000842190082644628 pu**, 458 MVA / 22 kV |
| System Zbase = 22² / 100 | **4.84 Ω** |
| Ra_pu_system = 0.00089 / 4.84 | **0.000183884297520661 pu**, 100 MVA / 22 kV |
| Xdpp on 100 MVA / 22 kV | **0.0569432314410480 pu** |
| Xdpp_sat on 100 MVA / 22 kV | **0.0490829694323144 pu** |

General impedance conversion: new pu = old pu × (new MVA / old MVA) × (old kV / new kV)². Keep machine-base data primary; derive system-base views once. The SPS machine/transformer block base and the 100 MVA reporting base are not interchangeable. Field resistance must not be converted as though its field-circuit base were the stator impedance base.

Inertia unit kW·s/kVA equals MW·s/MVA and seconds. Preserve H = 5.287 s on the combined train's selected 458 MVA base; use the same power base in swing equations. Seconds, SCR and saturation coefficients do not receive impedance scaling.

Automated test design: compare the stored machine resistance against 0.000842190082644628 with absolute tolerance 1e-12; compare system resistance against 0.000183884297520661 with 1e-12; recover 0.00089 Ω from each base with 1e-12 Ω; verify machine/system round trip and reject the erroneous numeric identity Ra_pu_machine = 0.00089. Add these to [test_base_conversion.m](matlab/tests/test_base_conversion.m:42) during implementation, not during this audit.

## 8. Missing values now resolved

Remove the blanket missing status, in the next approved data/documentation change, for Xq, Xqp, Xqpp, Xl, X2, X0, Ra, H, all nine supplied time constants, the two saturation coefficients, excitation type/controller designation, SCR, active-power capacity and separate Xdpp_sat. Update both the executable fields and human-facing descriptions/tests. Rf's numeric value is present; retain the unit qualification.

Also correct pre-existing documentation gaps: transformer excitation current is available; the old generator reactances are explicitly saturated; UAT/GAT datasheets provide approximate endpoint tap impedances, although complete tap arrays remain unavailable. A supplied numeric value is not automatically a validated plant model.

## 9. Missing data and qualifications that genuinely remain

| Item | Evidence / consequence |
|---|---|
| Generator damper XD, XQ, field reactance Xf, damper RD/RQ | Workbook R3/S3/T3/W3/X3 are blank. Do not invent rotor-circuit parameters; standard reactance/time-constant models may not need independent entries |
| Ta(1) | AH3 blank; AG3 Ta or Ta(3) is not a substitute |
| Rf unit and field reference base; Ra temperature/test definition | Numeric resistance data exist, but these semantics need confirmation for detailed circuit identification |
| Exact saturation convention/full OCC | Two coefficients exist; not a full measured voltage-versus-field-current characteristic or a controller calibration |
| Damping coefficient, turbine/governor/PSS/SEMIPOL gains, limits, time constants, deadbands and settings | No verified values identified; generic controls require explicit future assumption profiles |
| Generator capability envelope and actual operating P/Q/V/taps | 458 MVA circle is only a stator apparent-power check, not complete field/underexcitation limits. Availability claims for the full capability attachment conflict; it was not verified in this audit |
| Generator/plant zero-sequence resistance, capacitances, effective neutral AC impedance and grounding operating states | Workbook X0 alone does not complete earth-fault paths. Retain documented NER components; do not label an approximate NER-only current as a measured total earth-fault current |
| GAT ZPT and ZST; tertiary/zero-sequence model details | Still MISSING. Documented Z0 does not identify the entire three-winding zero-sequence network |
| UAT/GAT neutral hardware and settings | Datasheets specify impedance-limited 5 A LV earthing; actual installed resistance/settings and switching require confirmation |
| Current PGCB maximum/minimum grid strengths, R/X and zero-sequence equivalents | Siemens estimate and historical secondary references do not replace an official present-day network dataset |
| Feeder/cable/IPB impedances; South outgoing line identification/electrical data | No invented line inserted. External secondary route references do not establish the exact plant terminal mapping |
| Actual auxiliary allocation, motor operating factors/PF/efficiency/dynamic data | Preserve 14 MW / 0.85 aggregate and existing labelled allocation, not a new motor model |
| Cooling stage and whether cooling is included in the 14 MW aggregate | Needed before adding separate cooling loads; no double counting |
| Complete relay settings, CT saturation/burden details, trip chain timing, GIS bay mapping and normal switching | Some CT/VT ratings and relay identities are present; missing detailed settings must not be replaced with assumed as-built records |
| Validation data | No verified plant disturbance/commissioning dataset establishing dynamic fidelity |

These gaps do not all block provisional balanced LF. Separate “source missing”, “model not using this parameter” and “feature blocked”. Unconstrained LF Q is a modelling choice; physical capability limits remain unresolved.

## 10. Grid audit

### 10.1 Primary estimated grid versus equipment ratings

[Generator Data_South.pdf](fwdtechnicaldatasldrequestforbueteeetermproject/Generator%20Data_South.pdf), PDF p.2 / report p.7, §2.4, states nominal grid voltage 230 kV, **grid impedance (estimated) XN = 2.66 Ω**, grid three-phase short-circuit power 19,919 MVA and maximum apparent three-phase short-circuit current 50 kA. This is direct documentary support for a Siemens engineering estimate, **not a measured PGCB fault level**.

The selected unchanged primary LF equivalent is R = 0 by explicit assumption, with magnitude/reactance **230/(√3 × 50) = 2.655811 Ω** and power **19,918.584 MVA**, consistent with the rounded source. No numeric physical-model change is necessary to correct the attribution. Keep missing R/X distinct from the supplied estimated strength. A withstand rating alone does not prove an actual grid-strength upper bound or a universal direction of voltage error.

The recovered [Data Sheet_230KV.pdf](tmp/rev3_newsrc/Data%20Sheet_230KV.pdf) has a North transmittal cover but **South body pages**. Its disconnector table separately gives 50 kA for 1 s and 3 s and 125 kA peak. Its transformer-bay circuit-breaker section separately gives 50 kA interrupting and 125 kA making ratings. Preserve equipment class, duration and applicable bay; do not assign interrupting duty to disconnectors merely because they withstand 50 kA. The source also distinguishes 2000 A transformer/line modules from the 3150 A coupler; broad 3150 A bay assertions need a scoped rating review, not a network rewrite.

### 10.2 Secondary sensitivity and voltage-factor ambiguity

The 45.01 kA / X/R 10.99 / 3.25 Ω set is found in the secondary [master compilation](Ashuganj_South_Final_Master_Data_and_Assumptions%20%281%29.md:524); the underlying official 2019 study was not verified. Keep it secondary.

- If selected from **45.01 kA at c = 1**, magnitude is **2.950245766 Ω**; derive R = magnitude / √(1 + 10.99²), X = 10.99R.
- Legacy R = 0.268 Ω and X = 2.94 Ω imply magnitude about **2.95219 Ω** and X/R about **10.9701**, consistent only approximately with the preceding rounded interpretation, not with 3.25 Ω.
- If selected from **reported magnitude 3.25 Ω and X/R 10.99**, R = **0.2945067125 Ω**, X = **3.2366287702 Ω**. This is a different coherent profile.
- A voltage factor near 1.10 could explain the 3.25 Ω versus 45.01 kA relation: 45.01 kA with c = 1.10 implies **3.245270342 Ω**. This is a plausible reconciliation, **not proof of the source's method**. Do not silently turn it into the primary grid or declare the conflict closed.

Store voltage factor, current type, source date, selected independent quantities and boundary with every grid profile. Do not combine the 50 kA magnitude with the secondary R/X unless explicitly running a separately labelled split sensitivity.

## 11. Grid sensitivity failures: individual root causes

Historical evidence is preserved in [verify.log](results/verify.log:57): **29 passed, 6 failed** in the grid test. [grid_sens.log](results/grid_sens.log:23) subsequently records **38 passed, 0 failed** for an earlier magnetising configuration. Current code already fixes several historical issues. This is not a basis for claiming the current suite has exactly six failures without rerunning it.

| Historical failure | Root-cause classification | Required treatment |
|---|---|---|
| 1. Grid loss reported zero for all finite X/R | **Test setup/post-processing input defect**, not physical-model defect | Model was changed to RL while branch reconstruction received R = 0 data. Current [test_grid_sensitivity.m](matlab/tests/test_grid_sensitivity.m:237) already supplies a matching case-local data copy |
| 2. Plant loss spread about 1.39 MW | **Test bookkeeping defect plus expectation/documentation defect** | Missing grid loss made system loss look like plant loss. Even after correcting that, internal loss is not mathematically invariant because GSUT current and voltage change |
| 3. Plant-boundary export spread about 1.39 MW | **Test bookkeeping defect plus expectation/documentation defect** | Swing delivery was mistaken for plant-boundary delivery. Boundary export = swing delivery + grid loss, but its value can still change with internal loss |
| 4. Angle must monotonically fall / be overstated with R = 0 | **Test expectation and documentation defect** | Recorded angles are nonmonotonic; preserve measured values and case conditions, not a universal sign assertion |
| 5. R = 0 understates voltage drop | **Test expectation and documentation defect** | In this P-dominant export case boundary voltage rises when R is introduced. Do not generalize that direction to all operating conditions |
| 6. X/R effect must be smaller than impedance-magnitude uncertainty | **Test expectation and documentation defect** | Measured finite-X/R shift is larger for the chosen probes. Relative sensitivity is a result, not an a priori invariant |

Preserved historical finite-X/R results, from [grid_sens.log](results/grid_sens.log:23):

| X/R | Boundary V pu | Angle degrees | Generator Q MVAr | Grid loss MW |
|---:|---:|---:|---:|---:|
| Infinite | 0.998686 | 1.0787 | 31.1595 | 0.0000 |
| 20 | 0.999497 | 1.0801 | 28.5344 | 0.3535 |
| 10 | 1.000304 | 1.0795 | 25.9209 | 0.7040 |
| 5 | 1.001889 | 1.0729 | 20.7928 | 1.3862 |

**Remaining current test-design issues:**

1. [test_grid_sensitivity.m](matlab/tests/test_grid_sensitivity.m:309) still asserts plant loss and boundary export invariant within 0.005 MW. Small historical spread passed that tolerance; it does not prove physical independence. Replace with independent conservation checks, not relaxed tolerances.
2. The magnitude sweep changes the model inductance but [its branch reconstruction](matlab/tests/test_grid_sensitivity.m:58) still receives the original data. Grid current and reactive loss at non-unit scales are therefore reconstructed with the wrong impedance. Match case-local data for both sweeps; retain every measured bus solution.
3. [test_magnetising_sensitivity.m](matlab/tests/test_magnetising_sensitivity.m:107) similarly changes block magnetising inductance while reconstructing branch powers from the unchanged registry. Its derived/base row matches; off-base reconstructed branch totals require synchronized data.
4. “Everything inside the plant is unaffected” is false. Approximate radial UAT/MV independence follows the ideal PV constraint only with fixed auxiliary demand and the stated GAT switching/snubber treatment. GSUT Q/current/loss and boundary voltage are not insulated from the grid. GAT-in cases also couple the auxiliary bus to the grid.
5. The runner returns counters instead of throwing on failed checks. An external automation job must inspect the failure count; process exit zero alone is not a passing suite.

Replacement independent checks: grid loss = 3I²R in MW; plant loss = sum of internal branch losses including separately labelled snubber loss; system loss = plant loss + grid loss; generator terminal P = auxiliary P + plant loss + boundary export; boundary export = swing delivery + grid loss. Derive one side from solved source injections and the other from branch terminal powers, not from the same definition twice. Preserve existing numeric tolerances until a measured error budget justifies changes. No resistor, tap or dispatch adjustment to make a test pass.

## 12. Transformer magnetising branch and loss-accounting audit

The implementation in [ashuganj_transformers.m](matlab/data/ashuganj_transformers.m:377) correctly removes the core-loss component from total no-load current:

**Rm = S/P0; Xm = 1/√(I0² − (1/Rm)²).** The SPS per-unit inductance entry represents magnetising reactance at nominal frequency. Retain internal-node placement in [ashuganj_branch_flows.m](matlab/analysis/ashuganj_branch_flows.m:124).

| Transformer | Primary rating/base MVA | Z / R percent | P0 kW | I0 percent | Copper loss at top rating kW | Total including cooling kW | Cooling kW |
|---|---|---|---:|---:|---:|---:|---:|
| GSUT | 355/460/515; impedance base 515 | 16 / 0.21 | 159 | 0.13 | 1095 | 1282 | **28** |
| UAT | 19/25; impedance base 25 | 10.5 / 0.4 | 14 | approximately 0.3 | 110 | 125.25 | **1.25** |
| GAT | 19/25; impedance base 25 | ZPS 12 / 0.5 | 23 | 0.3 | 116 | 140.25 | **1.25** |

Source locations: GSUT [datasheet](fwdtechnicaldatasldrequestforbueteeetermproject/GSUT%20Data%20Sheet_South.pdf), PDF p.4 excitation and p.6 §1.7 losses; UAT/GAT [datasheet](fwdtechnicaldatasldrequestforbueteeetermproject/UAT%20%20Data%20Sheet_South.pdf), pp.5/16 excitation and pp.9–10/20–21 losses. Several existing CSV references cite equipment-section starting pages rather than the actual loss pages; correct locators later.

**1282 − 159 − 1095 = 28 kW, not 128 kW.** The 28 kW is also directly stated, not just inferred. At GSUT lower cooling ratings the source totals imply cooling of 0 kW at 355 MVA and 8 kW at 460 MVA. UAT/GAT 19 MVA totals imply zero forced-cooling contribution. Do not apply top-stage cooling consumption indiscriminately to every operating state.

Accounting findings:

- Core loss is represented by Rm exactly once; it is already included in branch sending-minus-receiving P. Do not add the tabulated no-load loss again to solved network losses.
- Winding copper loss is represented by split series resistance. Documented full-load copper loss is an **independent cross-check**, not an additional load. Current R values imply rated copper losses 1081.5/100/125 kW versus tabulated 1095/110/116 kW. Retain both and their approximate-source differences; do not add the discrepancy as another loss.
- Magnetising VAR is represented by Xm once, after subtracting active current in quadrature. Rated total is approximately 0.7954 MVAr; actual solved draw depends on internal voltage. It is not active loss and not identical to the increment in generator Q.
- Cooling consumption is not separately added by the current LF transformer provider. Its inclusion in the 14 MW auxiliary aggregate is unknown. Record this accounting boundary; do not increase auxiliary demand without resolving overlap.
- System balance and reconstructed branch loss are compared, not added together, in [run_load_flow_study.m](matlab/studies/run_load_flow_study.m:218). No active core/copper double counting was found in that path.
- “GAT out” opens its HV bay but leaves it back-energized from the LV bus; current code explicitly includes its magnetising branch. Do not remove its no-load draw merely because the bay is open. Distinguish this from a future fully isolated case.
- Correct stale “Lm open” comments, datasheet-versus-nameplate attribution, and the assertion that equal winding splitting has absolutely no numeric consequence with a finite internal shunt. Equal splitting remains a representation assumption; no split retuning is proposed.

## 13. Master registry design for all four study types

Extend the existing constructor and equipment providers rather than introduce another competing master. Target: source documents → authoritative registry → LF / fault / protection views → dynamic initialization → Simulink adapters → validation. Dynamic inputs also consume the registry directly; no source information is inferred from a rendered model.

### 13.1 Parameter record and governance

Each parameter record needs: component ID/KKS; canonical parameter name; numeric or text value; raw value and raw unit; normalized unit; source document identity and checksum; page/section or sheet/cell; source revision/date; confidence; source status; assumption flag; interpretation note; machine/system/field base; phase/sequence; saturation condition; temperature/operating condition if supplied; dataset ID; selected-primary flag; supersedes/alternative record IDs; derivation equation and input record IDs; study applicability.

Keep existing status vocabulary and extend it deliberately for SOURCE/DATASET RECONCILIATION and secondary/legacy use. Distinguish direct transcription from a selected interpretation, and derived-from-estimate from derived-from-verified. Missing values remain explicit, with a reason and blocked capability. No global replacement or silent fallback.

### 13.2 Domain fields

| Domain | Required design fields |
|---|---|
| Base/meta | Revision, dataset checksum, 100 MVA reporting base, 50 Hz source, per-bus nominal kV, machine 458 MVA/22 kV base, method/profile identifiers |
| Machine | All canonical quantities in §3, both Xdpp fields, saturation qualifiers, source-qualified legacy set, NER reference, rated PF versus actual operating PF, capacity versus dispatch versus PF reference |
| LF cases | Case ID/revision, dispatch, capacity exception approval, P/Q boundary, generator/grid voltage setpoints, GAT/coupler state, tap positions, auxiliary allocation, Q-limit treatment and capability-check status |
| Transformers | Cooling stages, actual stage if known, winding and bus voltages, vector group, Z/R/base, derived X, no-load current/loss, Rm/Xm, independent copper/total/cooling records, accounting inclusion flag, tap table, Z0 and missing GAT ZPT/ZST |
| Grid | Independent equipment ratings and network equivalents; primary/secondary profile, R/X/Z, voltage/current bases, current definition, voltage factor, source date, zero-sequence availability, boundary and assumptions |
| Fault | Selected subtransient field, sequence impedances, neutral impedances and delta blocking, prefault LF revision/phasors, topology, method/voltage corrections, fault impedance/type/location, peak/DC/clearing assumptions |
| Protection | Device class and KKS, associated bay/zone and winding, source/terminal/sequence current basis, CT/VT ratio/core/polarity/burden, relay function/curve/settings/status, breaker interrupting versus withstand/making ratings, timing and source revision |
| Dynamics | Sixth-order formulation and state convention, machine/base profile, saturation representation, LF initialization reference, damping availability, separate AVR/governor/PSS assumption profiles, events/clearing, validation status |
| Simulink/validation | Block/release mapping, supported and unused parameters, conversion lineage, source model versus dynamic model type, initial conditions, run fingerprint, per-bus KCL and independent loss checks, source/model/test limitations |

Compatibility: existing LF providers remain callable views of the selected master, preserving their existing interface while canonical machine fields are introduced. Percent fields, where still required for display, become derived views rather than independently edited values. Freeze Rev2 records for historical reproduction; migrate live consumers through explicit adapters with complete profile checks, not a wholesale copy of Rev2 into the current master.

## 14. Load-flow changes required — not implemented here

1. Add the verified machine fields and metadata; do not insert machine reactances or inertia into the ideal PV LF equivalent.
2. Separate 360 MW capacity, PF 0.85, 389.30 MW PF/OEM reference, and operating dispatch. PF 0.85 is not a requirement to force the PV source's solved operating Q.
3. Keep the four main comparison slots: recommend future LF1/LF2 at **360 MW** with GAT out/in and LF3/LF4 retaining the **342.01 MW scenario** with its boundary qualification. Preserve old 389.30 MW runs under explicit legacy/PF-derived sensitivity IDs; do not overwrite historical evidence or relabel it as 360 MW.
4. Keep 14 MW, PF 0.85 and **Q = 8.67642073764343 MVAr**; retain allocation assumptions, transformers, ratios and principal taps. Do not adopt Rev2 12+j5 or its GSUT values.
5. Add a primary capacity guard and revisioned result identifiers. A legacy override requires explicit case classification and rationale; no silent primary over-capacity allowance.
6. Preserve [fresh build and independent KCL](matlab/studies/run_load_flow_study.m:169). Changing the dataset is not changing the solver.
7. Future non-unit voltage cases must actually use the case-specific generator setpoint: [build_generator_system.m](matlab/build/build_generator_system.m:68) currently uses the generator record, not the case's voltage field. This is an adapter issue for the future sensitivity, not a present 1.0 pu LF defect.
8. Report plant-boundary export and swing-node delivery separately when grid resistance is nonzero. Neither 360 nor 389.30 MW is net export.

### Preserved comparison baseline

Recorded values from [system_summary.csv](results/load_flow/system_summary.csv):

| Legacy case | Generator MW | GAT | MV voltage pu on 6.6 kV | Network loss MW | Swing delivery MW | Worst KCL residual MVA |
|---|---:|---|---:|---:|---:|---:|
| LF1 | 389.30 | Out, LV back-energized | **1.000911168** | 0.816493662 | 374.483506233 | 8.61e-8 |
| LF2 | 389.30 | In | **1.020279743** | 0.833419291 | 374.466580642 | 0.000613886 |
| LF3 | 342.01 | Out, LV back-energized | 1.000907610 | 0.680192057 | 327.329807893 | 8.62e-8 |
| LF4 | 342.01 | In | 1.020818101 | 0.690257248 | 327.319742715 | 0.000517957 |

All four recorded checks are OK. These are computed model results, not plant measurements. At the present R = 0 assumption swing delivery and plant-boundary export coincide in active power. No forced 1.0 pu MV voltage or cosmetic tap adjustment is proposed.

### Future voltage/tap sensitivity design

- First sweep generator setpoint **0.98 / 1.00 / 1.02 pu** at unchanged principal taps, both GAT states and each capacity-compliant dispatch scenario.
- Then vary one transformer tap at a time, keeping all other controls fixed: GSUT positions **8/9/10** = 232.875/230/227.125 kV HV; UAT **2/3/4** = 22.55/22/21.45 kV HV; GAT **12/13/14** = 232.875/230/227.125 kV HV when in service.
- UAT changes are off-circuit scenarios, not online tap control. A common bus voltage is not an instruction to move taps.
- Preserve 6.9 kV winding and 6.6 kV reporting bases; report both bases, actual kV, Q/current, each cooling-stage loading, losses, boundary export and KCL.
- Intermediate tap impedance data are not fully supplied. A ratio-only sweep holding principal impedance is a labelled approximation, not a manufacturer tap-impedance curve. Review endpoint source data and block ratio mapping before implementation.
- Use fresh builds; separately list capability-limited, nonconverged or unvalidated cases rather than forcing results into an attractive range.

## 15. Fault-study changes required

[seq_networks.m](rev2/data/seq_networks.m:27) must eventually consume the same selected registry and LF snapshot, not old result files with hard-coded P1A fallbacks. Preserve its sequence-method work but review assumptions before reuse.

- Rebase machine impedances exactly once; use explicit selected Xdpp/Xdpp_sat and supplied saturated X2/X0. Sequence resistances R2 = R1 and R0 = 1.5R1 are Rev2 assumptions, not workbook facts.
- Restore generator NER path and 3Zn in zero sequence. Siemens gives a 22 kV/√3 : 500 V neutral transformer, 135 kVA / 20 s, 60 Ω HV DC resistance and 2.62 Ω secondary loading resistor. The precise AC equivalent/test conditions still need qualification; do not promote DC resistance to exact fault impedance without method review.
- Keep GSUT LV delta zero-sequence blocking and HV neutral grounding. Use documented Z0 magnitude 15.8% with an explicit R0/X0 treatment rather than automatically setting Z0 = Z1.
- UAT/GAT LV neutrals are impedance-limited in the datasheets, not unrestricted solid sources. The balanced GAT two-winding model is not approved as an earth-fault equivalent; ZPT/ZST remain missing.
- Remove live dependence on the unverified assumed 0.7 km line/electrical constants unless a separately authorized sensitivity uses them. Match the LF and fault boundary/topology.
- Preserve fault component phasors and through-device currents; do not infer device duty from the total bus fault current alone. Revalidate KCL, prefault continuity and phase shifts after migration.
- Classical initial symmetrical faults, steady fault current, peak/asymmetric duty and interruption-time current are different outputs. Time constants and Ta do not by themselves make the existing source model a validated decrement model.

The solid-neutral Rev2 earth-fault model is a confirmed source/model mismatch. Existing earth-fault and dependent protection conclusions must remain labelled legacy/unvalidated until corrected; do not delete the result files.

## 16. Protection-study changes required

[run_phase3_protection.m](rev2/run_phase3_protection.m:18) currently reads legacy registry values and unversioned LF/fault CSVs. It must require matching master/case/method fingerprints and verified branch/sequence currents, or reject the input.

Use sourced CT/VT information already present in the Siemens report and protection drawing rather than calling all instrument data missing. Distinguish generator terminal CTs from GSUT winding CTs; do not use generator 458 MVA current as the GSUT 515 MVA LV winding rating in a differential mismatch calculation. Review the current hard-coded calculation at [run_phase3_protection.m](rev2/run_phase3_protection.m:106).

Review relay zones and actual devices: Q0 is a breaker; Q1/Q2 are bus-selection disconnectors; Q9's identity must follow the specific drawing/bay rather than a generic “line breaker” label. The current [fault duty table](rev2/run_phase2_fault.m:66) gives interrupting fields even to disconnector-labelled rows. Correct the equipment model/reporting, not just its pass/fail limits.

Recalculate pickup/loading with the preserved 14 MW / 0.85 aggregate and capacity-compliant LF. Earth-fault protection must reflect high-resistance/impedance grounding and residual/neutral current, not total phase fault current. Existing proposed slopes, pickups and time multipliers remain engineering proposals until confirmed by actual relay settings. Manufacturer breaking time is not the complete relay-plus-breaker fault-clearing time.

## 17. Dynamic-study design and readiness

**No validated plant dynamic model was identified.** The audited MATLAB/Rev2 tree contains ideal-source LF/fault representations, not a verified sixth-order synchronous-machine implementation. A standalone machine parameter exporter was not located. Do not describe a missing artifact as already implemented or an ideal source as a dynamic generator.

Recommended future model: a standard sixth-order two-axis synchronous machine with rotor electrical angle, speed deviation, d/q transient internal states and d/q subtransient internal states. Fix the Park transform, current direction, torque/power and state/base conventions in the implementation specification.

- Use the primary workbook d/q reactances, leakage, inertia and **four open-circuit time constants** as the normal independent standard-model inputs.
- Retain all four short-circuit time constants and Ta as source data for parameter-consistency/decrement validation; they are not extra independent state equations to append to a sixth-order model. Do not feed open- and short-circuit constants into unrelated mask slots just to use every value.
- Preserve Xdpp_sat for the explicit saturated fault profile and cross-check; it is not a seventh state or a replacement for unsaturated Xdpp.
- Keep saturation coefficients S(1.0) and S(1.2) separate from a measured OCC. Select and document a two-point saturation law only after checking the chosen block's convention. Do not pass these coefficients directly as voltage/current curve pairs when the block expects an OCC.
- Keep Xl and Rf available, but only consume parameters supported by the selected standard-model interface. Missing explicit damper values need not block a standard reactance/time-constant model; they do block claiming a fully identified physical rotor circuit.
- Initialize from a newly solved, capacity-compliant LF on the same topology/base, including terminal P/Q/V, rotor angle, field input and mechanical power balance. Generator terminal P is not shaft input if electrical/mechanical losses are represented.
- Static/SEMIPOL identifies hardware/type only. If exact controls remain unavailable, a later generic AVR/governor abstraction must have a separate assumption record and prominent “not plant controller” label. Do not invent a damping coefficient or controller settings now.
- Validation gates: no-disturbance equilibrium, initial P/Q/V matching, positive time constants/reactance ordering, saturation enabled/disabled comparison, small-step behavior, fault/decrement comparison under matched assumptions, clearing-time sensitivity and finally plant/OEM benchmark comparison if obtained.

A sixth-order electromechanical model is not automatically an EMT stator-transient/DC-offset model; Ta-related claims must match the model's actual state content.

## 18. Simulink changes required

Retain the existing ideal PV source for balanced LF. [build_generator_system.m](matlab/build/build_generator_system.m:63) already reads most electrical LF values from the current provider; its missing-data explanation and hard-coded nameplate display need revision after migration.

[build_loadflow_v2.m](rev2/simulink/build_loadflow_v2.m:16) hard-codes another machine/grid/transformer profile and an external absolute root. It must not become the primary exporter. Future active paths must obtain machine data from the master and avoid destructive model-copy routines as a migration strategy.

Propose one new parameter-adapter file, [export_simulink_parameters.m](matlab/data/export_simulink_parameters.m), in a later approved implementation. It will carry every machine source parameter plus supported/unused mapping metadata, use explicit block bases and distinguish LF source, fault equivalent and dynamic machine profiles. No fabricated mask parameters for unsupported inputs. A future separate dynamic builder must consume this adapter and the matched LF initialization. Existing LF models remain preserved and are rebuilt only after approval, never by saving a solved model over the specification.

## 19. Test changes required

Tests must follow verified data rather than freeze obsolete missingness. Retain the test recorder and existing physical checks.

1. [test_generator_data.m](matlab/tests/test_generator_data.m:19): assert all §3 numerical values, each time constant, both saturation coefficients, Static/SEMIPOL, raw ohm unit, selected base and workbook provenance. Preserve additional sourced ratings and legacy records. Replace obsolete missing assertions only for resolved parameters.
2. [test_base_conversion.m](matlab/tests/test_base_conversion.m:42): separate saturated/unqualified subtransient conversions and add the resistance test in §7, including inverse conversion and no double conversion.
3. [test_topology.m](matlab/tests/test_topology.m): retain the 2×2 topology matrix; verify primary dispatch at or below 360 MW and explicit legacy-case classification. Keep the PF reference test without treating it as primary dispatch.
4. [test_grid_sensitivity.m](matlab/tests/test_grid_sensitivity.m): synchronize model/reconstruction data in both sweeps; replace global plant/export invariance with independent conservation and scoped radial invariance; preserve historical values as revision-specific results, not immutable universal truths.
5. [test_magnetising_sensitivity.m](matlab/tests/test_magnetising_sensitivity.m:107): synchronize modified Xm with reconstruction; verify no-load current decomposition and loss accounting for every probe.
6. [test_transformer_data.m](matlab/tests/test_transformer_data.m): preserve Z/R/ratio/tap checks; add cooling arithmetic, source locator and separate copper/core/network accounting tests; keep GAT ZPT/ZST missing.
7. [test_line_data.m](matlab/tests/test_line_data.m): correct grid source/equipment-bay rating assertions without inserting assumed lines.
8. [run_all_tests.m](matlab/tests/run_all_tests.m:19), [t_case.m](matlab/tests/t_case.m:15), and model comments: stop using sourced Xq as the example of a value that must remain missing; ensure CI treats a nonzero failure count as failure.
9. Rev2 fault/protection tests must eventually assert migrated profiles, neutral/sequence topology, device classes, CT/current bases and matched prefault fingerprints, not simply old numerical outputs. Do not increase KCL tolerances to hide omitted networks.
10. Add future exporter/registry integration tests that perturb an in-memory machine field and prove propagation without a second hard-coded primary value. Unsupported dynamic mappings fail clearly; missing controls remain missing.

No tests were edited in this reconciliation stage. Any legacy data tests that pass while enforcing obsolete missing values are passing the old specification, not validating REV3.1.

## 20. Exact proposed file changes and order

Only this report and [REV3_1_ACTION_PLAN.md](REV3_1_ACTION_PLAN.md) are authorized outputs now. The following are future targeted changes, not permission for a broad rewrite.

| Priority | Exact file(s) | Purpose |
|---|---|---|
| P0 | [ashuganj_generators.m](matlab/data/ashuganj_generators.m), [Ashuganj_Master_Data.csv](data/master/Ashuganj_Master_Data.csv) | Primary workbook machine fields, source/base/unit/saturation metadata, legacy retention, capacity/PF separation |
| P0 | [test_generator_data.m](matlab/tests/test_generator_data.m), [test_base_conversion.m](matlab/tests/test_base_conversion.m) | Data-driven expectations and resistance/base regression |
| P0 | [ashuganj_master_data.m](matlab/data/ashuganj_master_data.m), [test_topology.m](matlab/tests/test_topology.m) | Authoritative case profiles, 360 MW primary guard, explicit historical sensitivities |
| P0 | [ashuganj_grid.m](matlab/data/ashuganj_grid.m), [grid_series_resistance_zero.m](matlab/data/assumptions/grid_series_resistance_zero.m), [ashuganj_lines.m](matlab/data/ashuganj_lines.m) | Correct estimated grid provenance, scoped claims and equipment-versus-network identities |
| P0 | [test_grid_sensitivity.m](matlab/tests/test_grid_sensitivity.m), [test_magnetising_sensitivity.m](matlab/tests/test_magnetising_sensitivity.m), [test_line_data.m](matlab/tests/test_line_data.m) | Case-local reconstruction, physical invariants and bay ratings |
| P1 | [ashuganj_transformers.m](matlab/data/ashuganj_transformers.m), [test_transformer_data.m](matlab/tests/test_transformer_data.m) | Cooling/accounting/source records only; retain existing primary impedances and magnetising physics |
| P1 | [ashuganj_branch_flows.m](matlab/analysis/ashuganj_branch_flows.m), [run_load_flow_study.m](matlab/studies/run_load_flow_study.m) | Targeted boundary/loss labels and fingerprints; preserve solver, KCL and fresh-build flow |
| P1 | [build_generator_system.m](matlab/build/build_generator_system.m), [build_ashuganj_main.m](matlab/build/build_ashuganj_main.m) | Data-driven captions, case-setpoint propagation and representation warnings, not a topology rewrite |
| P1 | [missing_parameters.md](docs/validation/missing_parameters.md), [verified_parameters.md](docs/validation/verified_parameters.md), [conflicting_parameters.md](docs/validation/conflicting_parameters.md), [source_inventory.md](docs/validation/source_inventory.md), [load_flow_readiness.md](docs/validation/load_flow_readiness.md), [assumptions.md](docs/validation/assumptions.md), [generator_list.md](docs/model/generator_list.md) | Resolve supplied data, retain true gaps, correct sources and model readiness |
| P1 | [DATA_RECONCILIATION_REV3.md](DATA_RECONCILIATION_REV3.md), [REV3_PROGRESS.md](REV3_PROGRESS.md), [rev3_b1_derivations.m](matlab/studies/rev3_b1_derivations.m) | Append corrections to unsupported interpretation/identity claims; retain original audit history |
| P1 | [gui_symbols.m](matlab/gui/gui_symbols.m), [run_all_tests.m](matlab/tests/run_all_tests.m), [t_case.m](matlab/tests/t_case.m) | Remove obsolete missing-value descriptions and expose revision/status correctly |
| P2 | [ashuganj_rev2_registry.m](rev2/data/ashuganj_rev2_registry.m), [reconciliation_register.csv](rev2/data/reconciliation_register.csv), [run_phase1_loadflow.m](rev2/run_phase1_loadflow.m), [run_full_project.m](rev2/run_full_project.m) | Preserve legacy snapshot while routing new active study profiles through the master; no silent data substitution |
| P2 | [seq_networks.m](rev2/data/seq_networks.m), [run_phase2_fault.m](rev2/run_phase2_fault.m), [test_rev2_registry.m](rev2/tests/test_rev2_registry.m), [test_phase2_fault.m](rev2/tests/test_phase2_fault.m), [test_phase2_kcl.m](rev2/tests/test_phase2_kcl.m) | Correct neutral/sequence methodology and source/base/prefault linkage |
| P2 | [run_phase3_protection.m](rev2/run_phase3_protection.m), [test_phase3_protection.m](rev2/tests/test_phase3_protection.m), [add_protection.m](rev2/simulink/add_protection.m) | Correct device/CT/current semantics and consume reconciled fault/LF data |
| P2 | [build_loadflow_v2.m](rev2/simulink/build_loadflow_v2.m), [run_loadflow_v2_tests.m](rev2/simulink/run_loadflow_v2_tests.m) | Eliminate active hard-coded primary values and external root; retain legacy artifacts |
| P3 — new | [export_simulink_parameters.m](matlab/data/export_simulink_parameters.m), [test_simulink_parameter_export.m](matlab/tests/test_simulink_parameter_export.m) | Master-fed parameter mapping and propagation tests |
| P3 — new | [build_dynamic_generator_system.m](matlab/build/build_dynamic_generator_system.m), [test_dynamic_machine_initialization.m](matlab/tests/test_dynamic_machine_initialization.m) | Separate sixth-order implementation and initialization verification only after model-method approval |

Generated manuals/reports require a later source-driven refresh, not hand-editing historic results: [build_lab_report.m](matlab/studies/build_lab_report.m), [build_user_manual.m](matlab/studies/build_user_manual.m), [build_project_update.m](matlab/studies/build_project_update.m), and their directly affected content producers [lr_part_data.m](matlab/studies/private/lr_part_data.m), [lr_part_next2.m](matlab/studies/private/lr_part_next2.m), [um_part_care.m](matlab/studies/private/um_part_care.m). Preserve old report/result revisions, including [Rev2_Final_Report.md](rev2/reports/Rev2_Final_Report.md), rather than making historic runs appear to use new inputs.

## 21. Audit execution evidence and stop condition

The workbook extraction and independent PowerShell arithmetic were executed read-only. A 924-file SHA-256 baseline was captured outside the workspace before audit execution. MATLAB R2024a was invoked to run the unchanged suite and the unchanged four LF cases with both result writing and model saving disabled; caches and console output are directed to the operating-system temporary directory. The audit deliberately does not run destructive Rev2 model builders or overwrite historical results.

### Verified current execution results

The unchanged suite completed: **447 passed, 0 failed** across ten test files. Grid sensitivity returned **38 passed, 0 failed**; magnetising sensitivity returned **41 passed, 0 failed**. All four unchanged LF cases converged in two iterations and passed the existing cross-checks. Their generator P/Q, loss, swing delivery and KCL residuals reproduced the preserved §14 table to the printed precision.

Current finite-X/R results, with the documented magnetising branches in place:

| X/R | Boundary V pu | Angle degrees | Generator Q MVAr | Grid loss MW |
|---:|---:|---:|---:|---:|
| Infinite | 0.998672 | 1.0787 | 31.6759 | 0.0000 |
| 20 | 0.999483 | 1.0801 | 29.0509 | 0.3536 |
| 10 | 1.000290 | 1.0796 | 26.4374 | 0.7041 |
| 5 | 1.001875 | 1.0730 | 21.3091 | 1.3864 |

The current magnitude sweep at factors 0.5/1/2/4 returned boundary voltages 0.999328/0.998672/0.997394/0.994924 pu, generator Q 29.5521/31.6759/35.8102/43.8037 MVAr and MV voltage approximately 1.0009112 pu throughout. These are solved-bus results; the non-unit-scale reconstructed grid quantities retain the test-input caveat in §11.

Independent MATLAB arithmetic confirmed Rm = 3238.993710692 / 1785.714285714 / 1086.956521739 pu and Xm = 791.886792164 / 339.297053229 / 350.207384175 pu for GSUT/UAT/GAT. Rated magnetising draw is 0.650345485 / 0.073681748 / 0.071386273 MVAr. Resistance conversions and 28/1.25/1.25 kW cooling closure matched §7/§12.

After the executable audit, all **924 pre-existing file hashes were unchanged** and no pre-existing file was missing. The only intended workspace additions are the two requested Markdown documents. No registry, test, model or historical result was rewritten. The full console transcript and hash baseline are temporary audit artifacts outside the project; the relevant measurements are transcribed here for persistent review.

## 22. Required closing status

### CURRENT STATUS

Read-only source reconciliation performed; workbook row 3 verified; two documentation deliverables produced. The existing LF branch remains intact and reproducible. Current tests pass their old specification; registry migration and dynamic validation have not been performed.

### DATA ERRORS

Current Claude generator values omit the new primary dataset and conflate saturated/unqualified subtransient reactance. Capacity/PF-reference separation is missing. Grid attribution is incomplete. Rev2 misassigns GSUT solid grounding to the generator and substitutes different auxiliary/GSUT inputs. GSUT cooling is 28 kW, never 128 kW. Rf unit/field base and Ra/Ta conditions remain qualified, not silently invented.

### MODEL ERRORS

No LF engine defect was demonstrated by this audit. Confirmed legacy fault-model mismatch: missing generator neutral impedance through the solid-ground assumption. GAT balanced simplification cannot automatically define earth faults. Protection device/current-base semantics require correction. No validated sixth-order plant dynamic model was found.

### TEST ERRORS

The six historical grid failures were classified individually; the present suite is 447/0, not six failures. Remaining defects include stale reconstruction inputs in magnitude/magnetising probes, overbroad loss/export invariance and tests demanding newly supplied data remain missing. Corrections are designed, not implemented.

### REMAINING MISSING DATA

GAT ZPT/ZST; blank rotor-circuit/Ta(1) fields; exact controller/damping settings; complete saturation/base/test-condition definitions; actual capability/operating snapshots; current PGCB and zero-sequence data; detailed neutral/feeder/motor/relay information; cooling-load overlap; plant validation evidence.

### PROPOSED FILE CHANGES

Exact future changes and ownership are in §20 and [REV3_1_ACTION_PLAN.md](REV3_1_ACTION_PLAN.md). Only the two requested reports are changed at this stage. **STOP: no broad rewrite, no physical-model adjustment and no project-completion claim.**
