# v4 Simulink audit and correction record

Audit date: 2026-09-25. Scope: the supplied isolated v4 project compared with its parent `306 Power Project -kimi k3` project, plus the v4 addition claims. There is no Git history. Evidence consists of SHA-256 file comparison, SLX ZIP/XML comparison, source inspection and separately recorded MATLAB runs. Original repair targets are backed up under `Phase6/logs/audit_20260925/before/`.

## Supplied v4 changes before repair

| Area | Observed difference from parent project |
|---|---|
| `matlab/data`, `matlab/build`, existing `matlab/phase4` code | No file-content changes |
| `Phase6/scripts`, `Phase6/model`, existing Phase6 results/docs | No file-content changes |
| New Phase5 helpers | `phase5c_diff_87g.m`, `phase5c_diff_87t.m`, `phase5c_fault_enrichment.m`, `phase5d_q0_breaker_duty.m` |
| New Phase6 helpers | `build_dynamic_protection_sim.m`, `run_dynamic_trip_simulation.m` |
| New tests | `test_phase5c_differential.m`, `test_phase5c_enrichment.m`, `test_phase5d_q0_duty.m`, `test_phase6_dynamic_trip.m` |
| New model/note | `Phase6/PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx`, `Phase6/data/assumptions/HARDWARE_SELECTION_v4.md` |
| Top-level documentation | Added `MANUAL_CHANGES_v4.md` and two `PORTED_UNION_ALPHA` reports; changed `NOT_DETERMINABLE_REGISTER.md` |
| Existing documentation artifact | `docs/validation/rev31_phase2/generator_capability_curve.png` changed |

The added helpers were dated September 25 at about 02:02–02:16 local time; the added closed-loop copy was dated 02:18:50. The canonical dynamic model was dated September 24 at 18:09:19. Timestamps identify the supplied sequence; content comparison establishes equality. Imported Phase-4 reports are historical evidence, not proof that additional solver fixes were made in v4.

### SLX comparison

Inside the original v4 closed-loop copy, `simulink/modelWorkspace.mxarray`, `configSet0.xml` and every pre-existing system XML were byte-identical to the canonical dynamic model. Changes were limited to a new `system_464.xml`, its root block/reference, thumbnail, UI state and metadata.

The new top-level block `CL_TripRelayHook` (SID 464) had empty `PortCounts` and explicitly described itself as an unconnected placeholder.

| Child block | SID | Actual block type |
|---|---|---|
| `inv_top` | 465 | Constant |
| `SI_integrator` | 466 | Gain |
| `TRIP_out` | 467 | Terminator |

The only lines were 465 → 466 → 467. There was no measurement input, trip output, latch or connection to a breaker. The pre-existing model already had the measured `Measurements`, `Protection`, `DC Supply` and `Breaker Control` subsystems; the hook added no closed-loop functionality.

## Confirmed defects in supplied v4 claims

### 1. Synthesized traces were presented as dynamic trip validation

Original `matlab/phase6/run_dynamic_trip_simulation.m` lines 89–109 assigned sine-wave amplitude, set current to zero at an analytical operating time, and assigned 0.25/1.0 pu voltage. Lines 122–126 ran only a 0.02 s Simulink probe; the illustrative fault started at 0.50 s. No measured simulation output made the four plotted traces.

The 0.317045 s feeder, 1.187763 s backup and 0.040 s instant times were analytical examples. Claimed current truncation and recovery followed directly from assignments. The 22 kV input also belonged to a generator-terminal fault, while the feeder example assumed a separate 15 kA auxiliary fault; these did not establish primary/backup coordination for a common fault.

Original `test_phase6_dynamic_trip.m` lines 38–51 compared the same timing calculator and assigned trace values. Passing those assertions did not demonstrate a Simulink relay decision, breaker action or network recovery.

### 2. A temporary-output test overwrote the project model

The original test passed a temporary output directory but the real project root to `build_dynamic_protection_sim`. Original builder line 115 copied the canonical model over the project closed-loop target before adding the placeholder. Running the test could therefore overwrite edits to that model. Repair must build test models in a temporary location or preserve the existing target.

### 3. Standalone characteristics were not runtime settings

At audit start, `Phase6/scripts/phase6_relay_parameters.m` read frozen settings CSVs, required the generator high-set flag OFF, used generator 30% and transformer 30%/60% half-sum restraint, and recorded `harmonicBlockingImplemented = 0`, `ctSaturationImplemented = 0`, and `communicationDelay_s = 0`. The finite timing correction is described under “Current repaired behavior” below.

Added 87G 20%/50% / high-set 5 pu and 87T 25%/50% / high-set 8 pu functions were isolated calculators. They did not replace the relay S-function, add CT saturation or implement measured harmonic blocking. Their assigned scalar examples cannot validate external-fault CT stability. The 87G “≤20 ms” label has no time-domain calculation behind it.

Dynamic defaults at audit start were GEN-51 17170.8 A / TMS 0.10; GSUT-HV-51 1380 A / TMS 0.55; GEN-51N 4 A / TMS 0.15; 87G 2403.8 A / 0.045 s; 87T 387.84 A HV-side / 0.045 s; and 87B/87L 320 A / 0.035 s. These were study settings, not commissioned plant values.

### 4. Transformer bases and unsupported algorithm claims were mixed

`phase5c_diff_87t.m` lines 27–37 calculate 515 MVA / 22/230 kV and hypothetical 450 MVA / 22/400 kV values, but generic `M_LV`, `M_HV`, the plot basis and test points use the hypothetical case. The changes note placed hypothetical values beside the actual transformer description.

| Basis | LV current A | HV current A | Matching LV (15000/1) | Matching HV (1600/1) |
|---|---:|---:|---:|---:|
| Actual 515 MVA, 22/230 kV | 13515.244938 | 1292.762559 | 1.109858 | 1.237660 |
| Hypothetical 450 MVA, 22/400 kV | 11809.437324 | 649.519053 | 1.270170 | 2.463361 |

Actual 0.30 pu is 4054.573 A LV / 387.829 A HV; runtime CSV uses rounded 1292.8 A to obtain 387.84 A. The new scalar calculator does not implement phasor/vector compensation or zero-sequence filtering. Existing dynamic compensation is separate.

### 5. Fault-point totals were confused with physical duty

The old hardware note claimed “50 kA ... covers F3 ≈53 kA with thin margin”; 53/50 is 106%, so that comparison fails. It also used fault-point totals to infer CT saturation and generator-breaker requirements. CTs and breakers require actual-side through-currents and appropriate transient/duty checks. A 5P20 class alone does not prove transient stability or certain saturation at an unspecified connected burden.

The frozen branch-duty CSV reports Q0 6.897015 kA against a conditional 50 kA mapping and 52G 55.048710 kA against 100 kA. It disclaims breaking-time and making-duty verification. The new 400 kV envelope assumes a 63 kA candidate and 3.03 kA contribution. It is not the South 230 kV network and does not establish an actual PGCB maximum. Its arithmetic screen is retained with that scope.

### 6. Blanket completeness and zero-value statements were unsupported

At audit start, the selected model used `PHASE3_BASELINE` with `Rgrid = 0`; `PHASE5_STUDY` was a separate finite-R alternative. Zero communication delay was an explicit idealization, while zero Boolean flags represented disabled states. Canonical missing-data fields, excluded loads, CT excitation curves and unimplemented relay functions did not become known because a note assigned candidate values. The default profile and communication timing have since been corrected as recorded below.

The “faults ≥45 kA, static loads have no effect” statement was false: frozen F1 earth-fault current is approximately 7.27 A. Load assumptions require evaluation within each study and fault type. The “76 pass” count referred to standalone assertions and could not establish dynamic validation.

## Corrections in this audit

- Rewrote `MANUAL_CHANGES_v4.md` to preserve additions while separating standalone calculations from actual dynamic settings/results.
- Rewrote `NOT_DETERMINABLE_REGISTER.md` to distinguish study inputs from installed verification, excluded scope and ideal assumptions.
- Corrected the hardware note's 50/53 kA comparison, branch-current interpretation and unsupported CT certainty. Its original is in the audit backup directory.
- Corrected the standalone 87G B example to the frozen physical GEN branch 55048.7096805279 A, retained the explicit assumed 5% mismatch, made plot limits cover every example, and removed the unsupported operating-time label. Source provenance and plot-limit fields are returned.
- Added explicit actual `M_LV_515` / `M_HV_230` and hypothetical `M_LV_450` / `M_HV_400` fields to the 87T calculator. Existing generic fields retain their hypothetical basis for compatibility; `characteristic_basis` labels it. Its assigned B point is no longer described as a derived F3 physical through-current.
- Updated `test_phase5c_differential.m` to check physical-branch CSV provenance, marker visibility, actual-basis normalization and compatibility aliases. Removed the old unsupported minimum-fault assertions mixing fault totals/voltage sides. A static source check first reproduced the 126214.14 versus 55048.7096805279 A mismatch, then passed after repair; MATLAB execution remains a separate gate below.
- Replaced the placeholder build/run workflow with the existing measured dynamic model. The wrapper backs up an existing working SLX before an explicit rebuild; result paths are confined to this installation's `Phase6/results`. Final measured-run evidence is recorded separately below.

## Current repaired behavior

- `Phase6/START_PHASE6.m` opens the canonical closed-loop model in this v4 project and the editable control panel. `build_dynamic_protection_sim` generates the connected electrical model, and `run_dynamic_trip_simulation` exports an actual completed `Simulink.SimulationOutput` with its settings and measured tables. The runner retains active relay edits and resets scenario fields from the declared defaults before applying supplied overrides.
- The default network is `PHASE5_STUDY`, with R1/R2 = **0.267343748 Ω**, X1/X2 = **2.938107792 Ω**, finite line/GSUT values, and declared zero-sequence assumptions. `PHASE3_BASELINE` remains available as a historical comparator.
- Machine viscous-loss coefficient **F = 0.001 pu** gives **458 kW at rated speed on the 458 MVA base**; SPS loss varies with speed squared. This is an engineering choice, not a measured damping value.
- 87L adds a **0.005 s** communication/processing allowance to its **0.035 s** local delay, giving **0.040 s** effective time above threshold. It uses synchronized end phasors and does not model sample transport or channel faults. Other relay pickups and curves above remain unchanged.
- Inapplicable relay fields are blank in the GUI and labeled `not applicable` in the build-parameter CSV. Event timestamps remain absent where the event did not occur; their Status describes the observation.
- The model presents one **Controls** launcher (stored at the existing `/Scenario` block path), shorter subsystem captions, and the panel's existing settings tabs. Redundant portless fault/protection launch buttons were removed.
- Figure PNGs/PDFs use **220 dpi raster export**. The complete [HTML manual](SIMULINK_USER_MANUAL.html) documents components, new differential calculators, fault reruns with changed protection, units and the export contract. Earlier manual entry pages link to it.

## Runtime verification

**PASS — 25 September 2026**, MATLAB 24.1.0.2537033 (R2024a), default `PHASE5_STUDY`. The final [JSON record](../logs/audit_20260925/realistic_verification.json), [initial test log](../logs/audit_20260925/realistic_verification.log) and [completion log](../logs/audit_20260925/realistic_resume.log) identify the evidence.

- **31 standalone differential assertions and 22 dynamic integration assertions passed**, plus input/evidence validation and GUI-panel refresh checks. The integration suite exercised normal operation, measured bus-fault relay/DC/breaker response, sustained branch-current cessation, and protection-disabled behavior.
- The bus-fault repeat changed only the 87B local delay from 0.035 to 0.100 s. The request moved **0.187 → 0.252 s** and Q0/local-line commands moved **0.237 → 0.302 s**. All six breaker-branch phase currents met sustained cessation by **0.2462 / 0.3102 s**, respectively. Saved outputs: `Phase6/results/manual_bus_default` and `manual_bus_delay_100ms`.
- Additional actual 3PH runs recorded **GEN/87G 0.197 s**, **GSUT_HV/87T 0.197 s**, and **LINE230/87L 0.192 s** in `v4_gen_3ph`, `v4_gsut_hv_3ph`, and `v4_line230_3ph`.
- The final **2.000 s normal run** had finite summary data and no relay trips. Means over 1.900–2.000 s were **359.289064 MW**, **22.000310 kV**, and **49.999932 Hz**. The model retains the 360 MW dispatch setting; the measured finite-loss result is reported without substituting that setting. Saved output: `Phase6/results/v4_normal`.
- The initial harness interrupted while adding the first zone record to an untyped empty structure, after the GEN export had completed. `resume_realistic_v4.m` corrected the record initialization, reused completed evidence and ran the remaining cases. The original harness error is preserved separately; it was not an electrical-model failure.
- Final layout application compiled and saved the model, rendered 13 systems, and found **zero block-body overlaps**. Duplicate signal-block captions are hidden; functional tags remain visible. Evidence: `Phase6/logs/audit_20260925/layout_status.json` and the `layout` folder. Earlier-phase cleanup changed 161 captions in 11 models; all content outside annotation text is identical to the backups.

Historical September 23–24 results retain their original scope and dates. Current verification establishes the named study runs and implemented functions; it does not establish installed-equipment ratings, commissioning settings, CT transient behavior, or complete internal-generator fault extinction.
