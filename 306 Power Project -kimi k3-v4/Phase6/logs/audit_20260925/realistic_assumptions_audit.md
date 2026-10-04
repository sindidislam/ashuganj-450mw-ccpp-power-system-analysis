# Finite physical assumptions audit — 2026-09-25

Scope: read-only review of active Phase6 parameters, source ledgers, the four-page master PDF, and installed R2024a SPS library XML. No MATLAB execution or model changes were performed by this audit. Root task is implementing the accepted defaults.

## Accepted changes

1. Use PHASE5_STUDY as the normal active profile. Keep PHASE3_BASELINE as historical comparison rather than the running default.
2. Use machine viscous-friction factor F = 0.001 pu as an ENGINEERING_ASSUMPTION. At rated speed this corresponds to 0.001 × 458 MW = 458 kW mechanical loss.
3. Use an explicit 5 ms line protection communication/processing allowance added to the 35 ms local 87L detection time. Effective 87L delay becomes 40 ms. Keep synchronized, time-aligned current comparison; describe the addition as a latency allowance, not a measured communications channel.

## Grid and line values already available

Source: `Ashuganj_South_Final_Master_Data_and_Assumptions.pdf`, p.2 §8 and p.4 W5. Text extraction directly confirmed 45.01 kA at 230 kV, X/R = 10.99 and a reported secondary 3.25 ohm figure. The ledger consistently derives the central c=1 magnitude from current, rather than mixing the conflicting reported impedance with the same current. The master classifies these values B (secondary/project supplied), with the derived values D. This is a defensible study input, not a fresh measured PGCB equivalent.

| Quantity | Active PHASE5_STUDY value | Source / derivation |
|---|---:|---|
| Grid initial symmetrical current | 45.01 kA | Master PDF p.2 §8; ledger row GRID_Isc_kA |
| Grid short-circuit level | 17.9307095751953 GVA | sqrt(3) × 230 kV × 45.01 kA |
| Grid R1 = R2 | 0.26734374814821 ohm | Z=230000/(sqrt(3)×45010), R=Z/sqrt(1+10.99²) |
| Grid X1 = X2 | 2.93810779214883 ohm | 10.99 × R |
| Grid R0 | 0.80203124444463 ohm | Explicit study assumption Z0=3Z1 |
| Grid X0 | 8.81432337644648 ohm | Explicit study assumption Z0=3Z1 |
| South per-circuit R1, X1 | 0.056, 0.245 ohm | 0.7 km × 0.08/0.35 ohm/km |
| South per-circuit B1 | 2.94 microS | 0.7 km × 4.2 microS/km |
| South per-circuit R0, X0 | 0.175, 0.84 ohm | 0.7 km × 0.25/1.2 ohm/km |
| South per-circuit B0 | 1.96 microS | 0.7 km × 2.8 microS/km |

Line quantities are explicit engineering assumptions, also reproduced in master PDF p.2 §7. Two circuits are already separately modelled. Each circuit has two half-length PI sections. Do not halve the per-km values again or duplicate the grid impedance inside the ideal EMF block.

Code: `phase6_electrical_profile.m` PHASE5_STUDY branch; `Phase6/data/phase5_reference/phase5_parameter_values.csv` rows GRID_* and SOUTH_*. `phase6_add_network.m` places the finite grid sequence element in series with the EMF source. The source's NonIdealSource='off' does not make the complete grid ideal: its impedance is represented by the separate sequence element.

Changing from PHASE3_BASELINE changes grid, line and GSUT positive-sequence values together. Rebuild and solve load flow; regenerate active reference outputs. A numerical difference from the frozen Phase3 operating point is expected and is not a solver failure.

## Machine friction: installed-library evidence

`C:/Program Files/MATLAB/R2024a/toolbox/physmod/powersys/library/electricalmachines/spsSynchronousMachinepuStandardLib.slx` has this mask prompt:

> Inertia coefficient, friction factor, pole pairs [ H(s) F(pu) p()]

In `spsSynchronousMachineModel.slx`, `simulink/systems/system_22743.xml` (trapezoidal mechanics):

- SID 22764 adds nominal speed to speed deviation, producing w=1+dw.
- Its output feeds gain F1, SID 22759, with Gain=SM.F.
- F1 output enters the negative third input of torque Sum2, SID 22765 (Inputs='+--').
- The torque balance then passes through 1/(2H) and the speed-deviation integrator.

Therefore friction torque is F×w pu, and mechanical friction power is F×w² pu. This is **not** incremental damping D×(w−1). The library's rotational implementation independently uses damper D=(SM.F+1e−6)×SM.Pn/(SM.web/SM.p)², confirming the rated-power interpretation.

F=0.001 means 458 kW at w=1. It is an explicit engineering selection, because neither the reviewed master PDF nor the canonical generator provider gives a mechanical-friction coefficient. A possible study range is F=0.0005–0.002 (229–916 kW at rated speed); these are sensitivity choices, not measured plant tolerances. Do not substitute a conventional incremental damping value such as 1 or 2 into this friction field.

Current old assignment was `init_phase6_parameters.m` P.machine.damping_pu=0. Retain a compatibility field if needed, but label its meaning as viscous-friction factor. Generator electrical damping and rotor time constants already exist; do not double-count a new arbitrary rotor damper circuit.

### Initial mechanical equilibrium

The readable `power_loadflow.m` delegates to protected `private/LoadFlowTool.p` or `machineInitTool`. The actual Pmec formula is not exposed in readable installed m files. Thus source inspection cannot prove whether returned LF.sm.Pmec already includes friction.

Verify with a fresh run that mechanical input balances electrical conversion plus stator copper plus 458 kW friction at w=1. If LF.Pmec already includes it, do not add another 0.001 pu. If it omits it, initialize governor/turbine mechanical input consistently. Root task owns that runtime check.

## Electrical loss terms already finite

| Item | Existing finite value | Basis |
|---|---:|---|
| Machine stator Ra | 0.00089 ohm = 0.000842190083 pu on 458 MVA / 22 kV | Generator workbook U3/C3/D3; master PDF p.1 |
| Machine H | 5.287 s | Generator workbook F3; master PDF p.1 |
| Machine open-circuit time constants | 7.547, 0.045, 0.839, 0.070 s | Workbook Y3/Z3/AA3/AB3; master PDF p.1 |
| Machine zero-sequence R0 | 0.001263285124 pu | Explicit R0=1.5Ra study assumption |
| Generator neutral resistor | 1750.77333333333 ohm | 60+(22000/sqrt(3)/500)²×2.62; qualified Generator Data PDF p.2/report p.7 §2.3 |
| GSUT active profile total R/X | 0.001771262136 / 0.166290566872 pu | Workbook loss (1067.5−155.3)kW/515MVA and Z=16.63%; master PDF p.2 §5 |
| GSUT winding R1=R2 | 0.000885631068 pu each | Equal split of total R |
| UAT total R / winding R | 0.004 / 0.002 pu each | Canonical documented 0.4% R |
| GAT total R / winding R | 0.005 / 0.0025 pu each | Canonical documented 0.5% R |
| UAT/GAT neutral resistance | 796.743371 ohm | (6900/sqrt(3))/5 A |
| Closed breaker resistance | 0.0001 ohm | Existing Phase6 contact-resistance assumption |
| Breaker parallel snubber | 1e6 ohm | Existing numerical regularization |
| Fault phase / ground resistance | 0.01 / 0.01 ohm | Existing finite fault-study setting |
| Fault parallel snubber | 1e9 ohm | Existing numerical regularization |
| Grounding equivalent magnetization | [1e7,1e7] pu | Existing finite weak shunt regularization |

GSUT, UAT and GAT magnetizing resistances and reactances are already finite. Canonical no-load losses are 159/14/23 kW and excitation currents 0.13%/0.3%/0.3%; `ashuganj_transformers.m` computes Rm=S/P0 and Lm=1/sqrt(I0²−(1/Rm)²). These should remain source-based instead of arbitrary tiny/large replacement values. The GSUT active profile inherits canonical magnetic-branch data while selecting the workbook copper/leakage values; that source distinction should be recorded.

SnubberCapacitance='inf' selects the SPS resistive-snubber convention; it is not a claimed infinitely large physical capacitor. Replacing it merely to eliminate an 'Inf' string changes topology and can affect numerical stability. Similarly, the grounded-star ideal reference is a topology convention; physical neutral impedance is separately represented where applicable.

## Timing and DC terms already finite

- Electrical integration 50 microseconds; protection/control sampling 1 ms.
- Measurement window one 50 Hz cycle =20 ms.
- Governor response 0.2 s; turbine response 0.75 s; AVR response 0.02 s.
- 87G/87T detection proxy45 ms; 87B local35 ms; 87L local35 ms plus accepted5 ms communication/processing allowance.
- Breaker mechanism delay50 ms for each of five equivalent breaker commands.
- Battery internal resistance0.05 ohm; charger response0.1 s.
- Aggregate trip pulse2 kW for0.2 s; close pulse3 kW for0.5 s.

These values come from `engineering_assumptions.m`, frozen relay CSVs, `phase6_control_parameters.m`, and `phase6_dc_parameters.m`. A trip sets governor/field **targets** to zero, but actual outputs decay through the existing finite states; it does not zero mechanical power or field voltage instantaneously.

### Line communication allowance implementation recommendation

Add a named `R.communicationDelay_s=0.005`, preserve local frozen detection delay separately (e.g. `R.localDelay_s`), and apply 0.005 only to the fourth differential element (87L). Effective line operating delay=0.035+0.005=0.040 s. Keep local87G/87T/87B delays unchanged. Update exported settings to show local, communications and effective time separately; distinguish this active addition from the frozen ledger.

Basis: five1-ms control samples is a modest explicit processing/transport allowance. Physical propagation on a0.7km fibre is only about3.5 microseconds at2e8m/s, so5ms represents framing, transport and processing rather than distance alone. It is not a manufacturer or site measured value. A2/5/10ms sensitivity can test reliance on the choice. Do not delay only one current phasor relative to the other without timestamp alignment; that would create artificial differential spill. The existing synchronized-current calculation plus an added decision-availability allowance is a coherent reduced model.

## Zeros that should remain meaningful

Do not turn disabled Boolean flags, initial timers, zero neutral-vector padding, zero inactive trip requests, no-fault commands, signed coordinate references, limiter lower bounds, or the absent-event Inf sentinel into arbitrary positive physical parameters. They represent state, topology, formatting or “event not scheduled,” rather than zero-resistance components or zero-time dynamics.

CT saturation, harmonic blocking and auxiliary induction-motor dynamics require actual model states/algorithms. Renaming flags or assigning a positive metadata number does not implement them. Keep their explicit scope and implement only when supported by the intended study and tests.
