# HOW TO RUN AND DEMONSTRATE THE MODEL

**Ashuganj 450 MW Combined Cycle Power Plant (South) — balanced steady-state load flow**
BUET EEE 306, January 2026, Group-03, Section C-1

> ## SUPERSEDED — read `docs/manual/USER_MANUAL.html` instead
>
> That page covers the same ground and is **generated from the solved results every
> time the study is run**, so it cannot drift from the model. This file is
> hand-written, and it has drifted: several figures in it were correct for an
> earlier revision of the dataset and are now wrong by a few hundredths of a
> per cent. Three passages have been checked against the current results and
> corrected — the four-case summary in §5, the node mapping in §7, and the closing
> one-paragraph answer in §15, which is the one a presenter is most likely to read
> aloud. The **other ~90 figures in this file have not been re-verified.**
>
> Quote numbers from `results/load_flow/*.csv` or from the generated documents in
> `docs/manual/`. Keep this file for its prose if you like; do not read a number
> off it onto a slide.
>
> Retained rather than deleted because the click paths, the anecdotes and the
> explanations are still sound — it is only the arithmetic that aged.

This is the operating manual. It tells you which program to open, what to click, in
what order, what each number on the screen means, and what to say about it. Every
click path in this document was measured on this installation, not recalled from
documentation.

Read §3 if you have five minutes. Read §7 before you present to anybody.

---

## 1. WHAT YOU NEED

| Item | Required | Verified present |
|---|---|---|
| MATLAB | R2024a | R2024a, 24.1.0.2537033, PCWIN64 |
| Simulink | 24.1 | yes |
| Simscape Electrical | 24.1 (provides Specialized Power Systems) | yes |
| Internet | **not needed** | the model is fully offline |
| Extra toolboxes | none | — |

The project root is:

```
F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project
```

Note the space at the start of `" Level 3 Term 1"`. Any path you type at a shell
must be quoted. Inside MATLAB this does not matter.

---

## 2. THE SHAPE OF THE PROJECT

```
306 Power Project/
├── data/master/            Ashuganj_Master_Data.csv     127-row parameter registry
├── matlab/
│   ├── ashuganj_setup.m    puts every folder on the MATLAB path  <-- ALWAYS FIRST
│   ├── run_build.m         builds the readable SLD and compile-checks it
│   ├── data/               the dataset: buses, generators, transformers, lines,
│   │                       loads, grid  (one .m per class, all with provenance)
│   ├── data/assumptions/   the 5 approved/disclosed assumptions, kept SEPARATE
│   ├── build/              the block-by-block model builders
│   ├── analysis/           results extraction and plotting
│   ├── studies/            run_load_flow_study.m   <-- the study driver
│   ├── tests/              run_all_tests.m + 12 test files
│   └── env/                one-off probes that measured solver behaviour (evidence)
├── simulink/
│   ├── main/               Ashuganj_South_Main.slx   <-- THE DIAGRAM YOU SHOW
│   ├── studies/            Load_Flow.slx + Load_Flow_LF1..LF4.slx
│   └── backups/            _v001 .. _v007
├── results/
│   ├── load_flow/          6 CSVs + 4 powergui .rep reports
│   ├── plots/              4 PNGs
│   └── reports/            load_flow_report.md   <-- the written deliverable
└── docs/
    ├── model/              topology, bus/branch/transformer/generator/load lists
    ├── validation/         verified / missing / conflicting / assumptions / readiness
    └── HOW_TO_RUN.md       this file
```

---

## 3. THE 60-SECOND VERSION

Open MATLAB. In the Command Window:

```matlab
cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
ashuganj_setup
run_all_tests
run_load_flow_study
make_load_flow_plots
```

That is the whole study, from dataset to figures. It rebuilds every model from the
dataset, solves all four cases, cross-checks each one three ways, and writes every
CSV, report and PNG. Expect roughly three to four minutes in total, most of it in
the test suite.

To *show* the model rather than rerun it:

```matlab
open('../simulink/main/Ashuganj_South_Main.slx')
```

then double-click the block labelled **powergui** in the top-left of the diagram →
**Load Flow** → **Compute**. That is the live demo. §7 is the click-by-click script.

---

## 4. WHAT THE SYSTEM IS — SO YOU CAN EXPLAIN IT

Ashuganj South is a **single-shaft** combined cycle block: Siemens
**SCC5-PAC 4000F/3000 (1S)**. One SGT5-4000F gas turbine and one SST-3000 steam
turbine sit on **one shaft driving ONE generator**. This matters for the demo,
because the obvious question — "where is the second generator?" — has a physical
answer: there isn't one. There is a single SGen5-2000H, 458 MVA nominal / 518 MVA
maximum, 22 kV.

The electrical path, generation on the left to grid on the right:

```
                                        22 kV GEN BUS                 230 kV BUS 1 / BUS 2
                                             |                              |
   ( G1 )  SGen5-2000H  ------------->  ======+======  --[ GSUT 10BAT10 ]--> ====+====  --[ ZGRID ]--> ( EXT GRID )
   458/518 MVA, 22 kV, pf 0.85              |          230/22 kV YNd1            |     grid equivalent    swing bus
   PV bus, Vset 1.00 pu (assumption A5)     |          355/460/515 MVA           |     |Z| = 2.656 ohm    230 kV, 1.00 pu
                                            |          Z = 16 % @ 515 MVA        |     ESTIMATED (Q1a)
                                            |          tap 9 = 230000 V          |
                                            |                                    |
                                   [ UAT 10BBT10 ]                    [ GAT BAY CB 10BAY20 ]
                                    22/6.9 kV Dyn11                    open in LF1/LF3
                                    19/25 MVA                          closed in LF2/LF4
                                    Z = 10.5 % @ 25 MVA                         |
                                    tap 3 = 22000 V                    [ GAT 10BBT20 ]
                                            |                           230/6.9 kV YNyn0+d11
                                            |                           19/25 MVA, Z_PS = 12 %
                                            v                           tap 13 = 230000 V
                                     ==== 6.6 kV MV BUS ====  <-------------------+
                                            |
                          14.000 MW + 8.676 MVAr total auxiliary load
                          split 9050 : 2500 : 2500 kW  (ASSUMPTION, approved answer Q6B)
```

Six things about this diagram that you should be ready to defend:

1. **There is no 400 kV anywhere.** Ashuganj *North* has the 400 kV GIS and the
   Hyosung 400/230 kV interbus transformers; that is UTS project 7485, a different
   unit, explicitly out of scope. South connects at 230 kV. Also: the auxiliary bus
   is **400 V** — four hundred volts, not four hundred kilovolts. The two are never
   mixed in this model.
2. **50 Hz**, because Bangladesh is 50 Hz. This is not cosmetic: the prior CYME
   PSAF v2.90 model of this plant was built at **60 Hz** (logged as defect D2), and
   every reactance in this model is therefore different from that study's.
3. **The grid is a two-terminal equivalent at the plant boundary**, not a piece of
   the Bangladesh network. No 70 km line was invented, no cosmetic grid buses were
   added (approved answer Q7a). Its magnitude |Z| = 2.656 Ω is an **ESTIMATE**, and
   its X/R is assumed infinite (assumption A1). It is the weakest number in the
   model and you should say so before anyone asks.
4. **The 230 kV switchgear is a Siemens 8DN9 GIS**, double-busbar single-breaker,
   3150 A busbar continuous rating, 50 kA/1 s. The bus coupler 10BAY12 is modelled
   **closed** — an assumption (Q9a), because the normal operating state is nowhere
   in the available document set.
5. **The 6.6 kV bus is reported on two bases.** The UAT and GAT LV windings are
   documented at **6.9 kV**; the plant MV bus is **6.6 kV**. That is conflict C13.
   Both are reported side by side and neither was silently discarded.
6. **The tertiary of the GAT is omitted**, because it is unloaded and its Z_PT and
   Z_ST are MISSING from the document set. The GAT is modelled as the documented
   two-winding Z_PS = 12 % (approved answer Q5a).

---

## 5. THE FOUR CASES, AND WHY THERE ARE FOUR

Two approved answers each ask for a comparison, and they are independent choices,
so together they make a 2×2 matrix:

|  | **GAT out of service** (radial) | **GAT in service** (looped) |
|---|---|---|
| **389.30 MW** rated dispatch | **LF1** | **LF2** |
| **342.01 MW** site-derated | **LF3** | **LF4** |

- **Q2c** asked for rated 389.30 MW to be compared against site-derated 342.01 MW.
- **Q4c** asked for GAT out to be compared against GAT in.

Reporting only two of the four would confound the dispatch effect with the GAT
effect. All four are solved so the two effects can be separated. **LF1 is the base
case**, and it is the case saved in the readable diagram.

Here is the whole answer on one page. Every number is from
`results/load_flow/system_summary.csv`.

| | **LF1** | **LF2** | **LF3** | **LF4** |
|---|---|---|---|---|
| dispatch | rated | rated | derated | derated |
| GAT bay 10BAY20 | open | closed | open | closed |
| topology | radial | looped | radial | looped |
| G1 P (MW) | 389.300 | 389.300 | 342.010 | 342.010 |
| G1 Q (MVAr) | 31.676 | 27.461 | 26.174 | 22.007 |
| auxiliary load (MW) | 14.000 | 14.000 | 14.000 | 14.000 |
| total losses (MW) | 0.8165 | 0.8334 | 0.6802 | 0.6903 |
| losses, % of generation | 0.2097 | 0.2141 | 0.1989 | 0.2018 |
| **P exported (MW)** | **374.484** | **374.467** | **327.330** | **327.320** |
| **Q exported (MVAr)** | **−29.986** | **−33.704** | **−23.418** | **−27.231** |
| V 230 kV (pu) | 0.99867 | 0.99849 | 0.99896 | 0.99877 |
| V 22 kV (pu) | 1.00000 | 1.00000 | 1.00000 | 1.00000 |
| V 6.6 kV (pu on 6600 V) | 1.00091 | 1.02028 | 1.00091 | 1.02082 |
| V 6.6 kV (pu on 6900 V) | 0.95739 | 0.97592 | 0.95739 | 0.97644 |
| GSUT loading, % of 355 MVA | **105.87** | 104.21 | 92.49 | 91.26 |
| GSUT loading, % of 515 MVA | 72.98 | 71.83 | 63.75 | 62.91 |
| UAT loading, % of 19 MVA | 91.09 | **109.60** | 91.09 | **101.50** |
| UAT loading, % of 25 MVA | 69.23 | 83.30 | 69.23 | 77.14 |
| GAT loading, % of 19 MVA | 0.34 | 40.82 | 0.35 | 34.49 |
| max 230 kV current (A) | 943.05 | 928.25 | 823.77 | 812.88 |
| … as % of 3150 A busbar | 29.9 | 29.5 | 26.2 | 25.8 |
| iterations to converge | 2 | 2 | 2 | 2 |
| worst KCL residual (MVA) | 8.6e−08 | 6.1e−04 | 8.6e−08 | 5.2e−04 |
| verdict | OK | OK | OK | OK |

**Q is negative in all four cases.** The plant exports MW and *absorbs* MVAr. Say
"absorbs", not "exports a negative", and be ready to point at the GSUT: its
reactive loss alone is 44.51 MVAr in LF1, which is where most of it goes.

**The two headline findings** are the two bold numbers in the loading rows. Both are
discussed in §11.

---

## 6. ROUTE A — THE FULL REBUILD (what to run for a clean, reproducible result)

Use this when you want the numbers regenerated from the dataset, or when you have
changed a parameter. Four commands, in this order.

### Step 1 — configure the path (once per MATLAB session)

```matlab
cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
ashuganj_setup
```

It prints the root and the MATLAB version, and creates any missing output folders.
**Nothing else in the project works until this has run**, because every script lives
in a subfolder. `matlab/env` is deliberately *not* on the path — those are one-off
probes, not library code.

### Step 2 — run the test suite

```matlab
run_all_tests
```

Expect: **434 passed, 0 failed, about 155 seconds**, across 12 files —
bus 61, generator 28, transformer 85, line 47, load 58, base conversion 19,
topology 52, transformer phase shift 18, grid sensitivity 38, magnetising
sensitivity 28.

These tests check the *dataset and the topology*, not the solution: that every
parameter carries a status and a source, that no ENGINEERING_ASSUMPTION is
mislabelled VERIFIED, that per-unit conversions to the 100 MVA base round-trip,
that the vector groups give the phase shifts they claim, that the topology has no
orphan bus, and that the answers are insensitive to the two disclosed assumptions
within their stated bounds. Run them first because a dataset error found here is
cheap, and the same error found in a load-flow result is not.

### Step 3 — solve the case matrix

```matlab
run_load_flow_study
```

This builds each of LF1–LF4 **from scratch immediately before solving it**, solves
it, cross-checks it, and writes the results.

Why rebuild each time? Because `power_loadflow('solve')` **writes the solution back
into the blocks** — it overwrites source `Voltage` and `PhaseAngle` and load
`NominalVoltage`. This was measured, in `matlab/env/probe_mutation.m`. Solving the
same model twice therefore solves a *slightly different network* the second time.
Each case here is built quietly, unsaved, and solved once. The deliverable `.slx`
files are then written by a final **clean** build, so what ships on disk is the
network as specified, not the network with a solution smeared into it.

Three cross-checks run on every case before its numbers are written:

1. **KCL at every bus**, from branch flows reconstructed *outside* the solver using
   the documented impedances — an independent calculation, not the solver's own
   residual.
2. **System power balance**, generation − load − losses = export, to 1e−6 MW.
3. **The case identity** — the solved generator injection must equal the MW the case
   dispatches, or the wrong case was solved.

A case that fails a cross-check is still written, with its verdict recorded, because
hiding an inconsistent case would defeat the point of running a matrix. A case that
does not *converge* is different: the solver strips `LF.bus` of `Vbus`, `Sbus` and
every other solution field, so there is nothing to write; it appears in
`system_summary.csv` as NaN with the solver's own error message and is absent from
the detail tables. **It is never quietly replaced by zeros.**

Variants:

```matlab
run_load_flow_study('Cases', {'LF1'})     % one case only
run_load_flow_study('Write', false)       % solve, write nothing
run_load_flow_study('SaveModels', false)  % don't rewrite the .slx files
S = run_load_flow_study;                  % capture the results struct
```

### Step 4 — draw the figures

```matlab
make_load_flow_plots
```

Writes four PNGs to `results/plots/`. See §9.

---

## 7. ROUTE B — THE LIVE GUI DEMO (this is what you show an audience)

The readable diagram in `simulink/main/Ashuganj_South_Main.slx` **is case LF1**, and
it **solves on its own**. This was verified by solving both it and
`Load_Flow_LF1.slx` and comparing: identical to **0 V and 0 degrees on all five
nodes**. So you can run the live demonstration on the diagram that is laid out to
be read, rather than on a generated study model. Do that.

### The click path

1. **Open MATLAB R2024a.** Wait for the Command Window prompt.

2. **Set up the path.** In the Command Window:
   ```matlab
   cd 'F:\LOCAL DISK E\idm\compressed\ Level 3 Term 1\306 Power Project\matlab'
   ashuganj_setup
   ```

3. **Open the diagram.**
   ```matlab
   open('../simulink/main/Ashuganj_South_Main.slx')
   ```
   Or: in the **Current Folder** browser, go up one level to
   `simulink\main\` and double-click `Ashuganj_South_Main.slx`.

   The diagram opens with 12 blocks and 25 annotations, laid out left to right as
   Generation → Transformation → Grid, with the auxiliary branch below. Let the
   audience read it for a moment before you touch anything. Point out `G1`,
   `22 kV GEN BUS`, `GSUT 10BAT10`, `230 kV BUS 1`, `230 kV BUS 2`,
   `UAT 10BBT10`, `6.6 kV MV BUS`, `400 V AUX BUS`, `GAT 10BBT20`, `EXT GRID`.

4. **Double-click the block named `powergui`.** It sits at the top level of the
   diagram, one of the 12 blocks. Its dialog opens.

5. **Confirm the solver settings in front of the audience.** The dialog's own field
   labels, read from the block's mask, are:

   | field label on screen | parameter | value | why it matters |
   |---|---|---|---|
   | `Simulation type:` | `SimulationMode` | Continuous | phasor solution, not discretised |
   | `Sample time (s):` | `SampleTime` | 50e-6 | unused in Continuous, but set |
   | **`Frequency (Hz):`** | `frequency` | **50** | Bangladesh. Show this deliberately — see the trap below |

6. **Open the Load Flow tool.** Two ways, and the second is the reliable one on a
   projector:

   - from the `powergui` dialog, the *Load Flow* entry in the tools area; or
   - **type one command**, which needs no hunting and no arguments:

   ```matlab
   powerLoadFlow
   ```

   `powerLoadFlow` is an App Designer app (`matlab.apps.AppBase`) shipped at
   `...\powersys\powersys\powerLoadFlow.mlapp`. It takes **no arguments** — it reads
   the current model itself. `powerLoadFlow('Ashuganj_South_Main')` throws
   `MATLAB:TooManyInputs`, so do not pass the model name.

7. **The window that opens is titled `Load Flow Analyzer`.** Its controls, measured
   from the running app rather than recalled, are:

   | control | what it does |
   |---|---|
   | `Model:` | the model it will solve |
   | `Units` — `V` / `kV`, `W, Var` / `kW, kVar` / `MW, MVar` | display units only; does not change the solution |
   | **`Compute`** | runs the load flow. Solves in **2 iterations** |
   | `Update` | pushes the solved values back into the blocks |
   | `Apply` | writes the settings in the table into the blocks |
   | **`Report`** | opens the text report |
   | `Add bus blocks` | inserts bus-label blocks — **see Trap 2, and do not click this during a demo** |

   It has **two tables**, a balanced one and an unbalanced one. This study is the
   balanced case, so the balanced table is the one to point at. Before you press
   anything it displays: *"The table shows the load flow settings of the model.
   Click Compute to perform load flow analysis."*

   One label to read carefully: the base-power field is **`Base power (VA)`** — volt-
   amperes, not MVA. It reads `100e6`, which is the 100 MVA reporting base, not
   100 VA. The tolerance field is `PQ tolerance (pu)` = 1e−4 and the iteration limit
   is `Max iterations` = 50.

8. **Click `Compute`, then `Report`.** A text report appears. This is the same content
   as `results/load_flow/LF1_powergui_report.rep`, which is already on disk if the
   projector is unreliable and you would rather open a saved file.

### THE THREE TRAPS IN THAT DIALOG — read this before presenting

**Trap 1 — the stray `60`.** The powergui dialog also contains a field
`fundamental = 60`. That is the **FFT tool's** default frequency and has nothing to
do with the system frequency, which is the `frequency = 50` in step 5. You do not
have to argue this: the mask's own prompt for that field reads

```
Fundamental (PSBFFTSCOPE)
```

— the parameter names the FFT scope in its own label. Mention it *before* anybody
spots it, because 60 Hz was logged as defect **D2** of the prior CYME PSAF study of
this same plant, and an examiner who notices a stray 60 on your screen will
reasonably assume you repeated that mistake. You did not: the solved `LF.frequency`
is 50, and it is written as `f_Hz = 50` in `system_summary.csv`.

**Trap 2 — the buses are called `*1*` … `*5*`.** They are not named in the report, so
you must supply the mapping yourself. **Do not identify buses by index**, because the
indices are assigned by the solver and are not stable if the network changes.
Identify them by **base voltage and bus type**, both of which the tool prints:

| tool ID | base | bus type | it is | LF1 | LF2 | LF3 | LF4 |
|---|---|---|---|---|---|---|---|
| `*1*` | 230 kV | PQ | **GAT HV terminal** | 0.957242 | 0.998487 | 0.957235 | 0.998770 |
| `*2*` | 6600 V | PQ | **6.6 kV MV BUS** | 1.000911 | 1.020280 | 1.000908 | 1.020818 |
| `*3*` | 22 kV | **PV** | **22 kV GEN BUS** (G1) | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| `*4*` | 230 kV | **swing** | **EXT GRID** | 1.000000 | 1.000000 | 1.000000 | 1.000000 |
| `*5*` | 230 kV | PQ | **230 kV BUS 1 + BUS 2** | 0.998672 | 0.998485 | 0.998960 | 0.998768 |

The two unambiguous anchors are the **only PV bus** (that is G1, 22 kV) and the
**only swing bus** (that is the grid, 230 kV). Find those two first and the rest
follow from the base voltage.

In LF2 and LF4 the mapping above **cannot be read off the report**: with the GAT
bay closed, `*1*` and `*5*` sit a fraction of a volt apart and print the same
three decimals. §5 of `docs/manual/USER_MANUAL.html` derives the mapping from the
report every time it is generated and says "ambiguous" in exactly those two
cases instead of guessing.

**This mapping has since been confirmed a second, independent way** — see *Naming the
buses* below. It is not an inference from base voltages alone.

Two things to say about this table:

- **`*5*` is BUS 1 and BUS 2 together.** The bus coupler is a closed breaker, and to
  a load flow a closed breaker is an identity, not a branch. Eight buses in the
  register become **five solved nodes**: the three 6.6 kV load nodes merge (their
  feeder impedances are MISSING from the document set) and the two 230 kV busbars
  merge (the coupler is closed by assumption). The CSVs list all eight rows, but
  only the representative of each merged group carries the solver's injection; the
  others show NaN and name the bus they merged into. That is deliberate — otherwise
  a reader could total the table and find 42 MW of auxiliary load in a plant that
  has 14.
- **`*1*` in LF1/LF3 is not a plant voltage.** With the GAT bay open, the only thing
  giving the GAT HV terminal a defined voltage instead of a floating node is the
  breaker block's own 1 MΩ snubber. 0.9579 pu there is a numerical artefact of the
  block, not a busbar voltage. It becomes a real 230 kV voltage in LF2/LF4, where it
  sits 0.5 V below the busbar node — the drop across the closed breaker's 0.01 Ω
  contact resistance.

#### Naming the buses — a correction to an earlier statement in this manual

An earlier version of this section said the `*n*` labels were "not fixable on this
installation" because "no user-facing bus-labelling block" exists in this MATLAB.
**That was wrong, and it is corrected here.** The block exists:

```
spsLoadFlowBusLib/Load Flow Bus
C:\Program Files\MATLAB\R2024a\toolbox\physmod\powersys\library\utilities\spsLoadFlowBusLib.slx
```

The earlier search missed it because it enumerated only the libraries in
`toolbox\physmod\powersys\powersys`. This one lives a directory tree away, in
`powersys\library\utilities`, and it is the sole block in that library. The Load Flow
Analyzer's **`Add bus blocks`** button is what led back to it.

What was then measured about it, on scratch copies only:

| question | measured answer |
|---|---|
| ports | `LConn 1`, `RConn 0` — one electrical terminal, one side |
| parameters | `Phases`, `Connectors`, `ID`, `Vbase`, `Vref`, `Vangle` + 6 read-back fields. No impedance |
| `Phases` options | `single \| ABC \| AB \| AC \| BC \| A \| B \| C`, default `single` |
| what `Add bus blocks` does | inserts one **unwired** block per solved node, `Vbase` pre-filled (230000 / 6600 / 22000 / 230000 / 230000), IDs `Bus*1*`…`Bus*5*` |
| leaving one unwired | the solver **throws**: *"The Load Flow Bus block labeled 'BUS_1' is not properly connected to the network."* |

**The setting matters more than the block.** `Phases = 'ABC'` looks like the right
choice for a three-phase busbar and is the wrong one for this study. Measured, with
all five blocks wired three-phase:

| | baseline | `Phases='single'` | `Phases='ABC'` |
|---|---|---|---|
| solved nodes | 5 | **5** | **15** (`B22_a`, `B22_b`, `B22_c`, …) |
| admittance field | `Ybus1` | **`Ybus1`** | **`Ybus`** |
| `LF.bus.Vbus` present | yes | **yes** | **no** |
| placeholders left | 5 of 5 | **0 of 5** | 0 of 15 |
| worst voltage change | — | **3.30e−07 V** (1.4e−12 relative) | not comparable |
| worst angle change | — | **4.55e−10 deg** | not comparable |

`Ybus1` is the positive-sequence matrix; `Ybus` is the full per-phase one. `ABC`
therefore moves the study **off the balanced positive-sequence formulation onto the
unbalanced per-phase one** — which is not the mandated study, and which removes the
`Vbus` field that every script in `matlab/analysis/` reads. It is a change of study
type wearing the costume of a label. Do not use it here.

`Phases = 'single'`, wired to one terminal of each node, does the job: balanced mode
kept, `Vbus` kept, five nodes still five, **and all five names appear** —
`BGRID230`, `B230_1`, `B22`, `B6_6`, `GAT_HV`. The worst change anywhere is
3.3 × 10⁻⁷ V on a 230 kV base, which is solver round-off, not a different answer.

Two consequences for a presenter:

1. **The mapping table above is now confirmed independently.** Naming the nodes
   produced exactly the assignment the table asserts: `*1*` → `GAT_HV`
   (220308.745055 V, matching to 3 × 10⁻⁷ V), `*2*` → `B6_6`, `*3*` → `B22`,
   `*4*` → `BGRID230`, `*5*` → `B230_1`. The table was derived from base voltage and
   bus type; it has now been checked against the solver's own labels.
2. **The blocks are not in the delivered models.** So the reports on disk today,
   and anything you solve live, still print `*1*`…`*5*` — the table remains how you
   read them. Adding the blocks is a change to a validated model: it needs a backup,
   a programmatic edit in `matlab/build/`, and a re-run of the full 434-test suite
   and all four cases to confirm no published number moves. That decision has not
   been taken.

If asked why the buses are not named, the honest answer is now: *"they can be, with
the Load Flow Bus block on its single-phase setting, and it costs 10⁻⁷ volts — but
the model was validated without it, so the mapping is documented instead of
re-validating the deliverable for a cosmetic gain."*

**Trap 3 — the summary block says "Total generation: 14.82 MW".** It is right, and
it is not the plant output. The powergui summary nets *all* generation including the
swing bus:

```
G1               + 389.30 MW
swing bus        − 374.48 MW      (the grid is absorbing the export)
                 -------------
Total generation  +  14.82 MW  =  14.000 MW auxiliary load + 0.816 MW losses
```

389.30 − 374.4839 = 14.8161 MW, and 14.000 + 0.8161 = 14.8161 MW. It is an exact
identity, and it is a good moment in a presentation: the "wrong-looking" number is
the auxiliary load plus the losses, and it proves the balance closes.

The same block also reports `Total losses: 0.62 MW` and `Total Zshunt load: 0.19 MW`
**separately**. The powergui "losses" line is the *series* copper loss only; the iron
/ magnetising loss is the Zshunt line. Total = 0.62 + 0.19 = 0.81 MW, which is the
0.8161 MW in `system_summary.csv`. If you quote a loss figure, quote the total.

---

## 8. ROUTE C — SHOWING ONE SPECIFIC CASE

To show the GAT in service, or the derated dispatch, open the matching study model
instead of the main diagram. Everything in §7 then applies unchanged.

```matlab
open('../simulink/studies/Load_Flow_LF2.slx')   % rated dispatch, GAT IN
open('../simulink/studies/Load_Flow_LF3.slx')   % derated dispatch, GAT out
open('../simulink/studies/Load_Flow_LF4.slx')   % derated dispatch, GAT IN
```

Each carries a `Case LFn` annotation on the canvas so the audience can see which one
is on screen.

`simulink/studies/Load_Flow.slx` also exists, because it is named in the requested
deliverable layout. It is a **duplicate of LF1** — same `Pref = 389300000`, same GAT
bay open, same coupler closed, same case annotation, solves in 2 iterations to 5
nodes. Open LF1 by preference so there is no ambiguity about what is on screen.

If you would rather solve from the Command Window than click:

```matlab
load_system('../simulink/studies/Load_Flow_LF2.slx')
LF = power_loadflow('Load_Flow_LF2', 'solve');
fprintf('status %d, %d iterations, %d nodes\n', LF.status, LF.iterations, numel(LF.bus));
for k = 1:numel(LF.bus)
    b = LF.bus(k);
    fprintf('%-6s %8.4g V base  %-6s  |V| = %.6f pu  angle = %+8.4f deg\n', ...
        b.ID, b.vbase, b.busType, abs(b.Vbus), rad2deg(angle(b.Vbus)));
end
bdclose('Load_Flow_LF2')
```

Four things about that snippet that will save you an hour if you write your own:

- **`LF.bus(k).Vbus` is COMPLEX.** `abs()` for the magnitude, `rad2deg(angle())` for
  the angle. `fprintf('%f', ...)` on a complex number prints **only the real part**,
  silently, with no warning. It will hand you five plausible-looking wrong voltages.
- **`status == 1` means converged**, `−1` means it did not, and `power_loadflow`
  **does not throw** on failure. Check `LF.status`. On failure `LF.bus` is truncated
  to 12 fields and `Vbus` is simply absent.
- Field names are **lowercase** `vbase`, not `Vbase`.
- Use **`bdclose`**, not `close_system(mdl,0)` — the latter will not force-close a
  model the solver has modified, and the solver always modifies it.

Also available, and useful:

```matlab
power_loadflow('Load_Flow_LF2', 'solve', 'report', 'LF2_report')       % text report
power_loadflow('Load_Flow_LF2', 'solve', 'ExcelReport', 'LF2_report')  % Excel report
```

The text report lands with a `.rep` extension — the function appends it to whatever
name you pass.

---

## 9. WHERE THE OUTPUTS ARE, AND WHAT THEY MEAN

### `results/load_flow/`

| file | one row per | the columns that matter |
|---|---|---|
| `system_summary.csv` | case | P/Q generated, aux load, losses, export, the four bus voltages, the three transformer MVAs, iterations, worst KCL residual, verdict |
| `bus_results.csv` | bus × case | `V_pu`, `V_kV`, `Ang_deg`, injections; `Merged_into` names the representative node; `P_load_alloc_MW` is the *dataset* allocation, never mixed with solver output |
| `generator_results.csv` | case | terminal P, Q, S, I, pf, and S as a % of the 458 MVA nominal and 518 MVA maximum |
| `transformer_results.csv` | transformer × case | per-winding P/Q/S, losses, HV current, `Loading_pct_lowest_stage`, `Loading_pct_highest_stage`, tap used |
| `line_results.csv` | branch × case | flows; branches with no observable flow are written with **NaN and a reason**, not zero |
| `residuals.csv` | bus × case | the independent KCL cross-check |
| `LFn_powergui_report.rep` | case | the solver's own report, `*1*`..`*5*` and all — the mapping is in §7 |

**One trap in the CSVs.** `system_summary.csv`'s `S_GSUT_MVA` / `S_UAT_MVA` /
`S_GAT_MVA` are the **LV-winding** apparent powers. `transformer_results.csv`
computes loading from the **worse of the two windings**. So for LF2 the UAT reads
20.2949 MVA in the summary (÷19 = 106.8 %) but **109.50 %** in the transformer
table, because its HV winding carries 20.8054 MVA. The transformer table is the one
to quote — loading against the worst-loaded winding is the correct definition. This
is not a discrepancy in the model; it is two different quantities with similar
names, and §6.3 of `results/reports/load_flow_report.md` sets it out in full.

### `results/plots/`

| file | shows |
|---|---|
| `bus_voltage_profile.png` | pu voltage at every bus in all four cases, with the ±5 % band, and the 6.6 kV bus plotted on both its bases so C13 is visible |
| `transformer_loading.png` | loading against every documented cooling stage, with the 100 % line |
| `line_loading.png` | 230 kV currents against the 3150 A busbar rating (top) and the flow through the grid equivalent (bottom) |
| `power_balance.png` | generation, auxiliary load, losses and export per case |

### `results/reports/load_flow_report.md`

The written deliverable, 15 sections: what the study is and is not, the network
solved, the four cases, convergence, bus voltages, transformer flows, 230 kV
results, the power balance, **five independent hand checks**, four findings needing
attention, the assumption/conflict/missing registers, the figures, nine things the
study does **not** establish, how to reproduce, and the bottom line.

If you only read one thing from it, read §9.4. With bay 10BAY20 open the GAT carries
magnetising current only, so its loss should be its documented no-load loss scaled by
voltage squared: 23 kW × (0.957852)² = **21.1020 kW**. The model solved
**21.1023 kW**. Agreement to 0.0003 kW, and it simultaneously confirms three separate
things: the documented iron loss is really in the model, the off-nominal
22000/6900-into-6600 ratio is implemented as intended, and an open bay leaves the
transformer at no-load loss alone.

---

## 10. CHANGING A CASE, AND THE BACKUP RULE

**Before you modify `simulink/main/Ashuganj_South_Main.slx`, back it up.** The
convention is already established in `simulink/backups/`: copy to
`Ashuganj_South_Main_v008.slx`, then `_v009`, and so on. The working sequence is
**backup → modify → update diagram → validate → save only after the checks pass**.
Never overwrite the only working model.

Three block parameters define a case:

| to change | block | parameter | values |
|---|---|---|---|
| dispatch | `G1` | `Pref` | `389300000` (rated) or `342010000` (site-derated), in **watts** |
| GAT in / out | `GAT BAY CB` | `InitialState` | `closed` or `open` |
| bus coupler | `BUS COUPLER` | `InitialState` | `closed` (assumption) or `open` |

From the Command Window, on an open model:

```matlab
set_param('Ashuganj_South_Main/G1', 'Pref', '342010000')
set_param('Ashuganj_South_Main/GAT BAY CB', 'InitialState', 'closed')
```

Both breakers have `External = off`, so the state comes from `InitialState` and not
from an input signal.

**Better than editing by hand:** rebuild. The builders take the case as an argument,
so a case change is one line and cannot leave the model half-edited:

```matlab
info = build_ashuganj_main('LF4');
```

**If you change a dataset value** — an impedance, a rating, a load — change it in
`matlab/data/*.m`, keep its provenance metadata truthful, then rerun §6 from step 2.
Do not edit a number into a block and leave the dataset saying something else; the
test suite exists to catch exactly that and it will.

**If you add an assumption**, it goes in `matlab/data/assumptions/` as its own file
with Parameter, Value, Unit, Reason, Approved_by_user, Date, Impact and Source, and
it gets a row in `docs/validation/assumptions.md`. Assumptions are never mixed into
the verified dataset.

---

## 11. THE FOUR THINGS TO SAY OUT LOUD

An audience will find these anyway. Say them first; they are findings, not faults.

### 11.1 The UAT is overloaded in LF2 and LF4 — and it is circulating power, not load

| | UAT loading vs 19 MVA ONAN | vs 25 MVA ONAF |
|---|---|---|
| LF1 (GAT out) | 90.64 % | 68.89 % |
| **LF2 (GAT in)** | **109.50 %** | 83.22 % |
| LF3 (GAT out) | 90.65 % | 68.89 % |
| **LF4 (GAT in)** | **101.39 %** | 77.06 % |

The auxiliary load is 14.000 MW in every case. It does not change. But in LF2 the
UAT carries **19.91 MW** — and the powergui report shows why: the GAT HV node sends
**+5.87 MW up into the 230 kV busbar** while the UAT brings **19.91 MW down** from
the generator bus. 19.91 − 14.00 − 5.89 ≈ 0. Power is going *down* through the UAT
and straight back *up* through the GAT.

That is **circulating power in a closed loop**, not extra auxiliary demand. Closing
bay 10BAY20 parallels two transformers with different ratios and different
impedances across the same two networks, and the ratio mismatch drives a circulating
current. It is the classic reason such a bay is not left closed.

**The caveat that makes this defensible:** the real plant's UAT/GAT changeover is
almost certainly an **interlocked transfer** — one source at a time, with a brief
parallel only during a live changeover. That interlock is not in the available
document set, so it is not in the model, and LF2/LF4 are therefore a *bounding
comparison* required by approved answer Q4c, **not** a claim that Ashuganj South runs
its UAT at 109 % of nameplate. Both readings are on the table because both were
asked for. The honest conclusion is: if the two ever *are* paralleled under load,
the UAT exceeds its ONAN rating and only its ONAF stage covers it.

### 11.2 The GSUT exceeds its ONAN stage at rated dispatch

| | vs 355 MVA ONAN | vs 460 MVA ODAN | vs 515 MVA ODAF |
|---|---|---|---|
| **LF1** | **105.87 %** | 81.70 % | 72.97 % |
| LF2 | 104.20 % | 80.42 % | 71.83 % |
| LF3 | 92.48 % | 71.37 % | 63.75 % |
| LF4 | 91.26 % | 70.43 % | 62.91 % |

This is **not a fault**. A three-stage transformer is not expected to carry full
plant output on natural cooling; the ONAN figure is the no-forced-cooling stage. The
correct statement is that **at rated dispatch the GSUT requires forced cooling** —
it is at 105.87 % of ONAN and 72.97 % of ODAF, so there is 27 % headroom on the
rating that actually applies in service. The reason all three stages are reported
rather than just the top one (approved answer Q11a) is precisely so this is visible
instead of hidden behind a comfortable 73 %.

### 11.3 The 230 kV switchgear is barely loaded

The largest 230 kV current anywhere in any case is **942.99 A** (GSUT HV, LF1),
against a documented 8DN9 busbar continuous rating of **3150 A**. That is **29.9 %**.
The GIS is nowhere near a thermal limit in any of the four cases. It was specified
for fault duty — 50 kA for 1 s, 125 kA peak — and that is a **short-circuit**
question, which this study does not address.

### 11.4 Two numbers in this model are weaker than the rest, and you should name them

- **The grid equivalent.** |Z| = 2.656 Ω is an **ESTIMATE** (approved answer Q1a
  explicitly permits it *as* an estimate), and its X/R is assumed infinite —
  assumption **A1**, zero series resistance. Sensitivity tests are in
  `test_grid_sensitivity.m` (38 tests). Note for accuracy: three claims in the
  original assumption record about the direction of the X/R effect did not survive
  those tests; `docs/validation/assumptions.md` now records what was measured.
- **The magnetising inductance.** `Lm = 1e6` pu is a **disclosed-but-not-approved**
  assumption, **A4**, used because no source document gives a magnetising reactance.
  Its bound is measured, not guessed: it is worth up to **3.4406 MVAr**, or
  **11.04 %** of the generator's reactive output in LF1. That is the largest single
  uncertainty in any *reactive* number in this study. The resistive part is not
  assumed — `Rm` comes from the documented no-load losses
  (GSUT 3239.0, UAT 1785.7, GAT 1087.0 pu on their own ratings).

The other disclosed-but-not-approved assumption is **A5**: G1 is a PV bus with
`Vset = 1.00` pu. That is why every table in this study shows the 22 kV bus at
exactly 1.000000 pu — **it is the voltage datum of the whole study, not a result.**
No source document gives the generator's normal voltage setpoint. Every voltage in
every table is *relative to that choice*.

---

## 12. A SUGGESTED TEN-MINUTE DEMONSTRATION

| min | do | say |
|---|---|---|
| 0–1 | Open MATLAB, `ashuganj_setup` | "Ashuganj South, 450 MW combined cycle, single shaft, one generator. We are doing a balanced steady-state load flow at 50 Hz." |
| 1–3 | Open `Ashuganj_South_Main.slx`, walk the diagram left to right | Name the blocks. Point out that South is 230 kV and the 400 kV GIS belongs to North. Point out that the auxiliary bus is 400 **volts**. |
| 3–4 | Double-click `powergui`, show `frequency = 50` | "Bangladesh is 50 Hz. The previous CYME study of this plant was built at 60. That field marked 60 is the FFT tool, not the system." |
| 4–5 | Load Flow → **Compute** | "Two iterations. Tolerance 1e−4 on a 100 MVA base." |
| 5–7 | **Report**, then map `*1*`..`*5*` using §7 | "The nodes print as `*1*`..`*5*` because the Load Flow Bus blocks are not in the model — identify by base voltage and type: the only PV bus is the generator, the only swing bus is the grid. The mapping has been verified against the solver's own labels." |
| 7–8 | Point at `Total generation 14.82 MW` | "That is not the plant output. 389.30 from the generator minus 374.48 into the grid — it is exactly the 14 MW of auxiliary load plus 0.82 MW of losses. The balance closes." |
| 8–9 | Open `results/plots/transformer_loading.png` and `bus_voltage_profile.png` | The GSUT/ONAN story (§11.2) and the ±5 % band. |
| 9–10 | Open `Load_Flow_LF2.slx`, Compute, show the UAT | "Same 14 MW of auxiliary load, but the UAT now carries 19.9. Closing the GAT bay parallels two transformers with different ratios — that is circulating power, and it is why the bay is not left closed." |

Have `results/reports/load_flow_report.md` and the four PNGs open in other windows
before you start, in case the live solve is inconvenient on the projector.

---

## 13. TROUBLESHOOTING

| symptom | cause | fix |
|---|---|---|
| `Undefined function 'run_load_flow_study'` | `ashuganj_setup` not run in this session | run it; it must be re-run after every MATLAB restart |
| `Undefined function 'probe_...'` | `matlab/env` is deliberately off the path | `run(fullfile(ashuganj_root,'matlab','env','probe_freq.m'))` |
| voltages look wrong, all angles are 0 | `fprintf('%f')` on the complex `Vbus` prints the real part only | `abs(Vbus)` and `rad2deg(angle(Vbus))` |
| a model will not close | the solver modified it; `close_system(mdl,0)` will not force it | `bdclose(mdl)` |
| solving twice gives slightly different answers | `power_loadflow('solve')` writes the solution into the blocks | rebuild before each solve — `run_load_flow_study` already does |
| `status = −1`, `LF.bus` has only 12 fields | did not converge; the function does **not** throw | check `LF.error`; look for an open breaker that has islanded part of the network |
| the report says `*1*`..`*5*` | the `Load Flow Bus` blocks are deliberately not in the delivered model | use the mapping table in §7 — expected, not broken. §7 also explains how naming them would work, and why it was not done |
| you added `Load Flow Bus` blocks and the solve now throws "not properly connected" | an unwired bus block is an error, not a no-op | wire each one to a terminal, or delete it |
| you added them and the node count jumped to 15 with names like `B22_a` | `Phases` was left on / set to `ABC`, which switches the solver to the **unbalanced** per-phase formulation | set `Phases` to `single`; see the table in §7 |
| a resistance you set has no effect | on a Series RLC Branch, `BranchType = 'L'` is a **pure inductance** and silently ignores `Resistance` | use `'RL'` |
| `S_UAT_MVA ÷ 19` ≠ the loading % in the transformer table | the summary carries the LV winding; loading uses the worse winding | see §9 |

---

## 14. WHAT THIS STUDY DOES NOT DO

Say this plainly. Every item is out of the current scope by instruction, not by
omission, and claiming any of them would be wrong.

1. **No short-circuit study.** No three-phase, line-to-ground, line-to-line or
   double-line-to-ground fault has been computed. The GIS's 50 kA/1 s rating is
   therefore untested by this work.
2. **No protection coordination.** No relay is modelled, no curve is set, no
   grading margin is computed.
3. **No transient or dynamic stability.** The generator's `H`, `Td0'`, `xq`, `xq''`,
   `x2`, `x0` and `Ra` are all MISSING from the document set — a dynamic study
   cannot be built from this dataset without new source data.
4. **No unbalanced analysis.** This is a **balanced** load flow. Zero-sequence data
   exists for the transformers but is unused here.
5. **No harmonic analysis**, no motor starting study, no arc-flash study.
6. **No Ashuganj North.** The 400 kV GIS and the Hyosung interbus transformers are
   project 7485 and are out of scope.
7. **The bus coupler's normal state is an assumption**, not a finding.
8. **The auxiliary load allocation 9050 : 2500 : 2500 kW is an assumption.** The
   14.000 MW total is documented; the split between the three 6.6 kV nodes is not.
9. **The feeder impedances between the 6.6 kV nodes are MISSING**, which is why
   those three nodes merge into one. Feeder voltage drop within the auxiliary system
   is therefore *not* represented, and no 6.6 kV feeder result should be quoted.
10. **The grid impedance is an estimate and the generator voltage setpoint is an
    assumption.** They are the datum and the stiffness of everything above.

`simulink/subsystems/` is empty, and that is deliberate. The requested layout named
five subsystem files, but the whole network is 12 blocks. Wrapping 12 blocks in five
masked subsystems would have made the diagram *less* readable, not more, and the
instruction was that it be readable as an engineering single-line diagram. The flat
diagram is the deviation, taken knowingly.

---

## 15. THE ONE-PARAGRAPH ANSWER

Open MATLAB R2024a, `cd` to the project root, run `RUN_ME setup`, then
`open('simulink/main/Ashuganj_South_Main.slx')`, double-click **powergui**, click
**Load Flow → Compute → Report**. That is case LF1: the Ashuganj South single-shaft
combined cycle block at rated 389.30 MW with the GAT out of service, converging in
two iterations to export **374.48 MW** and absorb **29.99 MVAr** at a 230 kV bus
sitting at **0.99867 pu**, with **0.8165 MW** of total losses — two tenths of one
percent of generation — and 14.000 MW of auxiliary load. To rerun everything from
the dataset instead, one command does it: `RUN_ME`. The three numbers to be honest
about are the GSUT at **105.87 %** of its natural-cooling stage, the UAT at
**109.60 %** of its natural-cooling stage when the GAT bay is closed — circulating
power in a loop, not load — and the fact that the 22 kV bus reads exactly 1.000 pu
because that is the assumed datum of the study, not a result of it.

*(The figures in this paragraph were re-checked against the current
`results/load_flow/*.csv` on 2026-08-21, as were the two tables named in the banner
at the top. The rest of this file was not.)*
