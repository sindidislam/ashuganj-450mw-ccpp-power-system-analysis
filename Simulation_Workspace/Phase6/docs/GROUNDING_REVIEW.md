# Phase 6 grounding design review

Review date: 2026-09-22. Scope: read-only electrical design audit and installed R2024a library inspection. No MATLAB session was started, no model was compiled or simulated, and no production code was changed by this review. Numerical checks below are independent arithmetic, not simulated acceptance results.

## Recommendation

The proposed unloaded 22 kV Yn/delta transformer, connected at the generator terminals with an external neutral resistor, can reconstruct the **terminal zero-sequence equivalent** missing from the three-terminal SPS Synchronous Machine pu Standard block. It is defensible for fundamental-frequency terminal ground faults and neutral overcurrent, subject to the acceptance checks below. It must be labelled **generator zero-sequence/neutral equivalent**, not an installed grounding transformer. It does not create a physical machine neutral inside the synchronous-machine block or model an internal stator winding fault location.

The installed SPS **Grounding Transformer** zigzag block is preferable because its mask directly accepts the intended zero-sequence R/X and exposes N. This avoids the extra leakage allocation and unloaded-delta configuration of the proposed two-winding equivalent. Both are passive sequence equivalents; neither represents the actual 12.7017 kV/500 V, 135 kVA/20 s neutral grounding transformer.

Keep the equivalent electrically on the machine side of the generator terminal CT and generator breaker. Connect its N through an actual Current Measurement block and a single physical neutral resistor to ground. The generator terminal measurement must include the combined machine-plus-equivalent port. The SM measurement-bus currents alone have zero residual and are unsuitable as the generator ground-fault measurement.

## Electrical basis and exact mapping

At the combined port, the synchronous machine supplies positive/negative sequence behavior while the passive shunt supplies

`Z0,total = Z0,machine + 3*Rn`.

The factor of three arises because `IN = Ia+Ib+Ic = 3*I0` flows through the one common neutral resistor. **Enter Rn, not 3Rn, in the physical neutral resistor.** A direct sequence-network impedance uses 3Rn; an actual neutral branch uses Rn. A three-phase shunt with three separate phase-to-ground resistors is a different circuit and is not an acceptable substitute.

| Quantity | Value and basis |
|---|---|
| Machine base | 458 MVA, 22 kV line-to-line, 50 Hz |
| Zbase | 22²/458 = 1.056768558951965 ohm |
| Phase voltage | 22000/sqrt(3) = 12701.7059221718 V RMS |
| Actual NGT voltage ratio | (22000/sqrt(3))/500 = 25.4034118443435 |
| Reflected loading resistance | ratio² × 2.62 = 1690.77333333333 ohm |
| Physical neutral equivalent Rn | 60 + 1690.77333333333 = 1750.77333333333 ohm |
| Sequence contribution 3Rn | 5252.32 ohm = 4970.1705785124 pu on machine base |
| Frozen Phase 5 machine R0 | 0.00126328512396694 pu = 0.001335 ohm |
| Machine X0 | 0.128 pu = 0.135266375545852 ohm |
| Equivalent machine L0 | X0/(2*pi*50) = 0.000430566246044939 H |

The 60 ohm source entry is qualified HV winding DC resistance, not the complete neutral resistance. The 2.62 ohm loading-resistor entry is also qualified. Their sum after reflection is a derived study interpretation, not a measured effective neutral impedance. Phase 4 used Ra=0.00089 ohm as machine zero-sequence resistance; Phase 5 records R0=1.5Ra as a new engineering assumption. This tiny change is not material to a 1750.77 ohm neutral but its provenance must remain visible.

### Preferred installed zigzag block

Read-only inspection of the installed SLX XML confirmed:

- Library: `C:/Program Files/MATLAB/R2024a/toolbox/physmod/powersys/library/powergridelements/spsGroundingTransformerLib.slx`.
- Block path: `spsGroundingTransformerLib/Grounding\nTransformer `, where `\n` denotes a literal line feed and the block name has a trailing space. Find by mask type `Grounding Transformer` if constructing paths programmatically.
- Description: three two-winding transformers connected in zigzag; winding resistances/reactances adjusted to obtain the specified zero-sequence impedance. Ports A, B, C, N are present in `simulink/systems/system_1.xml`.

Use these exact supported mask fields:

| Field | Value |
|---|---|
| UNITS | `pu` |
| NominalPower | `[458e6 50]` |
| NominalVoltage | `22000` |
| ZeroSequenceImpedance_pu | `[0.00126328512396694 0.128]` |
| MagnetizationBranch_pu | `[1e7 1e7]` as a declared numerical approximation |
| Measurements | `None` if separate terminal/neutral sensors are used |

NominalPower here is a convenient normalization base, not a claimed hardware rating. Do not put 3Rn into ZeroSequenceImpedance_pu when an external neutral resistor is present. The SI alternative fields are `ZeroSequenceImpedance_SI=[Ro(ohm) Xo(ohm)]` and `MagnetizationBranch_SI=[Rm(ohm) Xm(ohm)]`: their second entries are **reactances**, not henries.

The `1e7` magnetizing values are an implementation assumption requiring numerical conditioning and no-load checks. A transformer with Rm=Xm=500 pu can introduce tens of amperes of balanced exciting current on a 458 MVA base; it is not negligible relative to a 7 A ground fault. At 1e7 pu the simple machine-base estimate is 1.202 mA per resistive/reactive magnetizing component per phase. Confirm the actual zigzag input current rather than relying on this estimate as an exact block-specific current.

### Proposed Yn/delta alternative

The installed `spsThreePhaseTransformerTwoWindingsLib.slx` mask explicitly supports `Winding1Connection='Yn'`, `Winding2Connection='Delta (D1)'` or `'Delta (D11)'`, `CoreType='Three single-phase transformers'`, and an accessible Yn neutral. Use saturation off. The external delta terminals are unloaded; the delta itself remains internally closed. Do not short the three external delta terminals together.

On `[458e6 50]`, with both nominal winding line voltages 22000 V, an equal leakage allocation is:

`Winding1 = [22000 0.00063164256198347 0.064]`

`Winding2 = [22000 0.00063164256198347 0.064]`

and `Rm=Lm=1e7` pu. The two winding leakages sum to the target machine R0+jX0 referred to the 22 kV side when the delta provides its zero-sequence circulating path. The magnetizing branch makes the correspondence approximate; verify it by a sequence impedance measurement. In the transformer pu mask the L entries equal reactance pu at the nominal frequency; do not enter the SI henry value there. Use Yn rather than Yg, because Yg would bypass the external resistor with a solid ground. Different core models can add a core-return zero-sequence path and should not be selected casually.

### Mutual-impedance alternative

Installed library `spsThreePhaseMutualInductanceZ1Z0Lib.slx`, block `Three-Phase\nMutual Inductance\nZ1-Z0`, has six terminals and supported masks `PositiveSequence=[R1(ohm) L1(H)]`, `ZeroSequence=[R0(ohm) L0(H)]`. A shunt version can join a/b/c to a neutral and use very high positive/negative-sequence impedance, target machine Z0, and the external Rn. It approximates an open positive-sequence port and may be ill-conditioned because high sequence impedance is synthesized through mutual terms. The purpose-built zigzag is clearer. The same mutual block is particularly useful for a finite grid impedance because its Z1/Z0 inputs directly express that network without extreme impedance ratios.

## CT placement, protection meaning, and limits

The combined machine port must be inside the measurement boundary used for generator terminal currents. With the equivalent branch outside that CT, the terminal residual would miss the grounding return and ground-fault or differential interpretation would be wrong. Determine sensor polarities by KCL using signed instantaneous currents or complex phasors; do not sum current magnitudes. For outward machine current and a neutral current defined outward to earth, `Ia+Ib+Ic+IN=0` for the complete equivalent boundary without other earth branches. RMS magnitudes should therefore agree: `abs(Ia+Ib+Ic)=abs(IN)`.

If both generator differential CT sets are simulated, the three-terminal SM does not independently provide physical neutral-end stator conductor currents with zero sequence. Terminal equivalents cannot demonstrate an internal winding location, winding-to-earth capacitance, interturn fault, neutral-end coverage, or actual 87G response to a distributed internal fault. Any reconstructed neutral-end conductor measurement or inserted internal-fault surrogate requires its own stated model and KCL validation. A terminal fault inside a drawn protection zone is not automatically an internal winding model.

GEN-51N uses the physical neutral current with the frozen study CT ratio 20/1, pickup 0.20 A secondary = 4 A primary, and IEC Standard Inverse TMS 0.15. The 20/1 CT and relay settings are engineering study assumptions. A 7.2549 A steady current corresponds to 0.36275 A secondary and approximately 1.7531 s inverse-time operation; a 0.15 s fault should not complete that inverse timer from reset. The frozen F1 LG row is 7.27200442799 A OUT and 7.27012833909 A IN; the nominal isolated approximation is 7.25491168979 A. The small difference is not explained by a higher frozen B22 voltage: the frozen B22 voltage is exactly 1 pu. It reflects the full frozen network calculation and its assumptions.

These are **fundamental-frequency 51N** results. An actual 64G 20 Hz scheme requires an injected source, coupling network, 20 Hz voltage/current estimation, resistance inference, and associated supervision. Merely storing the Phase 5 64G settings or feeding a 50 Hz neutral RMS current does not implement 64G or prove 100% stator-earth-fault coverage.

## Phase 3 / Phase 4 / Phase 5 source separation

The Phase 6 parameter brief explicitly retains the canonical Phase 3 positive-sequence load-flow network and forbids replacing ZGRID with the Phase 5 screening alternative. Preserve that contract. The following are different named profiles, not interchangeable sources:

| Profile | Grid / line treatment |
|---|---|
| Phase 3 balanced baseline | 50 kA estimated grid magnitude, abs(Zgrid)=2.65581123827 ohm; R=0 is a balanced-load-flow-only assumption. South two-circuit lumped line Z1=0.0277725+j0.1425655 ohm, B1=3.937996 uS. Line zero-sequence data remain missing. |
| Phase 4 fault backbone | Same primary 50 kA magnitude split with X/R=15 base (10–20 band); secondary 45.01 kA/XR10.99 kept separate. Grid Z0/Z1 scaling 1/1.5/2, central 1.5. South zero-sequence uses declared bands kR=2–5, kX=2–3.5, kB=0.60–0.85 applied to frozen Phase 3 line. |
| Phase 5 numerical screening/reference | Grid 45.01 kA, X/R10.99, Z1=0.26734374814821+j2.93810779214883 ohm; Z2=Z1; Z0=3Z1 central, ratios 2/3/4 sensitivity. South two distinct 0.7 km circuits use new assumed electrical data below. |

Phase 3 explicitly says its Rgrid=0/XR=Inf must not carry unqualified into fault/DC-offset claims. A dynamic fault profile therefore needs a documented finite-R decision or an explicit limitation; changing it must not silently change the balanced baseline or claim exact Phase 3 identity. Likewise, deriving Z0=3 times the retained Phase 3 Z1 is a **new Phase 6 assumption inspired by Phase 5**, not the exact Phase 5 grid equivalent. Phase 4's central ratio 1.5 is the closer named continuation of its frozen fault backbone. Choose and label the applied profile.

For an explicitly selected Phase 5 grid screening case, either use an ideal grounded source plus the mutual Z1/Z0 element, or use a source with phase Z1 and `InternalConnection='Yn'` plus neutral `Zn=(Z0-Z1)/3`. The latter gives physical neutral R=0.17822916543214 ohm and L=0.00623485837943067 H. A plain Yg source with equal uncoupled phase RL gives Z0=Z1 and does not implement Z0=3Z1. Do not add both a full mutual Z0 and this additional neutral impedance.

For the Phase 5 South-line screening profile, **per circuit** at 0.7 km:

- Z1=0.056+j0.245 ohm; total B1=2.94 uS.
- Z0=0.175+j0.84 ohm; total B0=1.96 uS.
- Per-km SPS values: R1=0.08, R0=0.25 ohm/km; L1=0.00111408460164327 and L0=0.00381971863420549 H/km; C1=1.33690152197192e-8 and C0=8.91267681314614e-9 F/km.
- Two independent parallel circuits give series Z1=0.028+j0.1225, Z0=0.0875+j0.42 ohm, and total B1=5.88, B0=3.92 uS. Do not halve each circuit before paralleling it. Mutual coupling between the circuits is unavailable and its omission must remain an assumption.

The frozen Phase 5 fault-current CSV and coordination backbone were **not regenerated using all Phase 5 reference-profile changes**. PHASE5_AI_HANDOFF.md states that they retain locked Phase 4 currents; updated grid/GSUT/motor alternatives are separate analytical screening. Therefore agreement with 7.272 A is a plausibility check, not evidence that the rebuilt model matches every Phase 5 input. Preserve the GSUT YNd1 delta barrier: HV ground current has no conducting zero-sequence path through the 22 kV delta. UAT/GAT LV neutral resistances are separate 5 A equivalents, 796.743371 ohm physical on the 6.9 kV winding basis, not solid grounds and not the generator NER.

## Acceptance checks that distinguish a correct equivalent

1. **Balanced behavior:** equivalent on/off comparison at the same operating point. Confirm negligible changes to P/Q, phase current, rotor speed, field voltage, and load-flow mismatch; neutral RMS approximately zero. Record actual exciting current and chosen tolerance. Large balanced currents indicate default magnetization values or an unintended secondary load.
2. **Sequence impedance:** in an isolated component fixture, apply equal phase-to-earth sinusoidal voltages and calculate `(Va+Vb+Vc)/3 / ((Ia+Ib+Ic)/3)`. It must equal machine Z0+3Rn. Also measure the winding-side phase-to-neutral drop/current to resolve the small machine Z0; the 1750 ohm resistor can otherwise conceal a large leakage error. Test positive/negative sequence and confirm the equivalent behaves as a high-impedance shunt. Separate pure-sequence fixtures avoid confusing source impedance with the component under test.
3. **Terminal LG, relay disabled:** settle a 22 kV isolated generator with no other earth paths, apply a bolted terminal A-earth fault, and measure the fundamental component after numerical switching transients. Expect about 7.2549 A neutral/fault current at 1 pu and I0≈2.4183 A, with healthy phase-to-earth voltages approaching 22 kV while line-to-line voltages remain approximately normal. In the full network compare voltage-normalized neutral current and document charging-current contributions rather than demanding exact 7.272 A agreement.
4. **Factor-of-three and ground-path checks:** three times the physical Rn gives about 2.4183 A; one-third gives 21.7647 A; 60 ohm alone gives 211.695 A. Opening the NER should remove resistive LG current, leaving only explicitly modelled capacitance/numerical leakage. A large remaining current reveals another earth path. Check loads, source configuration, transformer neutrals, grounded measurement internals, and snubbers.
5. **KCL and CT boundary:** verify signed `Ia+Ib+Ic` against the measured neutral current at the combined generator port. Confirm each equivalent phase contributes equal I0 under a pure zero-sequence drive. Repeat with generator breaker open: the generator-side grounding equivalent must remain with the generator, and must not remain as a phantom bus ground on the other side.
6. **Fault selectivity:** balanced 3PH and LL should produce negligible generator neutral current in the symmetric model. LLG can have large phase current and only modest neutral current; it must not be treated as three times a phase-current magnitude. Test GSUT HV LG and confirm LV residual is zero through the delta (ignoring explicit capacitance), even though positive/negative sequence phase currents can cross it.
7. **Protection timing and trip action:** at approximately 7.25 A demonstrate the GEN51N inverse timer from the physical NER measurement, reset below pickup, and trip after the computed accumulated operating duty. For a fault on the generator side, opening GCB alone does not stop a still-excited rotating generator feeding the fault; model de-excitation/prime-mover response and observe decay. Battery-loss logic must affect trip execution through its actual control path, without changing or synthesizing measured fault current.

## Evidence inspected

- `matlab/phase4/phase4_grounding.m`, `phase4_seqZ.m`, `phase4_seqPN.m`, `phase4_sources.m`, `phase4_prefault.m`, `phase4_registry.m`, and `matlab/tests/test_phase4_grounding.m`.
- `matlab/phase5/phase5b_parameters.m`, `phase5b_physical_currents.m`; `Phase6/data/phase5_reference/phase5_parameter_values.csv`, `phase5_fault_inputs.csv`, `phase5_relay_currents.csv`, and `phase3_bus_results.csv`.
- `matlab/data/ashuganj_lines.m`; `PHASE3_FINAL_REPORT.md` (especially balanced-only grid resistance and missing zero data); `PHASE5_AI_HANDOFF.md` (separate profile/backbone distinction); `Phase6/docs/PARAMETER_TASK_BRIEF.md`.
- `Phase6/logs/jobs/job001_probe.m.log` confirms R2024a and three SM electrical terminals. `job003_machine_options.m.log` exposes round-rotor options but ends with a missing-powergui initialization error: it is not evidence of successful model compilation.
- Installed SLX XML for Grounding Transformer, Three-Phase Transformer (Two Windings), Three-Phase Mutual Inductance Z1-Z0, and Three-Phase Source. Their implementation callbacks are primarily protected `.p` files; this review confirms available masks/topology, not undocumented internals or runtime success.

