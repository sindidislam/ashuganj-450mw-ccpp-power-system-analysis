# v4 changes and September 25 audit corrections

This work is in the isolated `306 Power Project -kimi k3-v4` project. The audit compares it with its parent project using file hashes and SLX archive XML. Detailed findings and runtime verification are in [Phase6/docs/V4_SIMULINK_AUDIT.md](Phase6/docs/V4_SIMULINK_AUDIT.md).

## What the supplied v4 copy added

- Two imported historical Phase-4 reports: `PHASE4_REVIEW_GATE_PORTED_UNION_ALPHA_2026-09-24.md` and `PHASE4_CORRECTION_PORTED_UNION_ALPHA.md`. Copying these reports introduced no new solver changes: existing Phase-4 code matched the parent at audit start.
- Standalone 87G/87T characteristic calculators, fault-result enrichment, a hypothetical 400 kV duty-envelope calculator, four test files and generated study outputs.
- `Phase6/data/assumptions/HARDWARE_SELECTION_v4.md`, a candidate hardware note, not an installed-equipment schedule or runtime CT-saturation model.
- `Phase6/PHASE6_ASHUGANJ_CCPP_CLOSED_LOOP_TRIP.slx`, originally the existing dynamic model plus one unconnected placeholder. Its network, controller, relay, model workspace and solver configuration were unchanged. The inherited model already contained measured protection/DC/breaker control.

The earlier claim that all frozen artifacts were unchanged was too broad: `docs/validation/rev31_phase2/generator_capability_curve.png` differed from the parent. No existing `matlab/data`, `matlab/build`, `Phase6/scripts` or canonical `Phase6/model` file differed at audit start.

## Actual dynamic-model settings

The model reads `Phase6/data/phase5_reference/phase5_relay_settings.csv` and `phase5_parameter_values.csv` through `Phase6/scripts/phase6_relay_parameters.m`.

| Function | Runtime study setting |
|---|---|
| GEN-51 | 17170.8 A primary, IEC SI, TMS 0.10, CT 15000/1 |
| GSUT-HV-51 | 1380 A primary, IEC SI, TMS 0.55, CT 1600/1 |
| GEN-51N | 4 A primary, IEC SI, TMS 0.15, assumed dedicated CT 20/1 |
| 87G | 2403.8 A pickup, 30% half-sum restraint, 0.045 s operation proxy |
| 87T | 387.84 A on the 230 kV side, 30%/60% half-sum restraint, knee 2 × 1292.8 A, 0.045 s operation proxy |
| 87B | 320 A pickup, 30% half-sum restraint, 0.035 s local delay |
| 87L | 320 A pickup, 30% half-sum restraint, 0.035 s local delay + 0.005 s communication/processing allowance = 0.040 s effective delay |

High-set stages are disabled. CT saturation and harmonic blocking are not implemented. The line element now includes a finite 5 ms timing allowance; both ends still use synchronized phasors, so this is not a channel-transport simulation. Standalone values below do not change runtime settings. Relay request time, breaker open-command time and measured current cessation are different quantities.

## Standalone study additions

- `phase5c_diff_87g.m` draws a 0.20 pu, 20%/50%, high-set 5 pu characteristic on a 458 MVA / 22 kV basis. Its A/B/C cases are static scalar examples. The repaired B case uses the frozen F1 LLL physical GEN branch **55048.709681 A** with an assumed 5% mismatch, replacing the inappropriate 126 kA fault-point total. Plot limits keep all markers visible. The unsupported “≤20 ms” label was removed; this function does not calculate operating time or CT transient stability.
- `phase5c_diff_87t.m` computes both actual 515 MVA / 22/230 kV and hypothetical 450 MVA / 22/400 kV ratings. Existing `M_LV`/`M_HV`, the plot and scalar examples retain the hypothetical basis. Added `M_LV_515`/`M_HV_230` expose the actual factors **1.109858 / 1.237660**, while `M_LV_450`/`M_HV_400` explicitly name the legacy hypothetical factors. Actual rated currents are **13515.245 A LV / 1292.763 A HV**. The earlier 11809 A / 649.5 A and 1.2702 / 2.4633 values belong to the hypothetical case. The calculator does not implement measured YNd1 compensation or zero-sequence filtering.
- `phase5c_fault_enrichment.m` adds arithmetic and selected views of the frozen fault backbone. F1 LLL 126.21 kA and F3 LLL 50.53 kA are fault-point totals. Duty and relay comparisons require the relevant physical branch and voltage side. F1 LG is approximately **7.27 A**, so “faults ≥45 kA; static loads have no effect” was false.
- `phase5d_q0_breaker_duty.m` produces a **hypothetical 400 kV** 63 kA envelope with assumed 3.03 kA plant contribution. A 50 kA grid gives 53.03 kA total and 84.175% of 63 kA. This is not South's actual 230 kV Q0 branch and does not establish a verified current PGCB maximum or making capability.
- Existing `phase5_breaker_duty.csv` is the separate conditional branch screen: Q0 maximum 6.897015 kA / candidate 50 kA, and 52G maximum 55.048710 kA / 100 kA. It does not verify breaking-time current, TRV, contact time or DC asymmetry.

## Correction of the earlier dynamic-trip claim

In the supplied v4 runner, the 0.317045 s feeder, 1.187763 s generator-backup and 0.040 s instantaneous times were **analytical examples**. Current was set to zero at the calculated time; voltage was assigned 0.25 pu during the fault and 1 pu afterward. Simulink ran only a 0.02 s probe, before the illustrative 0.50 s fault. These outputs did not establish electrical fault clearing or measured voltage recovery.

The original `CL_TripRelayHook` contained `Constant -> Gain -> Terminator`, with no external ports. Its `SI_integrator` was a Gain. The existing measured model is the basis of the resumed workflow. Repaired entry points and measured verification are recorded in the audit report; the former synthetic plot must not be cited as runtime evidence.

For interactive operation, run `Phase6/START_PHASE6.m` from this project and follow the [complete HTML manual](Phase6/docs/SIMULINK_USER_MANUAL.html). It covers each electrical/control component, all seven implemented relay elements, both standalone differential calculators, GUI fault reruns with changed settings, API examples, and the full export-column reference. The earlier manuals link to this current guide. Standalone calculator tests are separate from measured Simulink validation.

## Current numerical defaults and presentation

- New/reset v4 cases use `PHASE5_STUDY`: finite grid R1/R2 **0.267343748 Ω** and X1/X2 **2.938107792 Ω**, with explicitly assumed R0/X0 equal to three times those values. The central grid case is linked to the secondary 45.01 kA, X/R 10.99 record in the master-data PDF; it is not a newly measured PGCB equivalent.
- The synchronous-machine viscous-loss coefficient is **F = 0.001 pu**. Under the SPS F×speed convention, power loss is F×speed² pu: **458 kW at rated speed on the 458 MVA machine base**. It is a finite engineering assumption, not measured damping.
- Breaker mechanisms retain the finite **0.050 s** assumption. Fault and ground resistances default to **0.01 Ω** each. The manual lists the selected line, transformer, neutral and DC representation values with their bases.
- Unused GUI relay-setting cells are blank; the generated build-parameter CSV uses `not applicable`. An unobserved result event retains a status and no invented timestamp; this is distinct from a missing active parameter.
- The top-level model uses one **Controls** launcher for the study panel, with short subsystem labels and no redundant fault/protection launch buttons. Panel tabs retain the detailed settings.
- Figure PDFs and PNGs use **220 dpi raster export**, avoiding the earlier warning about dense vector rendering. Numerical CSV/MAT data remain the primary record.

## Numerical scope and remaining verification

The selected study has numerical inputs for its included network and implemented relay/DC functions. This does not mean every parameter is measured or every installed protection function is implemented. `PHASE3_BASELINE` retains `Rgrid = 0` only for explicitly selected historical comparisons; `PHASE5_STUDY` is the default. Zero-valued Boolean flags identify disabled states. The original blanket claim “nothing left as ideal 0” was inaccurate; numerical and physical assumptions remain identified by function.

The original “76 pass” count described added standalone assertions, not closed-loop fault clearing. The September 25 final record reports **31 standalone differential and 22 measured dynamic integration assertions passed**, plus input/evidence and panel-refresh checks. The actual 87B delay repeat shifted its request from **0.187 to 0.252 s**. Generator, transformer and line differential fault runs operated, and the final 2 s normal run had no relay trips. Exact values and saved paths are in the linked audit and HTML manual. See [NOT_DETERMINABLE_REGISTER.md](NOT_DETERMINABLE_REGISTER.md) for installed-document and modelling limits.
