# Study inputs and installed-document verification

The selected numerical study has inputs for its included network, operating point and implemented protection/DC functions. Where plant records do not establish a value, the model uses a classified engineering assumption or excludes the unsupported detail. These choices make the study runnable while keeping installed-equipment verification separate.

The source/status/derivation ledger is `PHASE5_ASSUMPTIONS.csv`. Phase6 reads frozen CSVs under `Phase6/data/phase5_reference/`; the effective parameter register is exported to `Phase6/results/phase6_parameter_register.csv`. `HARDWARE_SELECTION_v4.md` records candidate hardware assumptions, not automatic changes to model blocks.

## Implemented dynamic study settings

- GEN-51: 17170.8 A primary, IEC SI, TMS 0.10. The historical 17171 A / 3 s comparator is a separate sensitivity.
- GSUT-HV-51: 1380 A primary, IEC SI, TMS 0.55. GEN-51N: 4 A primary, IEC SI, TMS 0.15, assumed dedicated 20/1 CT.
- 87G: 2403.8 A pickup, 30% half-sum restraint, 0.045 s operation proxy; high-set disabled.
- 87T: 387.84 A on the 230 kV side, 30%/60% half-sum restraint, knee twice 1292.8 A, 0.045 s operation proxy.
- 87B: 320 A pickup, 30% half-sum restraint, 0.035 s local delay.
- 87L: 320 A pickup, 30% half-sum restraint, 0.035 s local delay plus 0.005 s communication/processing allowance, giving 0.040 s effective delay. The separately recorded 0.050 s legacy line-scheme value is a proxy, not the active timer or a communications test.

Added standalone 87G 20%/50% / high-set 5 pu and 87T 25%/50% / high-set 8 pu calculators do not change these settings. Their harmonic-block examples do not implement blocking in the dynamic chain. Distance 21, 50BF, 64G and other ledger entries are not evidence that those functions run in Simulink.

## Explicit modelling limits

- Default `PHASE5_STUDY` uses finite grid R1/R2 = 0.267343748 Ω and X1/X2 = 2.938107792 Ω, revised line/GSUT inputs, and declared zero-sequence assumptions. `PHASE3_BASELINE` preserves the earlier balanced load-flow comparison with `Rgrid = 0`; it is selected only for that historical comparison.
- The active machine has a finite F = 0.001 pu viscous-loss assumption. On the 458 MVA machine base this gives 458 kW at rated speed; its power loss varies with speed squared. It is not measured incremental damping.
- Phase6 uses finite assumed zero-sequence and neutral values where required. Archived source fields without qualified units/bases are retained for provenance and are not used as active circuit parameters. Excluded 400 V demand is already included in the modeled 14 MW auxiliary aggregate.
- Relays use synchronized phasors with no CT saturation or harmonic-blocking model. The active 87L timer includes a finite 5 ms aggregate allowance, without sample transport, channel-failure or packet simulation. Candidate CT burdens, soil and tower footing values in a note do not model those effects.
- Trip/DC quantities represent the documented aggregate supply and breaker mechanisms, not individual coil wiring, contact feedback or vendor-certified interruption.
- Breaker-branch cessation does not establish complete internal generator-fault extinction. Remaining machine energy, scheduled fault removal and measurement window matter.

Blank relay-setting cells mean the field does not apply to that function; generated build-parameter CSVs use `not applicable`. Result-event statuses such as no trip or continued current mean the event was not observed during the run. Their absent timestamps are not unresolved numerical inputs.

## Conditional duty findings

Frozen `results/phase5_protection_v2/phase5_breaker_duty.csv` screens actual-side branch currents: Q0 maximum 6.897015 kA against a conditional 50 kA transformer-bay mapping, and 52G maximum 55.048710 kA against 100 kA. These are initial-current screens. Installed identity, breaking-time current, timing, DC capability, making duty and TRV remain unverified.

The added `q0_breaker_duty_matrix.csv` is a hypothetical 400 kV / 63 kA envelope with assumed 3.03 kA plant contribution. South connects at 230 kV. Its 53.03 kA / 63 kA = 84.175% example does not close South Q0 duty or prove a current PGCB maximum. A 50 kA rating cannot cover 53 kA demand on the same basis.

## Installed-document verification still required

- Relay settings, CT protection core/tap schedules, excitation curves, burdens and transient performance.
- Current PGCB positive-, negative- and zero-sequence equivalents, fault-level date and topology.
- Q0 bay/nameplate mapping, contact-parting time, DC capability, making rating and TRV.
- Generator neutral CT ratio, NGT/loading-resistor interpretation and measured resistance. The 1750.77 ohm study value remains derived from qualified entries.
- Actual 87T/87B/87L bias, vector compensation, communications and remote-end settings; 86/50BF wiring.
- 7UM62 64G settings/manual pages and injection adjustment. Ledger defaults remain study values.
- South route/conductor geometry, motor data, controller tuning and DC distribution/coil wiring.

Rotor-earth, reverse-power, turbine mechanical trips and functions outside the implemented study are not assigned fabricated commissioning settings. See the [HTML manual](Phase6/docs/SIMULINK_USER_MANUAL.html) for operating instructions and [v4 audit](Phase6/docs/V4_SIMULINK_AUDIT.md) for September 25 corrections and measured-run verification.
