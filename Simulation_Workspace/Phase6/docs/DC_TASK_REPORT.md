# Station DC engine

Status: pure-engine regression tests passed in MATLAB R2024a on 2026-09-22 at 08:51:15 Asia/Dhaka (`job027_dc_final.m.done`, `success: true`). Simulink wrapper verification is separate. This is a lumped academic supply equivalent, not installed battery/charger commissioning evidence.

## Sources and parameters

`phase6_dc_parameters(P)` reads canonical record fields from `P.assumptions`, or the unchanged `matlab/data/engineering_assumptions.m` when omitted. It retains every numeric `dc_*`, `charger_*` and `load_*` key with exactly the source value, and requires matching `value`/`selected_value` in supplied records. Source policy was checked against `matlab/data/ashuganj_phase2_systems.m`. No upstream file was modified.

The bank is 55 cells, nominal 110 V, 200 Ah, 0.05 ohm whole-bank resistance and linear OCV from 105 V at SOC 0 to 116 V at SOC 1. Initial SOC is 1, usable interval is 0.2–1, loaded discharge cutoff is 105 V, discharge limit is 200 A, charge limit is 40 A and coulombic charge efficiency is 0.9.

The charger uses one active 20 kW DC-output unit, 180 A ceiling, 123.75 V float target, 0.1 s current-control lag, 50 A/V voltage gain and 0.925 efficiency. Two installed study units represent duty and standby; availability is their aggregate ability to provide one duty supply. Capacity is never doubled. The standby transfer delay is unmodeled.

The six always-on loads are 0.3 + 0.5 + 0.4 + 0.2 + 0.3 + 0.7 = 2.4 kW. Additional loads are a 2 kW, 0.2 s trip pulse; 3 kW, 0.5 s close pulse; and caller-switched 5 kW emergency demand. Excitation electronics means control electronics only, with no generator field-power or SFC supply inferred.

Added academic interface assumption: charger AC availability requires the **measured auxiliary-bus positive-sequence magnitude to be at least 0.8 pu**. This is not an installed undervoltage setting. `D.serviceTolerance_W = 1e-6` is only a numerical served-power tolerance. Numeric provenance codes are 1 for canonical source records, 2 for supplied caller records and 3 for Phase 6 implementation assumptions. `D.provenance` and `D.assumptions` carry these codes/options without strings in the runtime structure.

## Interface

```matlab
D = phase6_dc_parameters(P); % P optional
[Y,state] = phase6_dc_step(U,state,dt,D);
```

Pass empty state for a fresh study. The public state includes `SOC`, `chargerCurrentCommand_A` (bounded current-control reference), previous bus voltage, previous trip/close requests and the two remaining pulse durations. The current command is not delivered current or stored electrical energy. `dt` is a positive finite elapsed interval in seconds. The intended integration step is 1 ms; the exact exponential lag avoids forward-Euler lag instability. SOC current limits account for the remaining usable charge over the actual interval.

| U field | Meaning |
|---|---|
| `auxVoltage_pu` | Actual measured AC auxiliary-bus positive-sequence voltage magnitude |
| `batteryAvailable` | Bank hardware connected/available |
| `chargerAvailable` | Duty-or-standby aggregate hardware available, one-unit capacity |
| `tripDemand` | Raw trip request; a rising edge starts one pulse |
| `closeDemand` | Optional raw close request; default false |
| `emergencyLoad` | Optional sustained switched load; default false |

| Y field | Meaning |
|---|---|
| `Vdc_V` | Solved bus voltage |
| `Ibattery_A` | Actual bank current; positive discharge, negative charge |
| `Icharger_A` | Actual delivered charger current |
| `Iload_A` | Actual served load current |
| `SOC` | Bank state after the elapsed interval |
| `dcHealthy` | Bus at least 105 V and full requested load served within numerical tolerance |
| `lowVoltage` | Bus below 105 V |
| `batteryLow` | Bank unavailable or at SOC reserve |
| `chargerFailure` | Hardware unavailable or auxiliary AC below pickup |
| `tripUnavailable` | Inverse of `dcHealthy`; an availability status, independent of request |
| `unservedPower_W` | Requested minus delivered load power |
| `chargerACPower_W` | Actual charger DC output power divided by 0.925 |
| `tripCoilPower_W` | Actual delivered trip-coil power, zero when supplies cannot energize it |

Trip and close pulses start on raw request edges regardless of supply health. This avoids an algebraic dependency between trip demand, coil load and `dcHealthy`. A held request does not repeat. A failed-supply pulse is recorded as unserved load; restoring power after its duration does not create a new pulse. A fresh falling/rising request edge is required to retry. Fractional pulse intervals use average power so the requested trip pulse integrates to exactly 400 J even when `dt` does not divide 0.2 s. The root model must coordinate physical breaker retries with this policy.

## Circuit and control equations

For a conducting unconstrained battery, the bus satisfies `V = E(SOC) - R*Ib`, `Ic + Ib = Pload/V`. The engine uses the high-voltage solution of `V^2 - (E + R*Ic)*V + R*Pload = 0`. This gives actual load-dependent sag, including greater sag when coil/emergency loads turn on.

Before accepting that solution, the engine checks current direction, charge/discharge limits, available SOC and the loaded-voltage cutoff. A charge-current limit curtails charger output and solves the bus at `E + R*Icharge`. A discharge-current limit permits only the load power supported by `E - R*Idischarge`; the deficit is reported. At the loaded-voltage cutoff the bank stops discharging, as required by the canonical policy. The cutoff is not chemical empty SOC. Charging remains possible from SOC reserve.

The charger demand is bounded voltage-error feedback with the canonical 50 A/V gain. Where the battery can charge, requested current is additionally limited to load plus permitted battery-charge current. The controller senses the reachable battery charging voltage when reconnecting from reserve, preventing an isolated charger float voltage from falsely inhibiting recharge. At full SOC or with no bank, load-current feed-forward implements the source's load-only float policy. The exact lag is `Iavailable = Iprevious + (Itarget-Iprevious)*(1-exp(-dt/0.1))`. The bounded reference is retained while charging is possible, so it can rise above float-load current and reconnect charging from reserve. With the bank full or absent, actual curtailed output returns to the controller state. Neither path accumulates an unbounded voltage-error integral.

The current envelope also uses the 20 kW limit evaluated at the maximum bus voltage, 123.75 V. Thus its conservative combined ceiling is `min(180,20000/123.75) = 161.616... A`; DC output can never exceed 20 kW anywhere below float. It does not imply a lower manufacturer current rating. This avoids an unstable power-limit algebraic loop and is conservative at the lower battery-charging voltages. Canonical simultaneous load plus 40 A recharge fits inside this envelope. An exact nonlinear charger capability curve is not modeled.

At full SOC, an ideal charge-blocking path lets an adequate charger hold 123.75 V without forcing current into a 116 V OCV bank. The bank reconnects to supply deficits. At full SOC the charger supplies load only. This is the explicit Phase 2 policy, represented as an ideal control/connection equivalent rather than a continuously hard-paralleled battery forced above OCV.

When the battery cannot supply the operating point, the charger holds float if it can serve the load. During insufficient-current startup/brownout, the load is represented by its rated-voltage equivalent resistance: `V = Vfloat*min(1,Ic/(Prequested/Vfloat))`. Actual power is `V*Ic`, and the remaining request is unserved. This declared low-voltage equivalent avoids the constant-power singularity at zero voltage. It produces zero bus voltage with both supplies lost. Coil, electronics and other served fractions use proportional allocation; device-specific dropout and priority shedding are not represented.

Every step conserves bus current and power: `Ic+Ib=Iload` and `V*Iload+Punserved=Prequested`. The battery OCV source supplies terminal power plus `Ib^2*R` loss while its path conducts. SOC changes by `-Ib*dt/(3600*Ah)` on discharge and `-0.9*Ib*dt/(3600*Ah)` on charge. AC loss immediately removes charger current and input power; its control lag is not treated as stored supply energy. A fresh, healthy initial state starts with settled continuous-load charger current rather than an artificial model-start voltage dip.

## Scope and integration

This pure engine supplies a physical lumped DC equivalent with explicit load and energy accounting. It does not implement battery chemistry/temperature/aging, cable/contact resistance, actual DC fault interruption, individual charger switching, bus capacitance, device-specific dropout, or relay/breaker coil nameplate curves. Added ideal current limiting, charge blocking, brownout resistance and proportional load allocation are study assumptions. They are not manufacturer behavior claims.

The actual AC bus voltage must drive `auxVoltage_pu`; a scenario flag must not substitute for that measurement. `chargerACPower_W` is available for AC-side accounting. If this power is fed into the dynamic auxiliary load, do so explicitly and keep the frozen Phase 3 operating-point comparison separate. A lost charger with a healthy charged battery leaves trip power available; total source loss inhibits it. Physical breaker operation and relay latch/reset sequencing remain root-model responsibilities.

## Verification

```matlab
addpath('Phase6/scripts/tests');
clear phase6_dc_parameters phase6_dc_step test_phase6_dc
rehash
test_phase6_dc;
```

The tests independently check the analytical battery-only voltage, KCL and load-power balance, healthy/full-SOC float support, battery-only trip delivery, pulse energy and retriggering including coarse time steps, measured AC failure, both-supply loss, charger-only restoration, one-unit current/power limits, discharge reserve, loaded-voltage cutoff above SOC reserve, recharge recovery, charge efficiency, near-full settling, finite charge at the reserve boundary and caller capacity records.

Test-first evidence starts with `job020_dc_red.m.done`, which records the intended missing-engine failure. The tests then exposed an incorrect full-SOC branch preference and a reserve-recharge current-command deadlock; both were corrected at their circuit/control boundaries. `job023_dc_probe.m.log` confirmed that the exact-equality load comparison differed by only 4.55e-13 W, so that test uses a numerical tolerance. `job025_dc_reserve_probe.m.log` captured the reserve deadlock before correction. The complete suite passed in `job026_dc_green.m` and, after explicit cutoff/coarse-step checks and tolerance centralization, in `job027_dc_final.m`, whose log contains `PHASE6_DC_TESTS_PASS`.

## Simulink adapter

`phase6_dc_sfun` is a Level-2 MATLAB S-function with dialog parameters `D,S`. Its two real-double scalar inputs are actual auxiliary-bus voltage pu and aggregate raw trip demand. It reads `S.batteryAvailable` and `S.chargerAvailable`. During `S.dcLossTime_s <= simulationTime < S.dcRestoreTime_s`, both supplies are forced unavailable; omitted loss/restore times default to infinity. This scheduled availability change represents the explicit supply-failure scenario, while charger AC failure still derives from the actual AC input. The wrapper does not expose optional close/emergency inputs.

The one output vector contains exactly 12 values: Vdc, Ibattery, Icharger, Iload, SOC, dcHealthy, lowVoltage, batteryLow, chargerFailure, tripUnavailable, chargerACPower, tripCoilPower. `unservedPower_W` remains available from the pure engine but is not a separate port in this specified 12-value adapter. Full-load availability already accounts for it in `dcHealthy`.

Eight real DWork values contain SOC, charger-current command, prior voltage, prior trip/close booleans, remaining trip/close durations and an initialization flag. No persistent/global state is used. The first `Update` initializes the pure engine from actual input values exactly once. Before that first measured update, outputs report zero voltage and unavailable trip power, with the prescribed initial SOC; this is the explicit initial state of the delayed measurement interface. Normal initialized supply appears on the next 1 ms sample. Gate interpretation of that initial sample consistently with phasor-valid/startup handling.

Both input ports have no direct feedthrough. `Outputs` returns the previous `Update`, adding one sample of coupling latency and avoiding a relay/DC/breaker algebraic loop. Pulse timers and SOC reset every simulation run. The wrapper test compiles the model, confirms battery-only coil energization, checks the scheduled total-supply-loss interval and restoration, and runs the model again to verify reset behavior. `job029_protection_wrappers_green.m.done` records `success: true` at 08:55:23 Asia/Dhaka, with `PHASE6_PROTECTION_SFUNCTIONS_PASS` in its log.

Run adapter verification with `addpath('Phase6/scripts/tests'); test_phase6_protection_sfunctions;`. The test creates and closes a temporary in-memory model; it does not save or change upstream electrical models.
