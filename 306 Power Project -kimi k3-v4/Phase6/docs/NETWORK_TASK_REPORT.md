# Network build and short-run verification

Completed 2026-09-22. Production changes are confined to `scripts/phase6_add_network.m` and `scripts/phase6_electrical_profile.m`. The main builder, controls, canonical source data and raw parameter provider were not edited.

## Corrected causes

1. The auxiliary builder iterated every canonical load record, including `LOAD_B0_4`. That record explicitly has `Model_included=false`, NaN P/Q, and an exclusion explaining that its unknown 400 V demand is already inside the 14 MW represented at 6.6 kV. The profile now filters on canonical inclusion, validates finite included P/Q and the supported 6.6 kV bus boundary, and preserves excluded records in metadata. Three loads remain, totaling exactly 14 MW and 8.67642073764 MVAr. No SAT parameters, separate LV demand, or LV voltage result were invented.
2. Discrete SPS rejected open ideal fault-switch current sources in series with transformer inductances. Fault blocks now have explicit pure-resistive numerical snubbers: `SnubberResistance=1e9` ohm and `SnubberCapacitance=Inf`. This is not an insulation measurement or plant load. At 230 kV nominal, a fully grounded three-phase bank would draw 52.9 W and 0.133 mA per phase. The value and rationale are exposed in the electrical profile.
3. A simulation-return-only check initially passed at 0.05 s, but actual measurements over 0.2 s revealed catastrophic instability with the inherited synchronous-machine `Trapezoidal non iterative` method. The supported `IterativeDiscreteModel='Trapezoidal robust'` method eliminated the instability with all physical machine parameters unchanged. The network builder now sets that option explicitly from the profile.

## Returned interface

Existing `net` fields and placeholder mechanical-power/field-voltage block paths are unchanged. `net.profile` now additionally contains:

- `loads`: selected canonical load records.
- `excludedLoads`: the unchanged excluded 400 V record, including its NaN demand and exclusion reason.
- `auxLoadConfiguration='Y (floating)'` and `auxLoadNote`: the existing three-wire auxiliary load implementation is explicitly identified as a Phase 6 zero-sequence assumption; it preserves the balanced P/Q model.
- `faultSnubber_ohm=1e9` and `faultSnubberNote`.
- `machineDiscreteSolver='Trapezoidal robust'` and `machineDiscreteSolverNote`.

These numerical selections should accompany final scenario/register metadata. Raw `P.loads`, `P.transformers`, `P.generator`, and the Phase 3 versus Phase 5 profile separation remain unchanged.

## Required caller configuration

The verified configuration uses powergui `SimulationMode='Discrete'`, `SampleTime='50e-6'`, frequency 50 Hz, and load-flow tolerance `ErrMax='1e-7'`. The model uses `SolverType='Fixed-step'`, `Solver='FixedStepDiscrete'`, `FixedStep='50e-6'`. The builder supplies `S.dispatch_MW=360` for the primary operating point.

After `LF=power_loadflow(mdl,'solve')` returns `LF.status==1`, initialize the machine's mechanical input with `LF.sm.Pmec/LF.sm.Pnom` and its field input with `LF.sm.Vf`. The load-flow solver sets the machine's electrical initial conditions. When replacing the placeholder mechanical/field Constant blocks with controls, delete the actual lines connected to the machine input ports as well as the source blocks: source deletion can leave a dangling line occupying a destination input.

## Measured verification

The existing shared R2024a worker executed uniquely named `jobN_network*.m` scripts. No separate MATLAB process or UI automation was used. Functions were cleared and rehashed before fresh reruns.

Final evidence: `logs/jobs/jobN_network06_fresh_profiles.m.done` reports `success=true`, finished 22-Sep-2026 08:59:50. This job rebuilt both profiles from the modified source files, solved load flow, compiled in discrete mode, simulated 0.2 s, and checked actual VI/neutral/machine measurements.

| Measured quantity | PHASE3_BASELINE | PHASE5_STUDY |
|---|---:|---:|
| Load-flow status | 1 (converged) | 1 (converged) |
| Load-flow generator Q | 27.6166455 MVAr | 24.8200871 MVAr |
| Generator mean active power, final 40 ms | 359.953703 MW | 359.954246 MW |
| Generator phase RMS voltages | 12701.7047, 12701.7062, 12701.7055 V | 12701.7106, 12701.7097, 12701.7102 V |
| Neutral current RMS, final 40 ms | 5.93699e-11 A | 4.73602e-11 A |
| Maximum speed departure over run | 9.91051e-9 pu | 6.39166e-8 pu |
| Auxiliary mean active power, final 40 ms | 14.0008036 MW | 13.999631 MW |

The checks require finite measurements, phase voltage between 12000 and 13400 V, generator active power between 350 and 370 MW, speed deviation below 1%, neutral RMS below 0.05 A, and auxiliary power between 13 and 15 MW. These are short normal-run acceptance checks, not full fault, controller, long-term stability or parameter-accuracy validation. Mechanical and field inputs are held at the load-flow operating point in this fixture. The slight active-power differences from 360 MW are reported, not hidden by rescaling.

Saved evidence:

- `logs/network_PHASE3_BASELINE_normal.mat`
- `logs/network_PHASE5_STUDY_normal.mat`
- `logs/jobs/jobN_network06_fresh_profiles.m.log`

Earlier diagnostic records preserve the causal sequence: `job015_network` demonstrates the NaN load failure; `jobN_network01_load_selection` demonstrates corrected load selection and the next discrete topology error; `jobN_network02_fault_snubber` demonstrates the 0.05 s compile/sim pass; `jobN_network03_normal_measurements` and `jobN_network04_diagnose_normal` reveal why that pass alone was insufficient; `jobN_network05_trapezoidal_robust` demonstrates the solver-only fix before persistence and fresh-profile verification.

The separate integrated-builder error observed in `jobR_integrated03` concerns replacement of occupied machine control input ports. It is outside the network changes above and is not counted as a successful integrated-model test.
