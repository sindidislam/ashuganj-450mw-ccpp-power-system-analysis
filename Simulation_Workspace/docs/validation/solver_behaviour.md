# Measured Solver and Block Behaviour — Simscape Electrical Specialized Power Systems

**Environment:** MATLAB **R2024a (24.1.0.2537033)**, PCWIN64 · Simscape Electrical 24.1 · `powergui` + `power_loadflow` · system frequency **50 Hz**

## Why this document exists

Every statement below was **measured by a probe script that is still in the repository**, not taken from documentation, a forum post, or prior experience. Several of them are the opposite of what the block dialogs and the `help` text imply, and at least three would have produced a plausible-looking but wrong load flow if assumed instead of tested.

The project rule that no electrical parameter may be invented applies equally to the *behaviour of the tool*. A modelling result is only as trustworthy as the mechanism that produced it, so the mechanism was measured.

Each finding names the probe that established it. Probe scripts live in `matlab/env/` with their captured output alongside as `.txt`. **`matlab/env` is deliberately NOT on the MATLAB path** — probes are evidence, not library code, and are run explicitly:

```bash
matlab -batch "ashuganj_setup; run(fullfile(ashuganj_root,'matlab','env','probe_lf_status.m'))"
```

---

## B1 — `powergui` carries a hidden `frequencyindice`, and 60 Hz is the default

**Severity: would have invalidated every result.**

The model audited **clean at 50 Hz** on every block that has a frequency: `powergui` `Frequency = 50`, every Three-Phase Source `Frequency = 50`, every transformer `NominalPower(2) = 50`, every load `NominalFrequency = 50`. `power_loadflow` nevertheless returned `LF.frequency = 60`.

The cause is a **second, separate** `powergui` parameter, `frequencyindice`, which indexes a frequency list rather than holding a frequency. Setting `Frequency` alone leaves `frequencyindice` at its default, and the load-flow engine reads the index. This is not cosmetic: the grid equivalent is entered as a pure inductance, so a 60 Hz solve would have used **1.2×** the intended reactance while every dialog still read 50.

**Treatment:** `build_ashuganj_main.m` sets **both** `Frequency` and `frequencyindice`, and the model header records why. The fix is verified by measurement rather than by re-reading the dialog: `probe_settle.m` back-computes the *effective* reactance of the pure-inductance grid branch from the solved current and voltage and confirms it corresponds to **50.000 Hz**.

- Discovered: `probe_lfparams.m` (Blocker A)
- Confirmed by independent measurement: `probe_settle.m`, `probe_freq.m`
- Cross-checked in the test suite: the 50 Hz assertion in `test_base_conversion.m` / grid reactance checks

Bangladesh operates at 50 Hz. The prior CYME PSAF model was built at **60 Hz** (defect D2, `prior_psaf_model_defects.md`), and 60 Hz is *also* the Simulink default — the same wrong number arriving from two independent directions, which is exactly the situation in which an assumption is most dangerous.

---

## B2 — The load-flow voltage setpoint is `BaseVoltage`, not `Voltage`

`power_loadflow` reported the generator and grid source voltages as **25000 V — the block default** — even though `Voltage` had been explicitly set to 22000 V and 230000 V, while `Pref` and `BusType` on the same blocks *did* apply. So the load-flow solver reads a **different parameter** from the one labelled as the physical voltage: `LF.vsrc(i).Vnom` comes from **`BaseVoltage`**.

Guessing the parameter name is precisely what this project must not do, so the full dialog parameter set of every block was dumped and compared against the solved struct.

- Parameter dump that exposed the mismatch: `probe_params.m`
- Setpoint semantics settled by experiment (does the PV magnitude come from `Voltage`/`BaseVoltage`, or is it 1.0 pu regardless?): `probe_vset.m`

**Consequence for this study:** the generator PV setpoint of 1.00 pu is an *assumption* (`matlab/data/assumptions/generator_voltage_setpoint.m`) — but the mechanism by which it reaches the solver is a *measurement*, and the two must not be confused.

---

## B3 — `power_loadflow('solve')` writes back into the model

`power_loadflow`'s own help states that "the model is initialized with the load flow solution". Measured: this is literal. The solve **mutates the blocks**, so solving twice on one model instance does not repeat the same computation — the second solve starts from a network whose blocks already carry the first solution.

**Treatment:** every case is solved on a **freshly built model**, and the model is closed with `bdclose` immediately afterwards. No model instance is ever solved twice. The deliverable `.slx` files are saved from **clean builds**, so what is on disk is the network *as specified*, not a network with a solution smeared into it.

- Established by: `probe_mutation.m`

---

## B4 — The report is a suffix to `'solve'`, and it is written as `.rep`

Measured API shape:

```matlab
LF = power_loadflow(SYS, 'solve');                        % solve
LF = power_loadflow(SYS, 'solve', 'report', FNAME);       % solve AND report
```

`'report'` is **not** a standalone command — it is an option appended to `'solve'`. An earlier version of the study called `power_loadflow(model,'report',path)` as a second, separate call; that was removed, because two calls can describe two different networks (see **B3**).

The filename passed in gets **`.rep` appended**. Asking for `LF1_powergui_report.txt` produces `LF1_powergui_report.txt.rep`. The study therefore passes a base name and documents the real extension.

- API shape: `probe_loadflow.m`, `probe_lfparams.m`
- Extension: measured by listing `results/load_flow/` after a run

---

## B5 — `status` is `1` / `−1`, and a failed solve returns a **truncated** `LF.bus`

**Severity: silent wrong results.**

`power_loadflow` **does not throw** on non-convergence. Measured semantics:

| | Converged | Did **not** converge |
|---|---|---|
| `LF.status` | `1` | `−1` |
| `LF.error` | `''` (empty) | solver message |
| `LF.iterations` | actual count | `0` |
| `LF.bus` | 22 fields | **12 fields — `Vbus` and `Sbus` absent entirely** |

`LF.status` is a **double**, not a string. An early version of the study compared it against text, which is always false, so the convergence gate never fired.

`LF.bus(k)` on success carries: `handle, ID, vbase, vref, angle, sm, asm, vsrc, pqload, rlcload, blocks, busType, Sref, Vbus, Sbus, Sgen, Spqload, Sshunt, Qmin, Qmax, QminReached, QmaxReached`.

**Treatment:** convergence is gated **before any post-processing**, because a failed solve has no solution fields to post-process. A non-converged case is recorded with `NaN` — never `0`, which would read as "measured zero loss" instead of "not solved" — appears in `system_summary.csv` carrying the solver's own message, and is **absent** from the detail tables rather than filling them with rows of NaN that look like results.

- Established by: `probe_lf_status.m`
- Field inventory: `probe_lf_fields.m`

---

## B6 — An open breaker is a 1 MΩ snubber, not an open circuit

The Specialized Power Systems Three-Phase Breaker defaults to `SnubberResistance = '1e6'` Ω and `SnubberCapacitance = 'inf'`. An "open" breaker is therefore a **1 MΩ galvanic connection**.

In the GAT-out cases (LF1, LF3) this creates a real path: 6.6 kV → GAT → GAT HV terminal → snubber → 230 kV busbar → grid. The 230 kV voltage leaks back through it, so quantities that *should* be mathematically independent of grid strength are not exactly independent in the solved model.

The size of the artefact was **measured and separated from the solver tolerance**:

| Snubber | UAT loading spread across an 8× grid-impedance range |
|---|---|
| 1e6 Ω (default) | 1.68e-4 MVA |
| 1e8 Ω | 1.43e-5 MVA |
| 1e10 Ω | 1.61e-5 MVA — **no further reduction, trend no longer monotonic** |

The plateau between the last two rows is the **solver's convergence tolerance**, which no change to the model removes. The two causes are therefore distinguishable by experiment, and the tolerances in `test_grid_sensitivity.m` are set **above the measured artefact** rather than tuned until the test passed. 1e-3 MVA is 6× the snubber artefact and 60× the solver floor, and still asserts independence to 6e-5 of UAT loading.

The mask parameter for external control is **`External`**, not `ExternalControl`.

- Established by: `probe_snubber_coupling.m`
- Block mask names: `probe_params.m`, `probe_powerlib*.m`

---

## B7 — The solver merges zero-impedance nodes: 8 register buses, 5 solved nodes

A zero-impedance connection is **not a branch** to `power_loadflow` — it is an **identity**. The bus register defines eight buses; every case solves **five nodes**.

| Register buses | Solved as | Why they merge |
|---|---|---|
| `B6_6`, `B6_6_WI1`, `B6_6_WI2` | one node | 6.6 kV feeder impedances are **MISSING** (`ashuganj_lines.m`); treatment **S7** |
| `B230_1`, `B230_2` | one node | bus coupler **closed** (assumption, Q9a) |
| `GAT_HV` | **stays separate** | the GAT winding terminates on it |

`GAT_HV` does **not** merge with the busbar even when the bay breaker is closed, because a closed breaker is a 0.01 Ω resistance, leaving the two nodes **2e-6 pu apart**. So the node count is five in *both* the bay-open and bay-closed cases, but for different reasons.

**Consequence for reporting.** The solver's injection at the merged 6.6 kV node is the **whole 14 MW** auxiliary load. Copying it onto all three register rows would make the bus table total **42 MW** of auxiliary load in a plant that has 14 — a wrong number that looks entirely plausible. `ashuganj_bus_results.m` therefore emits every register bus but gives the solver's injection only to the **representative** of each merged group; the others report `NaN` and name the bus they merged into, in a `Merged_into` column. Each bus's own allocated share stays visible in separate `P_load_alloc_MW` / `Q_load_alloc_MVAr` columns — **dataset input, never mixed into solver-output columns**. Merged members are also **skipped** in the KCL residual list, rather than given a NaN that would pass silently through a `max()` check.

- LF2 node set measured by: `probe_lf2_nodes.m`
- Independently visible in `results/load_flow/LF2_powergui_report.rep`, which the solver writes itself and which lists only 5 buses

---

## B8 — Buses must be identified by **block handle**, never by voltage

`power_loadflow` numbers buses; it does not name them, and the numbering is **not** the order in which blocks were created, nor stable across cases.

An earlier `ashuganj_bus_map.m` identified the GAT HV node by predicting its floating voltage and matching to five digits. That worked in LF1 and was **wrong in principle** — in LF2 the two candidate 230 kV nodes are 2e-6 pu apart, so matching by magnitude is a coincidence, not an identification. It duly failed the first time LF2 was solved.

Measured escape route: the solved struct **does** carry identity.

- `LF.vsrc(i).busNumber` — maps each source block to its bus (swing = EXT GRID, PV = G1)
- `LF.rlcload(i).busNumber` — maps each load block to its bus
- `LF.bus(k).blocks` — Simulink **handles** of the load-flow blocks terminating on bus *k*

Every bus is now found by the equipment attached to it. The voltage predictions are retained as **cross-checks on the physics** rather than as the mechanism of identification, which is the right way round.

**Handles are per-build.** Any handle-based map must use the zones exported by the build that was actually solved; `ashuganj_bus_map.m` enforces this by comparing `bdroot` against `LF.model`.

- Established by: `probe_lf_fields.m`, `probe_lf_busnames.m`

---

## B9 — `.rep` reports iron loss separately, giving an independent loss decomposition

`powergui`'s own `.rep` output lists **"Total Zshunt load"** separately from series losses. For LF2:

| | MW |
|---|---|
| Zshunt load (transformer iron loss, i.e. the derived R<sub>m</sub>) | 0.19 |
| Series (copper) losses | 0.64 |
| **Sum** | **0.83** |

That sum equals the study's independently computed `Ploss = 0.83326 MW`, and the split matches the hand decomposition (iron 0.1937, copper 0.6194 MW). This is a **third-party check on R<sub>m</sub>**: the solver, the study's own branch-flow reconstruction, and a hand calculation agree on both the total and its split.

A second self-consistency check falls out of the GAT-out cases: with its bay open the GAT draws `P_loss = 0.0211 MW` = **21.1 kW**, against a documented no-load loss of **23 kW** scaled by V² at the 0.958 pu energisation of its 6.9 kV winding (23 × 0.958² = 21.1 kW). R<sub>m</sub> entered correctly.

---

## B10 — MATLAB-level behaviours that cost real debugging time

| Behaviour | Measured reality | Where it bit |
|---|---|---|
| `close_system(mdl, 0)` | Does **not** force-close a *modified* model; warns instead. `bdclose(mdl)` does force it. | Every build/solve loop leaked a dirty model until all sites were changed to `bdclose` |
| `getfullname(numericHandle)` | Returns a **cell**, not a char | Block-path formatting in probes |
| `struct([])` | Has **no fields**, so `S(i) = populatedStruct` fails with *"dissimilar structures"* | Case accumulation; fixed by collecting into a cell and `[c{:}]` |
| Series RLC Branch | `BranchType` `'L'` is a *pure inductance* — setting `Resistance` on it is silently inert. `'RL'` is required for a non-zero R | The X/R sweep in `test_grid_sensitivity.m` Part 2 switches `BranchType` explicitly rather than only writing `Resistance` |
| Admittance rebasing | `Y_new = Y_old × (S_old / S_new)` | R<sub>m</sub> conversion for all three transformers |
| Loading an SPS library | **Wipes the base workspace** — one of the libraries carries a load callback that clears it. Since `run()` evaluates in the caller's workspace, variables defined before a `load_system` sweep are gone after it | `probe_bus_blocks.m` died on *"Unrecognized function or variable 'root'"*; every probe that sweeps libraries now recomputes its variables afterwards |

---

## B11 — A `Load Flow Bus` block **does** exist, and `Phases='ABC'` silently changes the study type

This entry corrects an earlier conclusion of mine. `probe_loadflow_bus3.m` searched the libraries in `toolbox\physmod\powersys\powersys` for a block whose name matches `/load\s*flow/`, found only `psbflowsolv/LoadFlow` (zero electrical ports, solver internals), and concluded that no user-facing bus-labelling block existed on this installation. **That conclusion was wrong.** The block is:

```
spsLoadFlowBusLib/Load Flow Bus
C:\Program Files\MATLAB\R2024a\toolbox\physmod\powersys\library\utilities\spsLoadFlowBusLib.slx
```

It is the only block in that library, and the library sits in `powersys\library\utilities` — outside the directory the earlier sweep enumerated. What led back to it was the Load Flow Analyzer having a button labelled **`Add bus blocks`**: evidence against my own conclusion, which had to be retested before `docs/HOW_TO_RUN.md` shipped asserting it.

**Measured properties.** `BlockType PMComponent`, `MaskType 'Load Flow Bus'`, ports `LConn 1 / RConn 0 / In 0 / Out 0`. Twelve parameters — `Phases`, `Connectors`, `ID`, `Vbase`, `Vref`, `Vangle` and six read-back fields (`VLF`, `VLFb`, `VLFc`, `angleLF`, `angleLFb`, `angleLFc`). No impedance parameter. `Phases` is `popup(single|ABC|AB|AC|BC|A|B|C)`, default `single`; `Connectors` is `popup(on one side|on both sides)`.

**The `Add bus blocks` button** inserts one **unwired** block per solved node with `Vbase` pre-filled (230000 / 6600 / 22000 / 230000 / 230000, matching the register exactly) and placeholder IDs `Bus*1*`…`Bus*5*`. An unwired block is not inert — the solver **throws**:

```
Error using ThreePhaseLoadFlowBar
The Load Flow Bus block labeled 'BUS_1' is not properly connected to the network.
You need to connect this block to a load flow block, or delete it from your model.
```

**The finding that matters.** `Phases` is not a cosmetic choice. Both settings were run against the same baseline, five blocks wired to the same five nodes (`probe_bus_transparency3.m`):

| | baseline | `Phases='single'` | `Phases='ABC'` |
|---|---|---|---|
| solved nodes | 5 | **5** | **15** (`B22_a`, `B22_b`, `B22_c`, …) |
| admittance field on `LF` | `Ybus1` | **`Ybus1`** | **`Ybus`** |
| `LF.bus` fields | 22 | 22 | **12 — no `Vbus`, no `Sbus`** |
| placeholder IDs left | 5 of 5 | **0 of 5** | 0 of 15 |
| worst ΔV over the 5 baseline nodes | — | **3.301e−07 V** (1.44e−12 relative) | not comparable |
| worst Δangle | — | **4.547e−10 deg** | not comparable |
| `status` / iterations | 1 / 2 | 1 / 2 | 1 / 2 |

`Ybus1` is the positive-sequence admittance matrix; `Ybus` is the full per-phase one. So `Phases='ABC'` moves the study **off the balanced positive-sequence formulation onto the unbalanced per-phase one**, while still reporting `status = 1` in the same 2 iterations. Two reasons that is a defect and not an option here: the mandated study is a *balanced* load flow, and every script in `matlab/analysis/` reads `LF.bus.Vbus`, which no longer exists. It is a change of study type that presents as a labelling change — exactly the class of thing this document exists to record.

`Phases='single'`, wired to one terminal of each node, is transparent: balanced mode kept, `Vbus` kept, node count unchanged, all five IDs resolved to `BGRID230`, `B230_1`, `B22`, `B6_6`, `GAT_HV`, worst deviation 3.3 × 10⁻⁷ V on a 230 kV base.

**Two conclusions.**

1. **B8's mapping is now independently confirmed.** B8 says buses must be identified by block handle, and `HOW_TO_RUN.md` §7 publishes a `*n*` → named-bus table derived from base voltage and bus type. Naming the nodes reproduced that table exactly: `*1*` → `GAT_HV` (220308.745055 V, matching to 3 × 10⁻⁷ V), `*2*` → `B6_6`, `*3*` → `B22`, `*4*` → `BGRID230`, `*5*` → `B230_1`.
2. **The blocks are not in the deliverable.** Adding them is a change to a validated model — it would need a backup, a programmatic edit in `matlab/build/`, and a re-run of the 434-test suite plus all four cases. The gain is cosmetic and the mapping is documented, so the change has not been made. This is recorded as an available, measured option rather than a limitation.

**Correct wiring is not obvious and was measured** (`probe_bus_transparency2.m` §2). Host terminals: `EXT GRID` LConn 0 / RConn 3, `G1` LConn 0 / RConn 3 — sources, so their only terminals are on the right; `LOAD_B6_6` LConn 3 / RConn 0; `GSUT 10BAT10`, `GAT 10BBT20`, `GAT BAY CB`, `BUS COUPLER` all 3 / 3. Asking for `LConn` on a source yields no terminal and the block silently labels nothing. And `GAT_HV` must be taken from the **transformer's** winding-1 terminal, never from the busbar side of the open bay — attaching it to the bay is what produced a spurious 6th node in the first attempt.

**Two probes in this chain print false verdicts and are annotated as superseded:** `probe_loadflow_bus3.m` (concluded no such block exists) and `probe_bus_transparency.m` (concluded "NOT transparent. Do not use." from a row-k-to-row-k comparison across lists of unequal length, plus single-phase wiring to the wrong node). `probe_bus_transparency3.m` is the one to cite.

---

## What this document is not

It is **not** a list of workarounds that make the solver produce a desired answer. Every item is either

- a **defect avoided** (B1, B2, B4, B5, B8, B11),
- an **artefact bounded by measurement** (B6, B7),
- an **independent confirmation** (B9, B11), or
- a **language/API fact** (B10).

Not one of them changed a plant parameter. The complete audit trail is the paired `probe_*.m` / `probe_*.txt` files: script and captured output, so any claim above can be re-derived rather than taken on trust. B11 also records where a conclusion of mine was **wrong** and how it was overturned, because a validation record that only lists successes is not a validation record.

**Related:** `topology_validation.md` · `load_flow_readiness.md` · `assumptions.md` · `prior_psaf_model_defects.md`
