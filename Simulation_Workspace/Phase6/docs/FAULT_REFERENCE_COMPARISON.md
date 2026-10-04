# Fault-current reference comparison

This comparison was recomputed from the saved September 23 Phase 6 complex
phasors. It does not rerun MATLAB or alter the model. The CSV contains the three
measured phase currents and one governing comparison for each of seven cases.

| Scenario | Frozen location/type | Phase 6 fundamental (A) | Frozen initial Ikpp (A) | Difference |
|---|---|---:|---:|---:|
| generator_3ph | F1 LLL | 110723.529092 | 126214.141190 | -12.273% |
| generator_slg | F1 LG | 7.256670 | 7.272004 | -0.211% |
| transformer_lv_ll | F2 LL | 98969.749702 | 109251.634192 | -9.411% |
| transformer_hv_llg | F3 LLG | 48506.047838 | 48503.661793 | +0.005% |
| bus_3ph | F3 LLL | 49894.525500 | 50530.885187 | -1.259% |
| line_slg | F4 LG | 45807.804140 | 46117.008837 | -0.670% |
| grid_external_ll | F5 LL | 45569.156645 | 45972.580435 | -0.878% |

## Meaning of the comparison

The Phase 6 column uses the mean of 39 complete post-fault phasor windows,
0.171 <= t < 0.210 s, before any breaker open command. The governing quantity
follows `matlab/phase4/phase4_solve.m`: positive-sequence |I1| for 3PH, |Ia| for
SLG, and max(|Ib|, |Ic|) for LL/LLG. Each quantity is calculated at every sample
before averaging. The CSV retains the individual A/B/C means, without inventing
phase-specific frozen references. All currents are RMS amperes; waveform peaks
and waveform RMS containing DC offset are excluded from the comparison.

The reference is `data/phase5_reference/phase5_fault_inputs.csv`, selected by
LF360_GAT_OUT, m=0.5 and stage Ikpp. It preserves the locked Phase 4 initial
symmetrical fault calculation. F1 is the generator 22 kV bus, F2 the GSUT LV
interface, F3 the GIS bus, F4 the midpoint of one South circuit, and F5 the
remote bus. GSUT HV uses the adjacent F3 electrical reference with an explicit
protection-boundary qualification.

Every governing comparison is **QUALIFIED_DIFFERENT_STAGE_AND_MODEL**. No
accuracy tolerance or PASS is asserted. Phase 6 uses a synchronous machine and
a later measurement window in which subtransient current is already decaying.
Its selected PHASE3_BASELINE retains Rgrid=0 and adds declared zero-sequence
assumptions; the frozen fault backbone uses finite grid resistance and its own
sequence assumptions. Phase 6 has 0.01 ohm fault/ground resistances. The later
PHASE5_STUDY grid, line and GSUT alternatives are a separate profile and were
not used to regenerate the frozen fault CSV. The larger generator/LV deltas
therefore require this qualification; no parameter was adjusted to force agreement.

Source paths and SHA-256 hashes, exact windows, sample counts, formulas and
signed differences are retained in `results/fault_reference_comparison.csv`.
Regenerate it with `scripts/export_phase6_fault_reference.py` using Python 3.
The generator checks unique reference keys and independently reconstructs all
21 phase means against the existing `fault_summary.csv` values before writing.

## Interruption and internal generator faults

`breaker_times.csv` measures current cessation at the opened breaker branch.
It does not prove extinction of a generator-side internal fault. In the saved
generator 3PH run, GCB opens at 0.247 s, yet faultGEN still carries about
27.1-27.5 kA waveform RMS at 0.400 s. In the timed generator SLG run, GCB opens
at 1.971 s, yet faultGEN carries 6.863 A at 2.200 s. These faults are scheduled
off at 0.450 s and 2.300 s respectively. The model commands field/prime-mover
shutdown and retains stored machine energy; these records demonstrate external
branch isolation and source-input decay, not a verified full internal-fault
extinction time or long-duration post-fault stability.
